<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OptimizationPerformanceMetric extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'optimization_performance_metrics';

    protected $fillable = [
        'date',
        'optimization_version',
        'region',
        'total_decisions',
        'successful_executions',
        'failed_executions',
        'skipped_decisions',
        'total_cost',
        'total_savings',
        'avg_cost_savings',
        'avg_cost_per_session',
        'avg_prediction_accuracy',
        'avg_price_prediction_error',
        'factor_performance',
        'metrics_json',
    ];

    protected $casts = [
        'date' => 'date',
        'total_decisions' => 'integer',
        'successful_executions' => 'integer',
        'failed_executions' => 'integer',
        'skipped_decisions' => 'integer',
        'total_cost' => 'float',
        'total_savings' => 'float',
        'avg_cost_savings' => 'float',
        'avg_cost_per_session' => 'float',
        'avg_prediction_accuracy' => 'float',
        'avg_price_prediction_error' => 'float',
        'factor_performance' => 'array',
        'metrics_json' => 'array',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get metrics for a date range
     */
    public static function getForDateRange(\DateTime $start, \DateTime $end, ?string $version = null, ?string $region = null)
    {
        $query = static::whereBetween('date', [$start, $end]);

        if ($version) {
            $query->where('optimization_version', $version);
        }

        if ($region) {
            $query->where('region', $region);
        }

        return $query->orderBy('date')->get();
    }

    /**
     * Get latest metrics for a version
     */
    public static function getLatest(?string $version = null, ?string $region = null)
    {
        $query = static::orderBy('date', 'desc');

        if ($version) {
            $query->where('optimization_version', $version);
        }

        if ($region) {
            $query->where('region', $region);
        }

        return $query->first();
    }

    /**
     * Calculate success rate
     */
    public function getSuccessRate(): float
    {
        if ($this->total_decisions === 0) {
            return 0;
        }

        return ($this->successful_executions / $this->total_decisions) * 100;
    }

    /**
     * Get average savings per day
     */
    public function getAverageSavingsPerDay(): float
    {
        return $this->total_decisions > 0
            ? $this->total_savings / $this->total_decisions
            : 0;
    }
}
