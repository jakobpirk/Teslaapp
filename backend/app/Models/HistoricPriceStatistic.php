<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HistoricPriceStatistic extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'historic_price_statistics';

    protected $fillable = [
        'region',
        'hour_of_day',
        'day_of_week',
        'month',
        'avg_price',
        'median_price',
        'min_price',
        'max_price',
        'percentile_10',
        'percentile_25',
        'percentile_75',
        'percentile_90',
        'std_deviation',
        'variance',
        'sample_count',
        'data_start_date',
        'data_end_date',
        'last_updated',
    ];

    protected $casts = [
        'hour_of_day' => 'integer',
        'day_of_week' => 'integer',
        'month' => 'integer',
        'avg_price' => 'float',
        'median_price' => 'float',
        'min_price' => 'float',
        'max_price' => 'float',
        'percentile_10' => 'float',
        'percentile_25' => 'float',
        'percentile_75' => 'float',
        'percentile_90' => 'float',
        'std_deviation' => 'float',
        'variance' => 'float',
        'sample_count' => 'integer',
        'data_start_date' => 'date',
        'data_end_date' => 'date',
        'last_updated' => 'datetime',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get typical price for a specific hour and day pattern
     */
    public static function getTypicalPrice(string $region, int $hourOfDay, ?int $dayOfWeek = null, ?int $month = null)
    {
        $query = static::where('region', $region)
            ->where('hour_of_day', $hourOfDay);

        if ($dayOfWeek !== null) {
            $query->where('day_of_week', $dayOfWeek);
        }

        if ($month !== null) {
            $query->where('month', $month);
        }

        return $query->first();
    }

    /**
     * Get all statistics for a specific hour across all days
     */
    public static function getHourlyPattern(string $region, int $hourOfDay)
    {
        return static::where('region', $region)
            ->where('hour_of_day', $hourOfDay)
            ->whereNull('day_of_week')
            ->whereNull('month')
            ->first();
    }

    /**
     * Calculate if a price is anomalous
     */
    public function isAnomalous(float $price, float $stdDevThreshold = 2.0): bool
    {
        $deviation = abs($price - $this->avg_price);
        return $deviation > ($this->std_deviation * $stdDevThreshold);
    }

    /**
     * Get percentile rank of a given price
     */
    public function getPercentileRank(float $price): int
    {
        if ($price <= $this->percentile_10) return 10;
        if ($price <= $this->percentile_25) return 25;
        if ($price <= $this->median_price) return 50;
        if ($price <= $this->percentile_75) return 75;
        if ($price <= $this->percentile_90) return 90;
        return 100;
    }
}
