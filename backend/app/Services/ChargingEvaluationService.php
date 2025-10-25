<?php

namespace App\Services;

use App\Models\User;
use App\Models\Vehicle;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class ChargingEvaluationService
{
    protected TessieService $tessieService;
    protected SmartChargingService $smartChargingService;

    public function __construct(
        TessieService $tessieService,
        SmartChargingService $smartChargingService
    ) {
        $this->tessieService = $tessieService;
        $this->smartChargingService = $smartChargingService;
    }

    /**
     * Evaluate and execute charging decision for a vehicle.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @return array
     */
    public function evaluateAndExecute(Vehicle $vehicle, User $user): array
    {
        // Get current vehicle state
        $state = $this->tessieService->getVehicleState($vehicle, $user);

        if (!$state) {
            return [
                'success' => false,
                'action_taken' => false,
                'message' => 'Failed to fetch vehicle state',
            ];
        }

        $batteryLevel = $state['battery_level'];
        $isCharging = $state['is_charging'];
        $isPluggedIn = $state['is_plugged_in'];

        Log::info('Evaluating charging for vehicle', [
            'vehicle_id' => $vehicle->id,
            'vehicle_name' => $vehicle->display_name,
            'battery_level' => $batteryLevel,
            'is_charging' => $isCharging,
            'is_plugged_in' => $isPluggedIn,
        ]);

        // Vehicle must be plugged in for automatic charging
        if (!$isPluggedIn) {
            return [
                'success' => true,
                'action_taken' => false,
                'message' => 'Vehicle not plugged in',
            ];
        }

        // Check low battery protection first (highest priority)
        if ($user->isLowBatteryProtectionEnabled()) {
            $result = $this->evaluateLowBatteryProtection($vehicle, $user, $state);
            if ($result['action_taken']) {
                return $result;
            }
        }

        // If already charging from low battery protection, check if we should stop
        if ($isCharging && $user->isLowBatteryProtectionEnabled()) {
            $stopLimit = $user->getLowBatteryStopLimit();
            if ($stopLimit && $batteryLevel >= $stopLimit) {
                Log::info('Low battery emergency charging stop limit reached', [
                    'vehicle_id' => $vehicle->id,
                    'battery_level' => $batteryLevel,
                    'stop_limit' => $stopLimit,
                ]);

                $stopped = $this->tessieService->stopCharging($vehicle, $user);
                if ($stopped) {
                    return [
                        'success' => true,
                        'action_taken' => true,
                        'action' => 'stopped_emergency_charging',
                        'message' => "Emergency charging stopped at {$batteryLevel}% (stop limit: {$stopLimit}%)",
                        'battery_level' => $batteryLevel,
                    ];
                }
            }
        }

        // Normal smart charging evaluation
        return $this->evaluateSmartCharging($vehicle, $user, $state);
    }

    /**
     * Evaluate low battery protection.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @param array $state
     * @return array
     */
    protected function evaluateLowBatteryProtection(Vehicle $vehicle, User $user, array $state): array
    {
        $batteryLevel = $state['battery_level'];
        $isCharging = $state['is_charging'];
        $threshold = $user->getLowBatteryThreshold();
        $stopLimit = $user->getLowBatteryStopLimit();

        if (!$threshold) {
            return [
                'success' => true,
                'action_taken' => false,
                'message' => 'Low battery threshold not configured',
            ];
        }

        // Start emergency charging if battery is below threshold and not already charging
        if ($batteryLevel <= $threshold && !$isCharging) {
            Log::warning('Low battery threshold reached - starting emergency charging', [
                'vehicle_id' => $vehicle->id,
                'battery_level' => $batteryLevel,
                'threshold' => $threshold,
            ]);

            // Set charge limit to stop limit if configured
            if ($stopLimit) {
                $this->tessieService->setChargeLimit($vehicle, $user, $stopLimit);
            }

            $started = $this->tessieService->startCharging($vehicle, $user);

            if ($started) {
                return [
                    'success' => true,
                    'action_taken' => true,
                    'action' => 'started_emergency_charging',
                    'message' => "Emergency charging started - battery at {$batteryLevel}% (threshold: {$threshold}%)",
                    'battery_level' => $batteryLevel,
                    'reason' => 'low_battery_protection',
                ];
            }

            return [
                'success' => false,
                'action_taken' => false,
                'message' => 'Failed to start emergency charging',
            ];
        }

        return [
            'success' => true,
            'action_taken' => false,
            'message' => 'Low battery protection not triggered',
        ];
    }

    /**
     * Evaluate smart charging based on recommendations.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @param array $state
     * @return array
     */
    protected function evaluateSmartCharging(Vehicle $vehicle, User $user, array $state): array
    {
        $batteryLevel = $state['battery_level'];
        $isCharging = $state['is_charging'];

        try {
            // Generate charging recommendation
            $recommendation = $this->smartChargingService->generateRecommendation(
                $vehicle->id,
                [
                    'user' => $user,
                    'energy_needed' => $this->calculateEnergyNeeded($vehicle, $batteryLevel),
                ]
            );

            $shouldChargeNow = $recommendation->should_charge_now;

            // Start charging if recommended and not already charging
            if ($shouldChargeNow && !$isCharging) {
                Log::info('Smart charging recommendation: START', [
                    'vehicle_id' => $vehicle->id,
                    'battery_level' => $batteryLevel,
                    'recommendation_id' => $recommendation->id,
                ]);

                $started = $this->tessieService->startCharging($vehicle, $user);

                if ($started) {
                    $recommendation->update(['status' => 'executed']);

                    return [
                        'success' => true,
                        'action_taken' => true,
                        'action' => 'started_smart_charging',
                        'message' => 'Smart charging started based on optimal pricing',
                        'battery_level' => $batteryLevel,
                        'recommendation_id' => $recommendation->id,
                        'estimated_cost' => $recommendation->estimated_cost,
                        'cost_savings' => $recommendation->cost_savings,
                    ];
                }

                return [
                    'success' => false,
                    'action_taken' => false,
                    'message' => 'Failed to start charging',
                ];
            }

            // Stop charging if not recommended and currently charging
            if (!$shouldChargeNow && $isCharging) {
                Log::info('Smart charging recommendation: STOP', [
                    'vehicle_id' => $vehicle->id,
                    'battery_level' => $batteryLevel,
                    'recommendation_id' => $recommendation->id,
                ]);

                $stopped = $this->tessieService->stopCharging($vehicle, $user);

                if ($stopped) {
                    return [
                        'success' => true,
                        'action_taken' => true,
                        'action' => 'stopped_smart_charging',
                        'message' => 'Charging stopped - waiting for better pricing',
                        'battery_level' => $batteryLevel,
                        'recommendation_id' => $recommendation->id,
                    ];
                }

                return [
                    'success' => false,
                    'action_taken' => false,
                    'message' => 'Failed to stop charging',
                ];
            }

            // No action needed
            $status = $isCharging ? 'charging' : 'waiting';
            return [
                'success' => true,
                'action_taken' => false,
                'message' => "Vehicle {$status} - no action needed",
                'battery_level' => $batteryLevel,
                'should_charge_now' => $shouldChargeNow,
                'recommendation_id' => $recommendation->id,
            ];

        } catch (\Exception $e) {
            Log::error('Error evaluating smart charging', [
                'vehicle_id' => $vehicle->id,
                'error' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'action_taken' => false,
                'message' => 'Error evaluating charging: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Calculate energy needed based on battery level and vehicle capacity.
     *
     * @param Vehicle $vehicle
     * @param int $currentBatteryLevel
     * @return float
     */
    protected function calculateEnergyNeeded(Vehicle $vehicle, int $currentBatteryLevel): float
    {
        $targetLevel = 80; // Default target battery level
        $batteryCapacity = $vehicle->battery_capacity ?? 75; // kWh

        $percentageNeeded = max(0, $targetLevel - $currentBatteryLevel);
        $energyNeeded = ($percentageNeeded / 100) * $batteryCapacity;

        return round($energyNeeded, 2);
    }
}
