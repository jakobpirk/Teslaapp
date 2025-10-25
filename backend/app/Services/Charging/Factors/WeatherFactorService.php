<?php

namespace App\Services\Charging\Factors;

use App\Models\WeatherForecast;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class WeatherFactorService implements ChargingFactorInterface
{
    private float $weight = 0.20; // 20% base weight
    private float $latitude = 55.6761; // Copenhagen, Denmark
    private float $longitude = 12.5683;

    public function getName(): string
    {
        return 'weather';
    }

    public function getDisplayName(): string
    {
        return 'Weather Conditions';
    }

    public function getData(Carbon $start, Carbon $end, string $region): Collection
    {
        // Try to get from database first
        $forecasts = WeatherForecast::getForecastRange(
            $this->latitude,
            $this->longitude,
            $start,
            $end
        );

        // If we have fresh data, return it
        if ($forecasts->isNotEmpty() && $forecasts->first()->isFresh(1)) {
            return $forecasts->map(function ($forecast) {
                return [
                    'timestamp' => $forecast->forecast_timestamp,
                    'temp_c' => $forecast->temp_c,
                    'wind_kph' => $forecast->wind_kph,
                    'cloud' => $forecast->cloud,
                    'is_day' => $forecast->is_day,
                ];
            });
        }

        // Otherwise, fetch fresh data
        $this->fetchAndStoreForecast($start, $end);

        // Retrieve again
        return WeatherForecast::getForecastRange($this->latitude, $this->longitude, $start, $end)
            ->map(function ($forecast) {
                return [
                    'timestamp' => $forecast->forecast_timestamp,
                    'temp_c' => $forecast->temp_c,
                    'wind_kph' => $forecast->wind_kph,
                    'cloud' => $forecast->cloud,
                    'is_day' => $forecast->is_day,
                ];
            });
    }

    public function scoreWindow(Carbon $windowStart, Carbon $windowEnd, string $region): float
    {
        $forecasts = $this->getData($windowStart, $windowEnd, $region);

        if ($forecasts->isEmpty()) {
            return 50; // Neutral score
        }

        $scores = $forecasts->map(function ($forecast) {
            // Wind score (higher wind = more renewable generation)
            $windScore = min(100, $forecast['wind_kph'] * 2.5);

            // Temperature score (15-20°C optimal, low HVAC demand)
            $tempDeviation = abs($forecast['temp_c'] - 17.5);
            $tempScore = max(0, 100 - ($tempDeviation * 3));

            // Solar score (less cloud = more solar, only during day)
            $solarScore = $forecast['is_day'] ? (100 - $forecast['cloud']) : 0;

            // Weighted composite: wind 50%, temp 30%, solar 20%
            return ($windScore * 0.5) + ($tempScore * 0.3) + ($solarScore * 0.2);
        });

        return $scores->avg();
    }

    public function getWeight(): float
    {
        return $this->weight;
    }

    public function getConfidence(Carbon $timestamp, string $region): float
    {
        $forecast = WeatherForecast::getForecast($this->latitude, $this->longitude, $timestamp);

        if (!$forecast) {
            return 0.0;
        }

        // Confidence degrades with forecast distance
        $hoursAhead = now()->diffInHours($timestamp, false);

        if ($hoursAhead < 0) {
            return 1.0; // Historical data, fully confident
        }

        if ($hoursAhead <= 24) {
            return 0.9; // Next 24h: high confidence
        }

        if ($hoursAhead <= 48) {
            return 0.75; // 24-48h: good confidence
        }

        return 0.6; // 48-72h: moderate confidence
    }

    public function getMetadata(): array
    {
        return [
            'data_type' => 'environmental',
            'source' => 'WeatherAPI.com',
            'update_frequency' => '60 minutes',
            'location' => 'Copenhagen, Denmark',
        ];
    }

    public function isEnabled(): bool
    {
        return config('services.weatherapi.key') !== null;
    }

    public function getScoreExplanation(Carbon $windowStart, Carbon $windowEnd, string $region): string
    {
        $forecasts = $this->getData($windowStart, $windowEnd, $region);

        if ($forecasts->isEmpty()) {
            return 'No weather forecast available';
        }

        $avgWind = $forecasts->avg('wind_kph');
        $avgTemp = $forecasts->avg('temp_c');
        $avgCloud = $forecasts->avg('cloud');

        return sprintf(
            'Wind: %.1f km/h (good for renewables), Temp: %.1f°C, Cloud cover: %d%%',
            $avgWind,
            $avgTemp,
            (int)$avgCloud
        );
    }

    /**
     * Fetch weather forecast from API and store in database
     */
    private function fetchAndStoreForecast(Carbon $start, Carbon $end): void
    {
        $apiKey = config('services.weatherapi.key');

        if (!$apiKey) {
            Log::warning('WeatherAPI key not configured');
            return;
        }

        try {
            // Calculate days needed
            $daysNeeded = max(1, min(3, $start->diffInDays($end) + 1));

            $response = Http::timeout(10)->get('https://api.weatherapi.com/v1/forecast.json', [
                'key' => $apiKey,
                'q' => "{$this->latitude},{$this->longitude}",
                'days' => $daysNeeded,
                'aqi' => 'no',
            ]);

            if (!$response->successful()) {
                Log::error('WeatherAPI request failed', ['status' => $response->status()]);
                return;
            }

            $data = $response->json();

            // Store forecast data
            foreach ($data['forecast']['forecastday'] as $day) {
                foreach ($day['hour'] as $hour) {
                    $forecastTime = Carbon::parse($hour['time']);

                    // Only store if within our range
                    if ($forecastTime->between($start, $end)) {
                        WeatherForecast::updateOrCreate(
                            [
                                'latitude' => $this->latitude,
                                'longitude' => $this->longitude,
                                'forecast_timestamp' => $forecastTime,
                            ],
                            [
                                'location_name' => $data['location']['name'],
                                'temp_c' => $hour['temp_c'],
                                'temp_f' => $hour['temp_f'],
                                'wind_kph' => $hour['wind_kph'],
                                'wind_mph' => $hour['wind_mph'],
                                'wind_degree' => $hour['wind_degree'],
                                'wind_dir' => $hour['wind_dir'],
                                'pressure_mb' => $hour['pressure_mb'],
                                'humidity' => $hour['humidity'],
                                'cloud' => $hour['cloud'],
                                'precip_mm' => $hour['precip_mm'],
                                'chance_of_rain' => $hour['chance_of_rain'] ?? 0,
                                'chance_of_snow' => $hour['chance_of_snow'] ?? 0,
                                'uv_index' => $hour['uv'] ?? null,
                                'vis_km' => $hour['vis_km'] ?? null,
                                'condition_text' => $hour['condition']['text'],
                                'condition_code' => $hour['condition']['code'],
                                'is_day' => $hour['is_day'] == 1,
                                'fetched_at' => now(),
                                'data_source' => 'weatherapi',
                                'raw_data' => $hour,
                            ]
                        );
                    }
                }
            }

            Log::info('Weather forecast updated successfully');
        } catch (\Exception $e) {
            Log::error('Failed to fetch weather forecast', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Set custom weight
     */
    public function setWeight(float $weight): void
    {
        $this->weight = max(0, min(1, $weight));
    }

    /**
     * Set custom location
     */
    public function setLocation(float $latitude, float $longitude): void
    {
        $this->latitude = $latitude;
        $this->longitude = $longitude;
    }
}
