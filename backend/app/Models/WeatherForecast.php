<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WeatherForecast extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'weather_forecasts';

    protected $fillable = [
        'latitude',
        'longitude',
        'location_name',
        'forecast_timestamp',
        'temp_c',
        'temp_f',
        'wind_kph',
        'wind_mph',
        'wind_degree',
        'wind_dir',
        'pressure_mb',
        'humidity',
        'cloud',
        'precip_mm',
        'chance_of_rain',
        'chance_of_snow',
        'uv_index',
        'vis_km',
        'condition_text',
        'condition_code',
        'is_day',
        'fetched_at',
        'data_source',
        'raw_data',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'forecast_timestamp' => 'datetime',
        'temp_c' => 'float',
        'temp_f' => 'float',
        'wind_kph' => 'float',
        'wind_mph' => 'float',
        'wind_degree' => 'integer',
        'pressure_mb' => 'integer',
        'humidity' => 'integer',
        'cloud' => 'integer',
        'precip_mm' => 'float',
        'chance_of_rain' => 'integer',
        'chance_of_snow' => 'integer',
        'uv_index' => 'float',
        'vis_km' => 'integer',
        'is_day' => 'boolean',
        'fetched_at' => 'datetime',
        'raw_data' => 'array',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get forecast for a specific location and time
     */
    public static function getForecast(float $lat, float $lon, \DateTime $timestamp)
    {
        return static::where('latitude', $lat)
            ->where('longitude', $lon)
            ->where('forecast_timestamp', $timestamp)
            ->orderBy('fetched_at', 'desc')
            ->first();
    }

    /**
     * Get forecast range for a location
     */
    public static function getForecastRange(float $lat, float $lon, \DateTime $start, \DateTime $end)
    {
        return static::where('latitude', $lat)
            ->where('longitude', $lon)
            ->whereBetween('forecast_timestamp', [$start, $end])
            ->orderBy('forecast_timestamp')
            ->get();
    }

    /**
     * Check if forecast is still fresh
     */
    public function isFresh(int $maxAgeHours = 1): bool
    {
        return $this->fetched_at->diffInHours(now()) < $maxAgeHours;
    }

    /**
     * Get wind score for renewable energy potential
     */
    public function getWindScore(): float
    {
        // Wind speed 15-35 kph is optimal for turbines
        // Scale to 0-100
        $optimal = 25;
        $deviation = abs($this->wind_kph - $optimal);
        return max(0, min(100, 100 - ($deviation * 2)));
    }

    /**
     * Get temperature impact score
     */
    public function getTemperatureScore(): float
    {
        // Optimal temperature 15-20°C (low HVAC demand)
        $optimal = 17.5;
        $deviation = abs($this->temp_c - $optimal);
        return max(0, min(100, 100 - ($deviation * 3)));
    }

    /**
     * Get solar potential score
     */
    public function getSolarScore(): float
    {
        if (!$this->is_day) {
            return 0;
        }

        // Less cloud = better solar
        return 100 - $this->cloud;
    }
}
