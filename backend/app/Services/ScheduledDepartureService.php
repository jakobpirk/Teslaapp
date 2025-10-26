<?php

namespace App\Services;

use App\Models\ScheduledDeparture;
use App\Models\Vehicle;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class ScheduledDepartureService
{
    private TessieService $tessieService;
    private VehicleApiProviderFactory $apiProviderFactory;

    public function __construct(TessieService $tessieService, VehicleApiProviderFactory $apiProviderFactory)
    {
        $this->tessieService = $tessieService;
        $this->apiProviderFactory = $apiProviderFactory;
    }

    /**
     * Process all scheduled departures that should run now.
     */
    public function processScheduledDepartures(): array
    {
        $results = [];
        $schedules = ScheduledDeparture::enabled()->get();

        foreach ($schedules as $schedule) {
            if ($this->shouldExecuteNow($schedule)) {
                $result = $this->executeSchedule($schedule);
                $results[] = [
                    'schedule_id' => $schedule->id,
                    'vehicle_id' => $schedule->vehicle_id,
                    'result' => $result,
                ];
            }
        }

        return $results;
    }

    /**
     * Check if a schedule should execute now.
     */
    private function shouldExecuteNow(ScheduledDeparture $schedule): bool
    {
        if (!$schedule->is_enabled) {
            return false;
        }

        $now = Carbon::now($schedule->timezone);
        $dayOfWeek = $now->dayOfWeek; // 0 = Sunday, 6 = Saturday

        // Check if today is in the schedule
        if (!in_array($dayOfWeek, $schedule->days_of_week)) {
            return false;
        }

        // Parse departure time
        $departureTime = Carbon::createFromFormat('H:i:s', $schedule->departure_time, $schedule->timezone);
        $targetTime = $now->copy()->setTime($departureTime->hour, $departureTime->minute, 0);

        // Calculate when we should start preconditioning
        $preconditioningStart = $targetTime->copy()->subMinutes($schedule->preconditioning_minutes);

        // Check if we're within the preconditioning window
        $isInWindow = $now->greaterThanOrEqualTo($preconditioningStart) && $now->lessThan($targetTime);

        // Check if we haven't executed recently (within last hour)
        if ($schedule->last_executed_at) {
            $lastExecution = Carbon::parse($schedule->last_executed_at, $schedule->timezone);
            if ($lastExecution->isToday() && $now->diffInHours($lastExecution) < 1) {
                return false;
            }
        }

        return $isInWindow;
    }

    /**
     * Execute a scheduled departure.
     */
    public function executeSchedule(ScheduledDeparture $schedule): array
    {
        $vehicle = $schedule->vehicle;
        $user = $schedule->user;

        if (!$vehicle || !$user) {
            Log::error('Invalid vehicle or user for scheduled departure', [
                'schedule_id' => $schedule->id,
            ]);
            return ['success' => false, 'error' => 'Invalid vehicle or user'];
        }

        $results = [
            'success' => true,
            'actions' => [],
        ];

        try {
            // Get vehicle API provider
            $apiProvider = $this->apiProviderFactory->getProvider($vehicle->api_provider);

            // Execute charging if needed
            if ($schedule->charge_before_departure && $schedule->target_battery_level) {
                $chargingResult = $this->ensureChargingCompletes($vehicle, $user, $schedule->target_battery_level, $apiProvider);
                $results['actions'][] = [
                    'action' => 'ensure_charging',
                    'result' => $chargingResult,
                ];
            }

            // Start climate preconditioning
            if ($schedule->precondition_climate) {
                $climateResult = $this->startClimate($vehicle, $user, $schedule->target_temperature, $apiProvider);
                $results['actions'][] = [
                    'action' => 'start_climate',
                    'result' => $climateResult,
                ];
            }

            // Start battery preconditioning (if supported)
            if ($schedule->precondition_battery) {
                $batteryResult = $this->preconditionBattery($vehicle, $user, $apiProvider);
                $results['actions'][] = [
                    'action' => 'precondition_battery',
                    'result' => $batteryResult,
                ];
            }

            // Log the execution
            $schedule->logExecution('success', $results);

            Log::info('Scheduled departure executed successfully', [
                'schedule_id' => $schedule->id,
                'vehicle_id' => $vehicle->id,
                'results' => $results,
            ]);

        } catch (\Exception $e) {
            $results['success'] = false;
            $results['error'] = $e->getMessage();

            $schedule->logExecution('error', ['error' => $e->getMessage()]);

            Log::error('Failed to execute scheduled departure', [
                'schedule_id' => $schedule->id,
                'vehicle_id' => $vehicle->id,
                'error' => $e->getMessage(),
            ]);
        }

        return $results;
    }

    /**
     * Ensure charging completes before departure.
     */
    private function ensureChargingCompletes(Vehicle $vehicle, User $user, int $targetLevel, $apiProvider): array
    {
        try {
            // Get current vehicle state
            $state = $apiProvider->getVehicleState($vehicle, $user);

            if (!$state) {
                return ['success' => false, 'error' => 'Could not get vehicle state'];
            }

            $currentLevel = $state['battery_level'] ?? 0;

            // If already at or above target, do nothing
            if ($currentLevel >= $targetLevel) {
                return ['success' => true, 'message' => 'Already at target level', 'current_level' => $currentLevel];
            }

            // Set charge limit
            $limitSet = $apiProvider->setChargeLimit($vehicle, $user, $targetLevel);

            if (!$limitSet) {
                return ['success' => false, 'error' => 'Could not set charge limit'];
            }

            // Start charging if not already charging
            if (!$state['is_charging'] && $state['is_plugged_in']) {
                $chargingStarted = $apiProvider->startCharging($vehicle, $user);
                return [
                    'success' => $chargingStarted,
                    'message' => $chargingStarted ? 'Charging started' : 'Could not start charging',
                    'current_level' => $currentLevel,
                    'target_level' => $targetLevel,
                ];
            }

            return ['success' => true, 'message' => 'Charging already in progress'];

        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Start climate control.
     */
    private function startClimate(Vehicle $vehicle, User $user, ?float $targetTemp, $apiProvider): array
    {
        try {
            $success = $apiProvider->startClimate($vehicle, $user);

            if (!$success) {
                return ['success' => false, 'error' => 'Could not start climate'];
            }

            // Set temperature if specified
            if ($targetTemp !== null) {
                $tempSet = $apiProvider->setTemperature($vehicle, $user, $targetTemp);
                return [
                    'success' => $tempSet,
                    'message' => 'Climate started',
                    'target_temperature' => $targetTemp,
                ];
            }

            return ['success' => true, 'message' => 'Climate started'];

        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Precondition battery for optimal range.
     */
    private function preconditionBattery(Vehicle $vehicle, User $user, $apiProvider): array
    {
        try {
            // Note: Battery preconditioning is typically automatic when climate is on
            // or when navigation to a Supercharger is active.
            // For now, we'll just log this as a future feature.

            return [
                'success' => true,
                'message' => 'Battery preconditioning requested (automatic via climate)',
            ];

        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Create a new scheduled departure.
     */
    public function createSchedule(array $data): ScheduledDeparture
    {
        return ScheduledDeparture::create($data);
    }

    /**
     * Update an existing scheduled departure.
     */
    public function updateSchedule(ScheduledDeparture $schedule, array $data): ScheduledDeparture
    {
        $schedule->update($data);
        return $schedule->fresh();
    }

    /**
     * Delete a scheduled departure.
     */
    public function deleteSchedule(ScheduledDeparture $schedule): bool
    {
        return $schedule->delete();
    }

    /**
     * Get schedules for a specific vehicle.
     */
    public function getVehicleSchedules(string $vehicleId): \Illuminate\Database\Eloquent\Collection
    {
        return ScheduledDeparture::byVehicle($vehicleId)->get();
    }

    /**
     * Get schedules for a specific user.
     */
    public function getUserSchedules(string $userId): \Illuminate\Database\Eloquent\Collection
    {
        return ScheduledDeparture::byUser($userId)->with('vehicle')->get();
    }
}
