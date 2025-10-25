<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'tessie_api_key',
        'electricity_provider_id',
        'pricing_region',
        'auto_charging_enabled',
        'low_battery_protection_enabled',
        'low_battery_threshold',
        'low_battery_stop_limit',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'tessie_api_key', // Hide API key from serialization
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'auto_charging_enabled' => 'boolean',
        'low_battery_protection_enabled' => 'boolean',
        'low_battery_threshold' => 'integer',
        'low_battery_stop_limit' => 'integer',
    ];

    /**
     * Get the electricity provider for this user.
     */
    public function electricityProvider(): BelongsTo
    {
        return $this->belongsTo(ElectricityProvider::class);
    }

    /**
     * Get the vehicles owned by this user.
     */
    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    /**
     * Get active vehicles only.
     */
    public function activeVehicles(): HasMany
    {
        return $this->vehicles()->where('is_active', true);
    }

    /**
     * Check if user has configured Tessie API key.
     */
    public function hasTessieApiKey(): bool
    {
        return !empty($this->tessie_api_key);
    }

    /**
     * Check if user has selected an electricity provider.
     */
    public function hasElectricityProvider(): bool
    {
        return !empty($this->electricity_provider_id);
    }

    /**
     * Check if user has set a pricing region.
     */
    public function hasPricingRegion(): bool
    {
        return !empty($this->pricing_region);
    }

    /**
     * Get the pricing region (e.g., 'east' or 'west' for Aura).
     */
    public function getPricingRegion(): ?string
    {
        return $this->pricing_region;
    }

    /**
     * Check if automatic charging is enabled.
     */
    public function isAutoChargingEnabled(): bool
    {
        return $this->auto_charging_enabled === true;
    }

    /**
     * Check if low battery protection is enabled.
     */
    public function isLowBatteryProtectionEnabled(): bool
    {
        return $this->low_battery_protection_enabled === true;
    }

    /**
     * Get low battery threshold percentage.
     */
    public function getLowBatteryThreshold(): ?int
    {
        return $this->low_battery_threshold;
    }

    /**
     * Get low battery stop limit percentage.
     */
    public function getLowBatteryStopLimit(): ?int
    {
        return $this->low_battery_stop_limit;
    }
}
