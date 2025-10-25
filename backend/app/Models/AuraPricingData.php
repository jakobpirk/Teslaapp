<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class AuraPricingData extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'aura_pricing_data';

    protected $fillable = [
        'date',
        'statistics',
        'chart_series',
        'min_y_axis_value',
    ];

    protected $casts = [
        'date' => 'date',
        'statistics' => 'array',
        'chart_series' => 'array',
        'min_y_axis_value' => 'float',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get hourly prices for a specific region and date.
     *
     * @param string $region 'east' or 'west'
     * @return array Array of hourly prices [hour => total_price]
     */
    public function getHourlyPricesForRegion(string $region): array
    {
        $prices = [];
        $chartSeries = $this->chart_series;

        if (empty($chartSeries)) {
            return $prices;
        }

        // Sum up all price components for each hour
        foreach ($chartSeries as $series) {
            $timePoints = $series['timePoints'] ?? [];

            foreach ($timePoints as $timePoint) {
                $hour = (int) $timePoint['name'];
                $price = $timePoint[$region] ?? 0;

                if (!isset($prices[$hour])) {
                    $prices[$hour] = 0;
                }

                $prices[$hour] += $price;
            }
        }

        // Sort by hour
        ksort($prices);

        return $prices;
    }

    /**
     * Get price for a specific hour and region.
     *
     * @param int $hour 0-23
     * @param string $region 'east' or 'west'
     * @return float|null
     */
    public function getPriceForHour(int $hour, string $region): ?float
    {
        $prices = $this->getHourlyPricesForRegion($region);
        return $prices[$hour] ?? null;
    }

    /**
     * Get statistics for a specific region.
     *
     * @param string $region 'east' or 'west'
     * @return array|null
     */
    public function getStatisticsForRegion(string $region): ?array
    {
        return $this->statistics[$region] ?? null;
    }

    /**
     * Get pricing data for a specific date.
     *
     * @param Carbon|string $date
     * @return self|null
     */
    public static function getForDate($date): ?self
    {
        if ($date instanceof Carbon) {
            $date = $date->toDateString();
        }

        return static::where('date', $date)->first();
    }

    /**
     * Check if pricing data exists for a specific date.
     *
     * @param Carbon|string $date
     * @return bool
     */
    public static function existsForDate($date): bool
    {
        if ($date instanceof Carbon) {
            $date = $date->toDateString();
        }

        return static::where('date', $date)->exists();
    }
}
