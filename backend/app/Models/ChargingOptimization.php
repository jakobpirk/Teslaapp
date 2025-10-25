<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChargingOptimization extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'charging_optimizations';

    protected $fillable = [
        'vehicle_id',
        'charging_recommendation_id',
        'decision_timestamp',
        'optimization_version',
        'recommended_window_start',
        'recommended_window_end',
        'was_executed',
        'predicted_cost',
        'predicted_savings',
        'actual_cost',
        'cost_variance',
        'factors_used',
        'factors_breakdown',
        'factor_weights',
        'weather_data',
        'carbon_data',
        'price_data',
        'composite_score',
        'prediction_accuracy',
    ];

    protected $casts = [
        'decision_timestamp' => 'datetime',
        'recommended_window_start' => 'datetime',
        'recommended_window_end' => 'datetime',
        'was_executed' => 'boolean',
        'predicted_cost' => 'float',
        'predicted_savings' => 'float',
        'actual_cost' => 'float',
        'cost_variance' => 'float',
        'factors_used' => 'array',
        'factors_breakdown' => 'array',
        'factor_weights' => 'array',
        'weather_data' => 'array',
        'carbon_data' => 'array',
        'price_data' => 'array',
        'composite_score' => 'float',
        'prediction_accuracy' => 'float',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get the vehicle this optimization is for
     */
    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * Get the charging recommendation associated with this optimization
     */
    public function chargingRecommendation(): BelongsTo
    {
        return $this->belongsTo(ChargingRecommendation::class);
    }

    /**
     * Record actual results after charging completes
     */
    public function recordActualResults(float $actualCost): void
    {
        $variance = $actualCost - $this->predicted_cost;
        $accuracy = 100 - (abs($variance) / $this->predicted_cost * 100);

        $this->update([
            'was_executed' => true,
            'actual_cost' => $actualCost,
            'cost_variance' => $variance,
            'prediction_accuracy' => max(0, min(100, $accuracy)),
        ]);
    }

    /**
     * Get optimizations for performance analysis
     */
    public static function getForPerformanceAnalysis(string $optimizationVersion, \DateTime $start, \DateTime $end)
    {
        return static::where('optimization_version', $optimizationVersion)
            ->whereBetween('decision_timestamp', [$start, $end])
            ->where('was_executed', true)
            ->whereNotNull('actual_cost')
            ->get();
    }

    /**
     * Calculate savings achieved
     */
    public function getActualSavings(): ?float
    {
        if ($this->actual_cost === null) {
            return null;
        }

        // Calculate what it would have cost to charge immediately
        // This is predicted_cost + predicted_savings
        $immediateChargeCost = $this->predicted_cost + $this->predicted_savings;
        return $immediateChargeCost - $this->actual_cost;
    }
}
