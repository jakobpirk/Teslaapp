<?php

namespace App\Services;

use App\Models\ElectricityProvider;
use App\Models\PricingHistory;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ElectricityProviderService
{
    /**
     * Fetch current pricing from provider's API.
     * This simulates a network call to the provider's API.
     */
    public function fetchCurrentPricing(ElectricityProvider $provider, ?string $location = null): array
    {
        try {
            // Simulate network call delay
            usleep(100000); // 100ms delay

            $now = Carbon::now();
            $hour = $now->hour;

            // Determine rate type based on time and pricing structure
            $rateType = $this->determineRateType($provider, $hour);
            $pricePerKwh = $this->calculatePrice($provider, $rateType, $now);

            return [
                'timestamp' => $now,
                'price_per_kwh' => $pricePerKwh,
                'currency' => 'USD', // Default currency, can be enhanced later
                'location' => $location,
                'utility_provider' => $provider->display_name,
                'rate_type' => $rateType,
                'metadata' => [
                    'provider_id' => $provider->id,
                    'source' => 'api',
                    'fetched_at' => $now->toIso8601String(),
                ],
            ];
        } catch (\Exception $e) {
            Log::error('Failed to fetch pricing from provider', [
                'provider' => $provider->name,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Fetch pricing forecast for the next N hours.
     */
    public function fetchPricingForecast(
        ElectricityProvider $provider,
        int $hours = 48,
        ?string $location = null
    ): array {
        try {
            // Simulate network call delay
            usleep(200000); // 200ms delay

            $forecast = [];
            $startTime = Carbon::now()->startOfHour();

            for ($i = 0; $i < $hours; $i++) {
                $timestamp = $startTime->copy()->addHours($i);
                $hour = $timestamp->hour;

                $rateType = $this->determineRateType($provider, $hour);
                $pricePerKwh = $this->calculatePrice($provider, $rateType, $timestamp);

                $forecast[] = [
                    'timestamp' => $timestamp,
                    'price_per_kwh' => $pricePerKwh,
                    'currency' => 'USD', // Default currency, can be enhanced later
                    'location' => $location,
                    'utility_provider' => $provider->display_name,
                    'rate_type' => $rateType,
                    'metadata' => [
                        'provider_id' => $provider->id,
                        'source' => 'forecast',
                        'hour_offset' => $i,
                    ],
                ];
            }

            return $forecast;
        } catch (\Exception $e) {
            Log::error('Failed to fetch pricing forecast', [
                'provider' => $provider->name,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Store pricing data in the database.
     */
    public function storePricingData(array $pricingData): PricingHistory
    {
        return PricingHistory::create([
            'timestamp' => $pricingData['timestamp'],
            'price_per_kwh' => $pricingData['price_per_kwh'],
            'currency' => $pricingData['currency'],
            'location' => $pricingData['location'],
            'utility_provider' => $pricingData['utility_provider'],
            'rate_type' => $pricingData['rate_type'],
            'metadata' => $pricingData['metadata'],
        ]);
    }

    /**
     * Fetch and store current pricing.
     */
    public function updateCurrentPricing(ElectricityProvider $provider, ?string $location = null): PricingHistory
    {
        $pricingData = $this->fetchCurrentPricing($provider, $location);
        return $this->storePricingData($pricingData);
    }

    /**
     * Fetch and store pricing forecast.
     */
    public function updatePricingForecast(
        ElectricityProvider $provider,
        int $hours = 48,
        ?string $location = null
    ): array {
        $forecast = $this->fetchPricingForecast($provider, $hours, $location);
        $stored = [];

        foreach ($forecast as $pricingData) {
            // Check if pricing for this timestamp already exists
            $existing = PricingHistory::where('timestamp', $pricingData['timestamp'])
                ->where('location', $pricingData['location'])
                ->first();

            if (!$existing) {
                $stored[] = $this->storePricingData($pricingData);
            }
        }

        return $stored;
    }

    /**
     * Determine rate type based on hour and provider's pricing structure.
     */
    protected function determineRateType(ElectricityProvider $provider, int $hour): string
    {
        $structure = $provider->pricing_structure;
        $timeWindows = $structure['time_windows'] ?? [];

        foreach ($timeWindows as $rateType => $windows) {
            foreach ($windows as $window) {
                if ($this->isHourInWindow($hour, $window)) {
                    return $rateType;
                }
            }
        }

        // Default to first rate type if no match found
        return array_key_first($structure['rate_types'] ?? ['standard']);
    }

    /**
     * Check if an hour falls within a time window.
     */
    protected function isHourInWindow(int $hour, string $window): bool
    {
        [$start, $end] = explode('-', $window);
        [$startHour] = explode(':', $start);
        [$endHour] = explode(':', $end);

        $startHour = (int) $startHour;
        $endHour = (int) $endHour;

        // Handle windows that cross midnight
        if ($endHour <= $startHour) {
            return $hour >= $startHour || $hour < $endHour;
        }

        return $hour >= $startHour && $hour < $endHour;
    }

    /**
     * Calculate price with some variation to simulate real-world fluctuations.
     */
    protected function calculatePrice(ElectricityProvider $provider, string $rateType, Carbon $timestamp): float
    {
        $structure = $provider->pricing_structure;
        $baseRate = $structure['base_rates'][$rateType] ?? 0.20;

        // Add small random variation (±5%)
        $variation = (rand(-500, 500) / 10000);
        $price = $baseRate * (1 + $variation);

        // Add seasonal adjustment (summer = +10%, winter = +15%)
        $month = $timestamp->month;
        if (in_array($month, [6, 7, 8])) {
            $price *= 1.10; // Summer peak
        } elseif (in_array($month, [12, 1, 2])) {
            $price *= 1.15; // Winter peak
        }

        // Round to 4 decimal places
        return round($price, 4);
    }

    /**
     * Get all active providers.
     */
    public function getActiveProviders(): \Illuminate\Database\Eloquent\Collection
    {
        return ElectricityProvider::active()->get();
    }
}
