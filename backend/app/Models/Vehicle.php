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
        'tessie_vehicle_id',
        'display_name',
        'vin',
        'model',
        'color',
        'year',
        'battery_capacity',
        'is_active',
        'vehicle_config',
    ];

    protected $casts = [
        'year' => 'integer',
        'battery_capacity' => 'decimal:2',
        'is_active' => 'boolean',
        'vehicle_config' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $hidden = [
        'tessie_vehicle_id', // Hide for security
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
}
