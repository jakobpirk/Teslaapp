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
        'price_per_kwh',
        'currency',
        'location',
        'utility_provider',
        'rate_type',
        'metadata',
    ];

    protected $casts = [
        'timestamp' => 'datetime',
        'price_per_kwh' => 'float',
        'metadata' => 'array',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get pricing data for a specific time range
     */
    public static function getForTimeRange($startTime, $endTime, $location = null)
    {
        $query = static::whereBetween('timestamp', [$startTime, $endTime])
            ->orderBy('timestamp');

        if ($location) {
            $query->where('location', $location);
        }

        return $query->get();
    }

    /**
     * Get the average price for a time period
     */
    public static function getAveragePrice($startTime, $endTime, $location = null)
    {
        $query = static::whereBetween('timestamp', [$startTime, $endTime]);

        if ($location) {
            $query->where('location', $location);
        }

        return $query->avg('price_per_kwh');
    }
}
