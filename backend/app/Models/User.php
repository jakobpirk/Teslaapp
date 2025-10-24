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
}
