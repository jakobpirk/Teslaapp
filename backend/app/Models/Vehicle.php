<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vehicle extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'api_provider',
        'provider_vehicle_id',
        'display_name',
        'vin',
        'model',
        'color',
        'year',
        'battery_capacity',
        'is_active',
        'vehicle_config',
        'charge_limit',
        'auto_charging_enabled',
        'low_battery_protection_enabled',
        'low_battery_threshold',
        'low_battery_stop_limit',
    ];

    protected $casts = [
        'year' => 'integer',
        'battery_capacity' => 'decimal:2',
        'is_active' => 'boolean',
        'vehicle_config' => 'array',
        'charge_limit' => 'integer',
        'auto_charging_enabled' => 'boolean',
        'low_battery_protection_enabled' => 'boolean',
        'low_battery_threshold' => 'integer',
        'low_battery_stop_limit' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $hidden = [
        'provider_vehicle_id', // Hide provider-specific ID for security
    ];

    /**
     * Get the user that owns the vehicle.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the charging sessions for this vehicle.
     */
    public function chargingSessions(): HasMany
    {
        return $this->hasMany(ChargingSession::class);
    }

    /**
     * Get the charging recommendations for this vehicle.
     */
    public function chargingRecommendations(): HasMany
    {
        return $this->hasMany(ChargingRecommendation::class);
    }

    /**
     * Get the scheduled departures for this vehicle.
     */
    public function scheduledDepartures(): HasMany
    {
        return $this->hasMany(ScheduledDeparture::class);
    }

    /**
     * Get the alert rules for this vehicle.
     */
    public function alertRules(): HasMany
    {
        return $this->hasMany(AlertRule::class);
    }

    /**
     * Scope to get only active vehicles.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to filter by user.
     */
    public function scopeByUser($query, string $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Get the most recent charging session.
     */
    public function latestChargingSession()
    {
        return $this->chargingSessions()
            ->orderBy('start_time', 'desc')
            ->first();
    }

    /**
     * Get the latest charging recommendation.
     */
    public function latestChargingRecommendation()
    {
        return $this->chargingRecommendations()
            ->orderBy('created_at', 'desc')
            ->first();
    }

    /**
     * Check if the vehicle uses a specific API provider
     */
    public function usesProvider(string $providerName): bool
    {
        return strtolower($this->api_provider) === strtolower($providerName);
    }

    /**
     * Check if the vehicle uses Tessie API
     */
    public function usesTessie(): bool
    {
        return $this->usesProvider('tessie');
    }

    /**
     * Check if the vehicle uses Tesla official API
     */
    public function usesTesla(): bool
    {
        return $this->usesProvider('tesla');
    }

    /**
     * Scope to filter vehicles by API provider
     */
    public function scopeByProvider($query, string $provider)
    {
        return $query->where('api_provider', strtolower($provider));
    }

    /**
     * Get the API key for this vehicle's provider from the user
     *
     * @return string|null
     */
    public function getProviderApiKey(): ?string
    {
        if (!$this->user) {
            return null;
        }

        // Map provider to user's API key field
        $keyMap = [
            'tessie' => 'tessie_api_key',
            'tesla' => 'tesla_api_key',
            // Add more mappings as needed
        ];

        $keyField = $keyMap[$this->api_provider] ?? null;

        return $keyField ? $this->user->$keyField : null;
    }
}
