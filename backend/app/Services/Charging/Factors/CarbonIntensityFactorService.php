<?php

namespace App\Services\Charging\Factors;

use App\Models\CarbonIntensityData;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class CarbonIntensityFactorService implements ChargingFactorInterface
{
    private float $weight = 0.20; // 20% base weight
    private string $zone = 'DK1'; // Danish grid zone (DK1 = West, DK2 = East)
    private float $minCO2 = 50;   // gCO2/kWh (very clean)
    private float $maxCO2 = 400;  // gCO2/kWh (very dirty)

    public function getName(): string
    {
        return 'carbon_intensity';
    }

    public function getDisplayName(): string
    {
        return 'Carbon Intensity';
    }

    public function getData(Carbon $start, Carbon $end, string $region): Collection
    {
        // Map pricing region to grid zone
        $zone = $this->mapRegionToZone($region);

        // Try to get from database first
        $data = CarbonIntensityData::getIntensityRange($zone, $start, $end, true);

        // If we have fresh data, return it
        if ($data->isNotEmpty() && $data->first()->isFresh(30)) {
            return $data->map(function ($record) {
                return [
                    'timestamp' => $record->timestamp,
                    'co2_per_kwh' => $record->co2_per_kwh,
                    'renewable_percentage' => $record->renewable_percentage,
                    'is_forecast' => $record->is_forecast,
                ];
            });
        }

        // Otherwise, fetch fresh data
        $this->fetchAndStoreData($zone, $start, $end);

        // Retrieve again
        return CarbonIntensityData::getIntensityRange($zone, $start, $end, true)
            ->map(function ($record) {
                return [
                    'timestamp' => $record->timestamp,
                    'co2_per_kwh' => $record->co2_per_kwh,
                    'renewable_percentage' => $record->renewable_percentage,
                    'is_forecast' => $record->is_forecast,
                ];
            });
    }

    public function scoreWindow(Carbon $windowStart, Carbon $windowEnd, string $region): float
    {
        $data = $this->getData($windowStart, $windowEnd, $region);

        if ($data->isEmpty()) {
            return 50; // Neutral score
        }

        $avgCO2 = $data->avg('co2_per_kwh');

        // Score based on carbon intensity (inverted: lower CO2 = higher score)
        $normalized = ($this->maxCO2 - $avgCO2) / ($this->maxCO2 - $this->minCO2);
        $score = $normalized * 100;

        return max(0, min(100, $score));
    }

    public function getWeight(): float
    {
        return $this->weight;
    }

    public function getConfidence(Carbon $timestamp, string $region): float
    {
        $zone = $this->mapRegionToZone($region);
        $data = CarbonIntensityData::getIntensity($zone, $timestamp, false);

        if (!$data) {
            // No data at all
            return 0.0;
        }

        if ($data->is_forecast && $data->forecast_confidence !== null) {
            // Use forecast confidence from API
            return $data->forecast_confidence / 100;
        }

        if (!$data->is_forecast) {
            // Actual data, high confidence
            return 1.0;
        }

        // Default moderate confidence for forecasts
        return 0.75;
    }

    public function getMetadata(): array
    {
        return [
            'unit' => 'gCO2/kWh',
            'data_type' => 'numeric',
            'source' => 'Energinet (Danish TSO)',
            'update_frequency' => '30 minutes',
            'zone' => $this->zone,
        ];
    }

    public function isEnabled(): bool
    {
        // Always enabled for Denmark
        return true;
    }

    public function getScoreExplanation(Carbon $windowStart, Carbon $windowEnd, string $region): float|string
    {
        $data = $this->getData($windowStart, $windowEnd, $region);

        if ($data->isEmpty()) {
            return 'No carbon intensity data available';
        }

        $avgCO2 = $data->avg('co2_per_kwh');
        $avgRenewable = $data->avg('renewable_percentage');

        return sprintf(
            'Grid emissions: %.0f gCO2/kWh, %.0f%% renewable energy',
            $avgCO2,
            $avgRenewable ?? 0
        );
    }

    /**
     * Fetch carbon intensity data from Energinet API
     */
    private function fetchAndStoreData(string $zone, Carbon $start, Carbon $end): void
    {
        try {
            // Energinet API endpoint for CO2 emissions
            $response = Http::timeout(15)->get('https://api.energidataservice.dk/dataset/CO2EmisProg', [
                'start' => $start->format('Y-m-d\TH:i'),
                'end' => $end->format('Y-m-d\TH:i'),
                'filter' => json_encode(['PriceArea' => $zone]),
            ]);

            if (!$response->successful()) {
                Log::error('Energinet API request failed', ['status' => $response->status()]);
                return;
            }

            $data = $response->json();

            if (!isset($data['records']) || empty($data['records'])) {
                Log::warning('No carbon intensity data returned from Energinet');
                return;
            }

            // Store the records
            foreach ($data['records'] as $record) {
                $timestamp = Carbon::parse($record['Minutes5UTC']);

                CarbonIntensityData::updateOrCreate(
                    [
                        'zone' => $zone,
                        'timestamp' => $timestamp,
                        'is_forecast' => true,
                    ],
                    [
                        'country_code' => 'DK',
                        'co2_per_kwh' => $record['CO2Emission'] ?? 0,
                        'co2_intensity' => $record['CO2Emission'] ?? 0,
                        'fetched_at' => now(),
                        'data_source' => 'energinet',
                        'raw_data' => $record,
                    ]
                );
            }

            Log::info('Carbon intensity data updated successfully', [
                'zone' => $zone,
                'records' => count($data['records']),
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch carbon intensity data', [
                'error' => $e->getMessage(),
                'zone' => $zone,
            ]);
        }
    }

    /**
     * Map pricing region to grid zone
     */
    private function mapRegionToZone(string $region): string
    {
        return match (strtolower($region)) {
            'west' => 'DK1',
            'east' => 'DK2',
            default => $this->zone,
        };
    }

    /**
     * Set custom weight
     */
    public function setWeight(float $weight): void
    {
        $this->weight = max(0, min(1, $weight));
    }

    /**
     * Set custom zone
     */
    public function setZone(string $zone): void
    {
        $this->zone = $zone;
    }
}
