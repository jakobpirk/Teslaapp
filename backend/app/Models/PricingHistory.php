<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PricingHistory extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'pricing_history';

    protected $fillable = [
        'timestamp',
        'date',
        'hour',
        'price_per_kwh',
        'currency',
        'utility_provider',
        'region',
        'rate_type',
        'metadata',
    ];

    protected $casts = [
        'timestamp' => 'datetime',
        'date' => 'date',
        'hour' => 'integer',
        'price_per_kwh' => 'float',
        'metadata' => 'array',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get pricing data for a specific time range
     */
    public static function getForTimeRange($startTime, $endTime)
    {
        return static::whereBetween('timestamp', [$startTime, $endTime])
            ->orderBy('timestamp')
            ->get();
    }

    /**
     * Get the average price for a time period
     */
    public static function getAveragePrice($startTime, $endTime)
    {
        return static::whereBetween('timestamp', [$startTime, $endTime])
            ->avg('price_per_kwh');
    }

    /**
     * Get pricing data for a specific date and region.
     *
     * @param string $date Date in Y-m-d format
     * @param string|null $region Optional region (e.g., 'east' or 'west')
     * @param string|null $provider Optional provider name
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public static function getForDateAndRegion(string $date, ?string $region = null, ?string $provider = null)
    {
        $query = static::where('date', $date);

        if ($region) {
            $query->where('region', $region);
        }

        if ($provider) {
            $query->where('utility_provider', $provider);
        }

        return $query->orderBy('hour')->get();
    }

    /**
     * Get hourly prices for a specific date and region.
     *
     * @param string $date Date in Y-m-d format
     * @param string $region Region (e.g., 'east' or 'west')
     * @param string|null $provider Optional provider name
     * @return array Array of prices indexed by hour
     */
    public static function getHourlyPrices(string $date, string $region, ?string $provider = null): array
    {
        $records = static::getForDateAndRegion($date, $region, $provider);

        $prices = [];
        foreach ($records as $record) {
            if ($record->hour !== null) {
                $prices[$record->hour] = $record->price_per_kwh;
            }
        }

        return $prices;
    }
}
