<?php

namespace App\Services;

use App\Models\AlertRule;
use App\Models\Vehicle;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Carbon\Carbon;

class AlertRuleService
{
    private VehicleApiProviderFactory $apiProviderFactory;

    public function __construct(VehicleApiProviderFactory $apiProviderFactory)
    {
        $this->apiProviderFactory = $apiProviderFactory;
    }

    /**
     * Evaluate all enabled alert rules.
     */
    public function evaluateAllRules(): array
    {
        $results = [];
        $rules = AlertRule::enabled()->with(['user', 'vehicle'])->get();

        foreach ($rules as $rule) {
            if ($rule->canTrigger()) {
                $evaluationResult = $this->evaluateRule($rule);
                if ($evaluationResult['triggered']) {
                    $results[] = [
                        'rule_id' => $rule->id,
                        'result' => $evaluationResult,
                    ];
                }
            }

            // Update evaluation timestamp
            $rule->recordEvaluation();
        }

        return $results;
    }

    /**
     * Evaluate a single alert rule.
     */
    public function evaluateRule(AlertRule $rule): array
    {
        $result = [
            'triggered' => false,
            'message' => null,
            'context' => [],
        ];

        try {
            // Get vehicles to check
            $vehicles = $this->getVehiclesForRule($rule);

            foreach ($vehicles as $vehicle) {
                $apiProvider = $this->apiProviderFactory->getProvider($vehicle->api_provider);
                $state = $apiProvider->getVehicleState($vehicle, $rule->user);

                if (!$state) {
                    continue;
                }

                $context = [
                    'vehicle_id' => $vehicle->id,
                    'vehicle_name' => $vehicle->display_name,
                    'battery_level' => $state['battery_level'] ?? 0,
                    'is_charging' => $state['is_charging'] ?? false,
                    'is_plugged_in' => $state['is_plugged_in'] ?? false,
                    'charging_state' => $state['charging_state'] ?? 'Unknown',
                ];

                // Evaluate based on rule type
                $triggered = $this->evaluateRuleCondition($rule, $state, $context);

                if ($triggered) {
                    $result['triggered'] = true;
                    $result['context'] = $context;
                    $result['message'] = $rule->getNotificationMessage($context);

                    // Send notification
                    $this->sendNotification($rule, $context);

                    // Record trigger
                    $rule->recordTrigger();

                    Log::info('Alert rule triggered', [
                        'rule_id' => $rule->id,
                        'rule_type' => $rule->rule_type,
                        'vehicle_id' => $vehicle->id,
                        'context' => $context,
                    ]);

                    break; // One trigger per evaluation cycle
                }
            }

        } catch (\Exception $e) {
            Log::error('Error evaluating alert rule', [
                'rule_id' => $rule->id,
                'error' => $e->getMessage(),
            ]);
        }

        return $result;
    }

    /**
     * Evaluate rule condition based on rule type.
     */
    private function evaluateRuleCondition(AlertRule $rule, array $state, array $context): bool
    {
        $conditions = $rule->conditions;

        switch ($rule->rule_type) {
            case AlertRule::TYPE_NOT_PLUGGED_IN:
                return $this->evaluateNotPluggedIn($conditions, $state);

            case AlertRule::TYPE_BATTERY_LOW:
                return $this->evaluateBatteryLow($conditions, $state);

            case AlertRule::TYPE_CHARGE_COMPLETE:
                return $this->evaluateChargeComplete($conditions, $state);

            case AlertRule::TYPE_LEFT_UNLOCKED:
                return $this->evaluateLeftUnlocked($conditions, $state);

            case AlertRule::TYPE_SENTRY_TRIGGERED:
                return $this->evaluateSentryTriggered($conditions, $state);

            case AlertRule::TYPE_CLIMATE_ON:
                return $this->evaluateClimateOn($conditions, $state);

            case AlertRule::TYPE_UNUSUAL_ENERGY:
                return $this->evaluateUnusualEnergy($conditions, $state);

            default:
                return false;
        }
    }

    /**
     * Evaluate "not plugged in" condition.
     */
    private function evaluateNotPluggedIn(array $conditions, array $state): bool
    {
        $isPluggedIn = $state['is_plugged_in'] ?? false;

        if ($isPluggedIn) {
            return false;
        }

        // Check if current time matches the condition
        if (isset($conditions['time_after'])) {
            $now = Carbon::now();
            $timeAfter = Carbon::createFromFormat('H:i', $conditions['time_after']);

            if ($now->lessThan($timeAfter)) {
                return false;
            }
        }

        // Check if current day matches
        if (isset($conditions['days']) && is_array($conditions['days'])) {
            $today = Carbon::now()->dayOfWeek;
            if (!in_array($today, $conditions['days'])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Evaluate "battery low" condition.
     */
    private function evaluateBatteryLow(array $conditions, array $state): bool
    {
        $batteryLevel = $state['battery_level'] ?? 100;
        $threshold = $conditions['threshold'] ?? 20;

        if ($batteryLevel > $threshold) {
            return false;
        }

        // Check if should only alert when unplugged
        if (isset($conditions['when_unplugged']) && $conditions['when_unplugged']) {
            $isPluggedIn = $state['is_plugged_in'] ?? false;
            if ($isPluggedIn) {
                return false;
            }
        }

        return true;
    }

    /**
     * Evaluate "charge complete" condition.
     */
    private function evaluateChargeComplete(array $conditions, array $state): bool
    {
        $batteryLevel = $state['battery_level'] ?? 0;
        $chargingState = $state['charging_state'] ?? '';
        $notifyAtPercentage = $conditions['notify_at_percentage'] ?? 80;

        // Check if charging just completed or reached target
        return $batteryLevel >= $notifyAtPercentage &&
               in_array($chargingState, ['Complete', 'Stopped']) &&
               ($state['is_plugged_in'] ?? false);
    }

    /**
     * Evaluate "left unlocked" condition.
     */
    private function evaluateLeftUnlocked(array $conditions, array $state): bool
    {
        $isLocked = $state['locked'] ?? true;

        if ($isLocked) {
            return false;
        }

        // TODO: Implement duration check (would need to track state changes)
        // For now, just check if unlocked

        return true;
    }

    /**
     * Evaluate "sentry triggered" condition.
     */
    private function evaluateSentryTriggered(array $conditions, array $state): bool
    {
        $sentryMode = $state['sentry_mode'] ?? false;
        $sentryEvents = $state['sentry_events'] ?? 0;

        // This would need integration with sentry mode event API
        return $sentryMode && $sentryEvents > 0;
    }

    /**
     * Evaluate "climate on" condition.
     */
    private function evaluateClimateOn(array $conditions, array $state): bool
    {
        $isClimateOn = $state['is_climate_on'] ?? false;
        $durationMinutes = $conditions['duration_minutes'] ?? 30;

        // TODO: Implement duration tracking
        // For now, just check if climate is on

        return $isClimateOn;
    }

    /**
     * Evaluate "unusual energy consumption" condition.
     */
    private function evaluateUnusualEnergy(array $conditions, array $state): bool
    {
        // This would need historical data analysis
        // Placeholder for now
        return false;
    }

    /**
     * Get vehicles for rule evaluation.
     */
    private function getVehiclesForRule(AlertRule $rule): \Illuminate\Database\Eloquent\Collection
    {
        if ($rule->vehicle_id) {
            return collect([$rule->vehicle]);
        }

        // Get all active vehicles for user
        return Vehicle::byUser($rule->user_id)->active()->get();
    }

    /**
     * Send notification for triggered rule.
     */
    private function sendNotification(AlertRule $rule, array $context): void
    {
        $channels = $rule->notification_channels ?? ['push'];

        $title = $rule->getNotificationTitle();
        $message = $rule->getNotificationMessage($context);

        Log::info('Sending alert notification', [
            'rule_id' => $rule->id,
            'channels' => $channels,
            'title' => $title,
            'message' => $message,
        ]);

        // TODO: Implement actual notification sending via FCM, email, etc.
        // For now, just log the notification
    }

    /**
     * Create a new alert rule.
     */
    public function createRule(array $data): AlertRule
    {
        return AlertRule::create($data);
    }

    /**
     * Update an existing alert rule.
     */
    public function updateRule(AlertRule $rule, array $data): AlertRule
    {
        $rule->update($data);
        return $rule->fresh();
    }

    /**
     * Delete an alert rule.
     */
    public function deleteRule(AlertRule $rule): bool
    {
        return $rule->delete();
    }

    /**
     * Get alert rules for a user.
     */
    public function getUserRules(string $userId): \Illuminate\Database\Eloquent\Collection
    {
        return AlertRule::byUser($userId)->with('vehicle')->get();
    }

    /**
     * Get alert rules for a vehicle.
     */
    public function getVehicleRules(string $vehicleId): \Illuminate\Database\Eloquent\Collection
    {
        return AlertRule::byVehicle($vehicleId)->get();
    }

    /**
     * Test an alert rule without saving trigger state.
     */
    public function testRule(AlertRule $rule): array
    {
        return $this->evaluateRule($rule);
    }
}
