<?php

namespace App\Services;

use App\Models\AuraPricingData;
use App\Models\PricingHistory;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AuraElectricityService
{
    private const BASE_URL = 'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net/umbraco/api/PowerPriceInfo/Get/data';
    private const TIMEOUT = 30; // seconds

    /**
     * Fetch pricing data from Aura API for a specific date.
     *
     * @param Carbon|string $date
     * @return array|null
     */
    public function fetchPricingData($date): ?array
    {
        try {
            if ($date instanceof Carbon) {
                $dateString = $date->format('Y/m/d');
            } else {
                $dateString = Carbon::parse($date)->format('Y/m/d');
            }

            $response = Http::timeout(self::TIMEOUT)
                ->get(self::BASE_URL, [
                    'date' => $dateString,
                ]);

            if (!$response->successful()) {
                Log::error('Failed to fetch Aura pricing data', [
                    'date' => $dateString,
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
                return null;
            }

            $data = $response->json();

            if (empty($data)) {
                Log::warning('Empty response from Aura API', [
                    'date' => $dateString,
                ]);
                return null;
            }

            // Validate response structure
            if (!isset($data['chartSeries']) || !is_array($data['chartSeries'])) {
                Log::error('Invalid Aura API response structure', [
                    'date' => $dateString,
                    'has_chart_series' => isset($data['chartSeries']),
                ]);
                return null;
            }

            return $data;
        } catch (\Exception $e) {
            Log::error('Exception while fetching Aura pricing data', [
                'date' => $dateString ?? 'unknown',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return null;
        }
    }

    /**
     * Store Aura pricing data in the database.
     *
     * @param Carbon|string $date
     * @param array $data Raw API response
     * @return AuraPricingData|null
     */
    public function storePricingData($date, array $data): ?AuraPricingData
    {
        try {
            if ($date instanceof Carbon) {
                $dateString = $date->toDateString();
            } else {
                $dateString = Carbon::parse($date)->toDateString();
            }

            // Store the full API response
            $auraPricingData = AuraPricingData::updateOrCreate(
                ['date' => $dateString],
                [
                    'statistics' => $data['statistics'] ?? [],
                    'chart_series' => $data['chartSeries'] ?? [],
                    'min_y_axis_value' => $data['minYaxisValue'] ?? 0,
                ]
            );

            // Also store individual hourly prices in pricing_history for easier querying
            $this->storeHourlyPrices($dateString, $data);

            return $auraPricingData;
        } catch (\Exception $e) {
            Log::error('Failed to store Aura pricing data', [
                'date' => $dateString ?? 'unknown',
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Store individual hourly prices in pricing_history table.
     *
     * @param string $dateString
     * @param array $data
     * @return void
     */
    protected function storeHourlyPrices(string $dateString, array $data): void
    {
        $chartSeries = $data['chartSeries'] ?? [];

        if (empty($chartSeries)) {
            Log::warning('No chart series data to store', ['date' => $dateString]);
            return;
        }

        // Calculate total price for each hour and region
        $hourlyPrices = [
            'east' => [],
            'west' => [],
        ];

        foreach ($chartSeries as $series) {
            $timePoints = $series['timePoints'] ?? [];

            foreach ($timePoints as $timePoint) {
                $hour = (int) $timePoint['name'];

                foreach (['east', 'west'] as $region) {
                    if (!isset($hourlyPrices[$region][$hour])) {
                        $hourlyPrices[$region][$hour] = 0;
                    }

                    $hourlyPrices[$region][$hour] += $timePoint[$region] ?? 0;
                }
            }
        }

        // Store each hourly price for both regions
        foreach (['east', 'west'] as $region) {
            foreach ($hourlyPrices[$region] as $hour => $price) {
                try {
                    $timestamp = Carbon::createFromFormat('Y-m-d H', "$dateString $hour");

                    PricingHistory::updateOrCreate(
                    [
                        'timestamp' => $timestamp,
                        'utility_provider' => 'Aura',
                        'region' => $region,
                    ],
                    [
                        'date' => $dateString,
                        'hour' => $hour,
                        'price_per_kwh' => round($price, 4),
                        'currency' => 'DKK', // Aura prices are in Danish Kroner
                        'rate_type' => $this->determineRateType($hour),
                        'metadata' => [
                            'source' => 'aura_api',
                            'fetched_at' => now()->toIso8601String(),
                        ],
                    ]
                );
                } catch (\Exception $e) {
                    Log::error('Failed to store hourly price', [
                        'date' => $dateString,
                        'hour' => $hour,
                        'region' => $region,
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        }
    }

    /**
     * Determine rate type based on hour.
     *
     * @param int $hour
     * @return string
     */
    protected function determineRateType(int $hour): string
    {
        // Peak hours: 17-20 (based on the data showing highest prices)
        if ($hour >= 17 && $hour <= 20) {
            return 'peak';
        }

        // Mid-peak: 6-17, 21-22
        if (($hour >= 6 && $hour < 17) || ($hour >= 21 && $hour <= 22)) {
            return 'mid-peak';
        }

        // Off-peak: 23-5
        return 'off-peak';
    }

    /**
     * Fetch and store pricing data for a specific date.
     *
     * @param Carbon|string $date
     * @return AuraPricingData|null
     */
    public function updatePricingForDate($date): ?AuraPricingData
    {
        $data = $this->fetchPricingData($date);

        if (!$data) {
            return null;
        }

        return $this->storePricingData($date, $data);
    }

    /**
     * Get pricing for a specific date and region.
     *
     * @param Carbon|string $date
     * @param string $region 'east' or 'west'
     * @return array|null Array of hourly prices
     */
    public function getPricingForDate($date, string $region): ?array
    {
        if ($date instanceof Carbon) {
            $dateString = $date->toDateString();
        } else {
            $dateString = Carbon::parse($date)->toDateString();
        }

        $auraPricing = AuraPricingData::getForDate($dateString);

        if (!$auraPricing) {
            return null;
        }

        return $auraPricing->getHourlyPricesForRegion($region);
    }

    /**
     * Check if tomorrow's prices are available (released after 17:00).
     *
     * @return bool
     */
    public function areTomorrowPricesAvailable(): bool
    {
        $tomorrow = Carbon::tomorrow();
        return AuraPricingData::existsForDate($tomorrow);
    }

    /**
     * Fetch tomorrow's prices if available.
     *
     * @return AuraPricingData|null
     */
    public function fetchTomorrowPrices(): ?AuraPricingData
    {
        $tomorrow = Carbon::tomorrow();
        return $this->updatePricingForDate($tomorrow);
    }
}
