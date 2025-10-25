<?php

namespace App\Services\Charging\Factors;

use App\Models\PricingHistory;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class PriceFactorService implements ChargingFactorInterface
{
    private float $weight = 0.40; // 40% base weight
    private float $minPrice = 0.05;
    private float $maxPrice = 0.50;

    public function getName(): string
    {
        return 'price';
    }

    public function getDisplayName(): string
    {
        return 'Electricity Price';
    }

    public function getData(Carbon $start, Carbon $end, string $region): Collection
    {
        return PricingHistory::whereBetween('timestamp', [$start, $end])
            ->where('region', $region)
            ->orderBy('timestamp')
            ->get()
            ->map(function ($record) {
                return [
                    'timestamp' => $record->timestamp,
                    'value' => $record->price_per_kwh,
                    'currency' => $record->currency,
                ];
            });
    }

    public function scoreWindow(Carbon $windowStart, Carbon $windowEnd, string $region): float
    {
        $prices = $this->getData($windowStart, $windowEnd, $region);

        if ($prices->isEmpty()) {
            return 50; // Neutral score if no data
        }

        $avgPrice = $prices->avg('value');

        // Normalize to 0-100 scale (inverted: lower price = higher score)
        $normalized = ($this->maxPrice - $avgPrice) / ($this->maxPrice - $this->minPrice);
        $score = $normalized * 100;

        return max(0, min(100, $score));
    }

    public function getWeight(): float
    {
        return $this->weight;
    }

    public function getConfidence(Carbon $timestamp, string $region): float
    {
        // Check if we have actual price data for this timestamp
        $hasData = PricingHistory::where('timestamp', $timestamp)
            ->where('region', $region)
            ->exists();

        return $hasData ? 1.0 : 0.0;
    }

    public function getMetadata(): array
    {
        return [
            'unit' => '$/kWh',
            'data_type' => 'numeric',
            'source' => 'Aura Pricing API',
            'update_frequency' => 'daily',
            'min_value' => $this->minPrice,
            'max_value' => $this->maxPrice,
        ];
    }

    public function isEnabled(): bool
    {
        return true; // Always enabled
    }

    public function getScoreExplanation(Carbon $windowStart, Carbon $windowEnd, string $region): string
    {
        $prices = $this->getData($windowStart, $windowEnd, $region);

        if ($prices->isEmpty()) {
            return 'No price data available for this window';
        }

        $avgPrice = $prices->avg('value');
        $minPrice = $prices->min('value');
        $maxPrice = $prices->max('value');

        return sprintf(
            'Average price: $%.3f/kWh (range: $%.3f - $%.3f)',
            $avgPrice,
            $minPrice,
            $maxPrice
        );
    }

    /**
     * Set custom weight
     */
    public function setWeight(float $weight): void
    {
        $this->weight = max(0, min(1, $weight));
    }
}
