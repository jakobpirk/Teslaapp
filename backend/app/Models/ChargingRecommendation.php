<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChargingRecommendation extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'charging_recommendations';

    protected $fillable = [
        'vehicle_id',
        'recommended_start_time',
        'recommended_end_time',
        'estimated_cost',
        'cost_savings',
        'confidence_score',
        'should_charge_now',
        'factor_scores',
        'reasoning',
        'status',
        'executed_at',
    ];

    protected $casts = [
        'recommended_start_time' => 'datetime',
        'recommended_end_time' => 'datetime',
        'estimated_cost' => 'float',
        'cost_savings' => 'float',
        'confidence_score' => 'integer',
        'should_charge_now' => 'boolean',
        'factor_scores' => 'array',
        'executed_at' => 'datetime',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get the latest recommendation for a vehicle
     */
    public static function getLatestForVehicle(string $vehicleId)
    {
        return static::where('vehicle_id', $vehicleId)
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->first();
    }

    /**
     * Mark recommendation as executed
     */
    public function markAsExecuted()
    {
        $this->update([
            'status' => 'executed',
            'executed_at' => now(),
        ]);
    }

    /**
     * Check if this recommendation is still valid
     */
    public function isValid(): bool
    {
        return $this->status === 'pending'
            && $this->recommended_start_time->isFuture();
    }
}
