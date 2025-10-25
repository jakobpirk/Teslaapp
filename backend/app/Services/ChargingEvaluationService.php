<?php

namespace App\Services;

use App\Models\User;
use App\Models\Vehicle;
use App\Contracts\VehicleApiProviderContract;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class ChargingEvaluationService
{
    private const DEFAULT_TARGET_BATTERY_LEVEL = 80; // Default target battery level in percent
    private const DEFAULT_BATTERY_CAPACITY_KWH = 75.0; // Default battery capacity in kWh

    protected SmartChargingService $smartChargingService;

    public function __construct(
        SmartChargingService $smartChargingService
    ) {
        $this->smartChargingService = $smartChargingService;
    }

    /**
     * Get the appropriate API provider for a vehicle
     *
     * @param Vehicle $vehicle
     * @return VehicleApiProviderContract
     */
    protected function getProvider(Vehicle $vehicle): VehicleApiProviderContract
    {
        return VehicleApiProviderFactory::make($vehicle->api_provider);
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
        // Get the appropriate API provider for this vehicle
        $provider = $this->getProvider($vehicle);
        $apiKey = $vehicle->getProviderApiKey();

        if (!$apiKey) {
            return [
                'success' => false,
                'action_taken' => false,
                'message' => 'API key not configured for vehicle provider',
            ];
        }

        // Get current vehicle state
        try {
            $state = $provider->getVehicleState($vehicle->provider_vehicle_id, $apiKey);
        } catch (\Exception $e) {
            Log::error('Failed to fetch vehicle state', [
                'vehicle_id' => $vehicle->id,
                'provider' => $vehicle->api_provider,
                'error' => $e->getMessage(),
            ]);
            return [
                'success' => false,
                'action_taken' => false,
                'message' => 'Failed to fetch vehicle state: ' . $e->getMessage(),
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
            $result = $this->evaluateLowBatteryProtection($vehicle, $user, $state, $provider, $apiKey);
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

                try {
                    $provider->stopCharging($vehicle->provider_vehicle_id, $apiKey);
                    return [
                        'success' => true,
                        'action_taken' => true,
                        'action' => 'stopped_emergency_charging',
                        'message' => "Emergency charging stopped at {$batteryLevel}% (stop limit: {$stopLimit}%)",
                        'battery_level' => $batteryLevel,
                    ];
                } catch (\Exception $e) {
                    Log::error('Failed to stop emergency charging', [
                        'vehicle_id' => $vehicle->id,
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        }

        // Normal smart charging evaluation
        return $this->evaluateSmartCharging($vehicle, $user, $state, $provider, $apiKey);
    }

    /**
     * Evaluate low battery protection.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @param array $state
     * @param VehicleApiProviderContract $provider
     * @param string $apiKey
     * @return array
     */
    protected function evaluateLowBatteryProtection(
        Vehicle $vehicle,
        User $user,
        array $state,
        VehicleApiProviderContract $provider,
        string $apiKey
    ): array {
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

            try {
                // Set charge limit to stop limit if configured
                if ($stopLimit) {
                    $provider->setChargeLimit($vehicle->provider_vehicle_id, $apiKey, $stopLimit);
                }

                $provider->startCharging($vehicle->provider_vehicle_id, $apiKey);

                return [
                    'success' => true,
                    'action_taken' => true,
                    'action' => 'started_emergency_charging',
                    'message' => "Emergency charging started - battery at {$batteryLevel}% (threshold: {$threshold}%)",
                    'battery_level' => $batteryLevel,
                    'reason' => 'low_battery_protection',
                ];
            } catch (\Exception $e) {
                Log::error('Failed to start emergency charging', [
                    'vehicle_id' => $vehicle->id,
                    'error' => $e->getMessage(),
                ]);
                return [
                    'success' => false,
                    'action_taken' => false,
                    'message' => 'Failed to start emergency charging: ' . $e->getMessage(),
                ];
            }
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
     * @param VehicleApiProviderContract $provider
     * @param string $apiKey
     * @return array
     */
    protected function evaluateSmartCharging(
        Vehicle $vehicle,
        User $user,
        array $state,
        VehicleApiProviderContract $provider,
        string $apiKey
    ): array {
        $batteryLevel = $state['battery_level'];
        $isCharging = $state['is_charging'];

        try {
            // Generate charging recommendation
            $recommendation = $this->smartChargingService->generateRecommendation(
                $vehicle->id,
                [
                    'user' => $user,
                    'battery_level' => $batteryLevel,
                    'energy_needed' => $this->calculateEnergyNeeded($vehicle, $batteryLevel),
                ]
            );

            if (!$recommendation) {
                Log::error('Failed to generate charging recommendation', [
                    'vehicle_id' => $vehicle->id,
                ]);
                return [
                    'success' => false,
                    'action_taken' => false,
                    'message' => 'Failed to generate charging recommendation',
                ];
            }

            $shouldChargeNow = $recommendation->should_charge_now;

            // Start charging if recommended and not already charging
            if ($shouldChargeNow && !$isCharging) {
                Log::info('Smart charging recommendation: START', [
                    'vehicle_id' => $vehicle->id,
                    'battery_level' => $batteryLevel,
                    'recommendation_id' => $recommendation->id,
                ]);

                try {
                    $provider->startCharging($vehicle->provider_vehicle_id, $apiKey);
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
                } catch (\Exception $e) {
                    Log::error('Failed to start smart charging', [
                        'vehicle_id' => $vehicle->id,
                        'error' => $e->getMessage(),
                    ]);
                    return [
                        'success' => false,
                        'action_taken' => false,
                        'message' => 'Failed to start charging: ' . $e->getMessage(),
                    ];
                }
            }

            // Stop charging if not recommended and currently charging
            if (!$shouldChargeNow && $isCharging) {
                Log::info('Smart charging recommendation: STOP', [
                    'vehicle_id' => $vehicle->id,
                    'battery_level' => $batteryLevel,
                    'recommendation_id' => $recommendation->id,
                ]);

                try {
                    $provider->stopCharging($vehicle->provider_vehicle_id, $apiKey);
                    return [
                        'success' => true,
                        'action_taken' => true,
                        'action' => 'stopped_smart_charging',
                        'message' => 'Charging stopped - waiting for better pricing',
                        'battery_level' => $batteryLevel,
                        'recommendation_id' => $recommendation->id,
                    ];
                } catch (\Exception $e) {
                    Log::error('Failed to stop smart charging', [
                        'vehicle_id' => $vehicle->id,
                        'error' => $e->getMessage(),
                    ]);
                    return [
                        'success' => false,
                        'action_taken' => false,
                        'message' => 'Failed to stop charging: ' . $e->getMessage(),
                    ];
                }
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
        $targetLevel = self::DEFAULT_TARGET_BATTERY_LEVEL;
        $batteryCapacity = $vehicle->battery_capacity ?? self::DEFAULT_BATTERY_CAPACITY_KWH;

        // Validate inputs
        if ($currentBatteryLevel < 0 || $currentBatteryLevel > 100) {
            Log::warning('Invalid battery level', [
                'vehicle_id' => $vehicle->id,
                'battery_level' => $currentBatteryLevel,
            ]);
            $currentBatteryLevel = max(0, min(100, $currentBatteryLevel));
        }

        $percentageNeeded = max(0, $targetLevel - $currentBatteryLevel);
        $energyNeeded = ($percentageNeeded / 100) * $batteryCapacity;

        return round($energyNeeded, 2);
    }
}
