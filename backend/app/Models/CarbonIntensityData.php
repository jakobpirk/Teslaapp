<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CarbonIntensityData extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'carbon_intensity_data';

    protected $fillable = [
        'zone',
        'country_code',
        'timestamp',
        'co2_per_kwh',
        'co2_intensity',
        'renewable_percentage',
        'fossil_percentage',
        'wind_percentage',
        'solar_percentage',
        'hydro_percentage',
        'nuclear_percentage',
        'coal_percentage',
        'gas_percentage',
        'is_forecast',
        'forecast_confidence',
        'fetched_at',
        'data_source',
        'raw_data',
    ];

    protected $casts = [
        'timestamp' => 'datetime',
        'co2_per_kwh' => 'float',
        'co2_intensity' => 'float',
        'renewable_percentage' => 'float',
        'fossil_percentage' => 'float',
        'wind_percentage' => 'float',
        'solar_percentage' => 'float',
        'hydro_percentage' => 'float',
        'nuclear_percentage' => 'float',
        'coal_percentage' => 'float',
        'gas_percentage' => 'float',
        'is_forecast' => 'boolean',
        'forecast_confidence' => 'float',
        'fetched_at' => 'datetime',
        'raw_data' => 'array',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get carbon intensity for a specific zone and time
     */
    public static function getIntensity(string $zone, \DateTime $timestamp, bool $preferForecast = false)
    {
        $query = static::where('zone', $zone)
            ->where('timestamp', $timestamp);

        if ($preferForecast) {
            $query->where('is_forecast', true);
        }

        return $query->orderBy('is_forecast', 'desc')
            ->orderBy('fetched_at', 'desc')
            ->first();
    }

    /**
     * Get carbon intensity range for a zone
     */
    public static function getIntensityRange(string $zone, \DateTime $start, \DateTime $end, bool $includeForecasts = true)
    {
        $query = static::where('zone', $zone)
            ->whereBetween('timestamp', [$start, $end]);

        if (!$includeForecasts) {
            $query->where('is_forecast', false);
        }

        return $query->orderBy('timestamp')->get();
    }

    /**
     * Check if data is fresh
     */
    public function isFresh(int $maxAgeMinutes = 30): bool
    {
        return $this->fetched_at->diffInMinutes(now()) < $maxAgeMinutes;
    }

    /**
     * Calculate carbon score (0-100, higher = cleaner)
     */
    public function getCarbonScore(float $minCO2 = 50, float $maxCO2 = 400): float
    {
        // Invert scale: lower emissions = higher score
        $normalized = ($maxCO2 - $this->co2_per_kwh) / ($maxCO2 - $minCO2);
        return max(0, min(100, $normalized * 100));
    }

    /**
     * Check if grid is running on high renewables
     */
    public function isClean(float $threshold = 70): bool
    {
        return $this->renewable_percentage >= $threshold;
    }

    /**
     * Get renewable score
     */
    public function getRenewableScore(): float
    {
        return $this->renewable_percentage ?? 0;
    }
}
