<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AlertRule extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'vehicle_id',
        'name',
        'description',
        'rule_type',
        'conditions',
        'notification_channels',
        'notification_title',
        'notification_message',
        'is_enabled',
        'cooldown_minutes',
        'priority',
        'last_triggered_at',
        'last_evaluated_at',
        'trigger_count',
    ];

    protected $casts = [
        'conditions' => 'array',
        'notification_channels' => 'array',
        'is_enabled' => 'boolean',
        'cooldown_minutes' => 'integer',
        'priority' => 'integer',
        'trigger_count' => 'integer',
        'last_triggered_at' => 'datetime',
        'last_evaluated_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Rule types constants
    public const TYPE_NOT_PLUGGED_IN = 'not_plugged_in';
    public const TYPE_BATTERY_LOW = 'battery_low';
    public const TYPE_CHARGE_COMPLETE = 'charge_complete';
    public const TYPE_LEFT_UNLOCKED = 'left_unlocked';
    public const TYPE_SENTRY_TRIGGERED = 'sentry_triggered';
    public const TYPE_UNUSUAL_ENERGY = 'unusual_energy_consumption';
    public const TYPE_CLIMATE_ON = 'climate_on';
    public const TYPE_SOFTWARE_UPDATE = 'software_update_available';
    public const TYPE_CUSTOM = 'custom';

    /**
     * Get the user for this alert rule.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the vehicle for this alert rule (nullable for all-vehicles rules).
     */
    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * Scope to get only enabled rules.
     */
    public function scopeEnabled($query)
    {
        return $query->where('is_enabled', true);
    }

    /**
     * Scope to get rules by user.
     */
    public function scopeByUser($query, string $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope to get rules by vehicle (including all-vehicle rules).
     */
    public function scopeByVehicle($query, string $vehicleId)
    {
        return $query->where(function ($q) use ($vehicleId) {
            $q->where('vehicle_id', $vehicleId)
              ->orWhereNull('vehicle_id');
        });
    }

    /**
     * Scope to get rules by type.
     */
    public function scopeByType($query, string $type)
    {
        return $query->where('rule_type', $type);
    }

    /**
     * Scope to get rules by priority.
     */
    public function scopeByPriority($query, int $priority)
    {
        return $query->where('priority', $priority);
    }

    /**
     * Check if the rule is in cooldown period.
     */
    public function isInCooldown(): bool
    {
        if (!$this->last_triggered_at) {
            return false;
        }

        $cooldownEnds = $this->last_triggered_at->addMinutes($this->cooldown_minutes);
        return now()->isBefore($cooldownEnds);
    }

    /**
     * Check if the rule can be triggered now.
     */
    public function canTrigger(): bool
    {
        return $this->is_enabled && !$this->isInCooldown();
    }

    /**
     * Record a trigger event.
     */
    public function recordTrigger(): void
    {
        $this->increment('trigger_count');
        $this->last_triggered_at = now();
        $this->save();
    }

    /**
     * Update the last evaluation timestamp.
     */
    public function recordEvaluation(): void
    {
        $this->last_evaluated_at = now();
        $this->save();
    }

    /**
     * Get the notification title or generate default.
     */
    public function getNotificationTitle(): string
    {
        if ($this->notification_title) {
            return $this->notification_title;
        }

        // Generate default titles based on rule type
        $defaults = [
            self::TYPE_NOT_PLUGGED_IN => 'Vehicle Not Plugged In',
            self::TYPE_BATTERY_LOW => 'Low Battery Alert',
            self::TYPE_CHARGE_COMPLETE => 'Charging Complete',
            self::TYPE_LEFT_UNLOCKED => 'Vehicle Left Unlocked',
            self::TYPE_SENTRY_TRIGGERED => 'Sentry Mode Activated',
            self::TYPE_UNUSUAL_ENERGY => 'Unusual Energy Consumption',
            self::TYPE_CLIMATE_ON => 'Climate Control Active',
            self::TYPE_SOFTWARE_UPDATE => 'Software Update Available',
            self::TYPE_CUSTOM => 'Vehicle Alert',
        ];

        return $defaults[$this->rule_type] ?? 'Vehicle Notification';
    }

    /**
     * Get the notification message or generate default.
     */
    public function getNotificationMessage(array $context = []): string
    {
        if ($this->notification_message) {
            return $this->replaceMessagePlaceholders($this->notification_message, $context);
        }

        // Generate default message based on rule type
        return $this->generateDefaultMessage($context);
    }

    /**
     * Replace placeholders in message with context values.
     */
    private function replaceMessagePlaceholders(string $message, array $context): string
    {
        foreach ($context as $key => $value) {
            $message = str_replace("{{$key}}", $value, $message);
        }
        return $message;
    }

    /**
     * Generate a default message based on rule type and context.
     */
    private function generateDefaultMessage(array $context): string
    {
        $vehicleName = $context['vehicle_name'] ?? 'Your vehicle';

        $defaults = [
            self::TYPE_NOT_PLUGGED_IN => "{$vehicleName} is not plugged in.",
            self::TYPE_BATTERY_LOW => "{$vehicleName} battery is low at {$context['battery_level']}%.",
            self::TYPE_CHARGE_COMPLETE => "{$vehicleName} has finished charging.",
            self::TYPE_LEFT_UNLOCKED => "{$vehicleName} has been left unlocked.",
            self::TYPE_SENTRY_TRIGGERED => "{$vehicleName} sentry mode has detected activity.",
            self::TYPE_UNUSUAL_ENERGY => "{$vehicleName} is showing unusual energy consumption.",
            self::TYPE_CLIMATE_ON => "{$vehicleName} climate control is running.",
            self::TYPE_SOFTWARE_UPDATE => "A software update is available for {$vehicleName}.",
            self::TYPE_CUSTOM => "{$vehicleName} alert triggered.",
        ];

        return $defaults[$this->rule_type] ?? "Alert for {$vehicleName}.";
    }
}
