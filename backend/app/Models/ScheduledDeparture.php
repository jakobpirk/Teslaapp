<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ScheduledDeparture extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'vehicle_id',
        'user_id',
        'departure_time',
        'days_of_week',
        'timezone',
        'is_enabled',
        'precondition_climate',
        'precondition_battery',
        'target_temperature',
        'preconditioning_minutes',
        'charge_before_departure',
        'target_battery_level',
        'off_peak_only',
        'last_executed_at',
        'execution_log',
    ];

    protected $casts = [
        'days_of_week' => 'array',
        'is_enabled' => 'boolean',
        'precondition_climate' => 'boolean',
        'precondition_battery' => 'boolean',
        'target_temperature' => 'float',
        'preconditioning_minutes' => 'integer',
        'charge_before_departure' => 'boolean',
        'target_battery_level' => 'integer',
        'off_peak_only' => 'boolean',
        'last_executed_at' => 'datetime',
        'execution_log' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the vehicle for this scheduled departure.
     */
    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * Get the user for this scheduled departure.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope to get only enabled schedules.
     */
    public function scopeEnabled($query)
    {
        return $query->where('is_enabled', true);
    }

    /**
     * Scope to get schedules for a specific day of week.
     * @param int $dayOfWeek 0=Sunday, 1=Monday, ..., 6=Saturday
     */
    public function scopeForDay($query, int $dayOfWeek)
    {
        return $query->whereJsonContains('days_of_week', $dayOfWeek);
    }

    /**
     * Scope to get schedules by user.
     */
    public function scopeByUser($query, string $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope to get schedules by vehicle.
     */
    public function scopeByVehicle($query, string $vehicleId)
    {
        return $query->where('vehicle_id', $vehicleId);
    }

    /**
     * Check if this schedule should run today.
     */
    public function shouldRunToday(): bool
    {
        $today = now($this->timezone)->dayOfWeek; // 0=Sunday, 6=Saturday
        return in_array($today, $this->days_of_week);
    }

    /**
     * Get the next scheduled run time.
     */
    public function getNextRunTime(): ?\DateTime
    {
        if (!$this->is_enabled) {
            return null;
        }

        $now = now($this->timezone);
        $departureTime = \Carbon\Carbon::createFromFormat('H:i:s', $this->departure_time, $this->timezone);

        // Start checking from today
        $nextRun = $now->copy()->setTime(
            $departureTime->hour,
            $departureTime->minute,
            $departureTime->second
        );

        // Find the next valid day
        for ($i = 0; $i < 7; $i++) {
            $checkDate = $now->copy()->addDays($i);
            $dayOfWeek = $checkDate->dayOfWeek;

            if (in_array($dayOfWeek, $this->days_of_week)) {
                $nextRun = $checkDate->setTime(
                    $departureTime->hour,
                    $departureTime->minute,
                    $departureTime->second
                );

                // If this is today but the time has passed, continue to next day
                if ($i === 0 && $nextRun->isPast()) {
                    continue;
                }

                return $nextRun;
            }
        }

        return null;
    }

    /**
     * Log an execution event.
     */
    public function logExecution(string $status, array $details = []): void
    {
        $log = $this->execution_log ?? [];

        // Keep only last 10 executions
        if (count($log) >= 10) {
            array_shift($log);
        }

        $log[] = [
            'timestamp' => now()->toIso8601String(),
            'status' => $status,
            'details' => $details,
        ];

        $this->execution_log = $log;
        $this->last_executed_at = now();
        $this->save();
    }
}
