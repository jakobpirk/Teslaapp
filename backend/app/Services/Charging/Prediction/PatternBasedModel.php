<?php

namespace App\Services\Charging\Prediction;

use App\Models\HistoricPriceStatistic;
use App\Models\PricingHistory;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class PatternBasedModel implements PredictionModelInterface
{
    private int $similarDaysCount = 4; // Look at last 4 similar days
    private float $recencyWeight = 0.7; // Weight recent data more heavily

    public function getName(): string
    {
        return 'pattern_based';
    }

    public function predict(Carbon $timestamp, string $region): array
    {
        // Get historic statistics for this hour/day pattern
        $stat = HistoricPriceStatistic::getTypicalPrice(
            $region,
            $timestamp->hour,
            $timestamp->dayOfWeek
        );

        if (!$stat) {
            // Fall back to hourly pattern without day-of-week
            $stat = HistoricPriceStatistic::getHourlyPattern($region, $timestamp->hour);
        }

        if (!$stat) {
            return $this->getDefaultPrediction();
        }

        // Find similar recent days
        $similarPrices = $this->findSimilarDayPrices($timestamp, $region);

        if ($similarPrices->isEmpty()) {
            // Use historic statistics only
            return [
                'price' => round($stat->avg_price, 4),
                'confidence_low' => round($stat->percentile_25, 4),
                'confidence_high' => round($stat->percentile_75, 4),
                'confidence_score' => $this->calculateConfidence($stat),
                'metadata' => [
                    'model' => $this->getName(),
                    'source' => 'historic_statistics',
                    'sample_count' => $stat->sample_count,
                ],
            ];
        }

        // Calculate weighted average with recency bias
        $prediction = $this->calculateWeightedPrediction($similarPrices, $stat);

        // Adjust prediction for overall trend
        $trendAdjustment = $this->calculateTrendAdjustment($region);
        $adjustedPrice = $prediction['price'] * (1 + $trendAdjustment);

        return [
            'price' => round($adjustedPrice, 4),
            'confidence_low' => round($prediction['confidence_low'] * (1 + $trendAdjustment), 4),
            'confidence_high' => round($prediction['confidence_high'] * (1 + $trendAdjustment), 4),
            'confidence_score' => $prediction['confidence_score'],
            'metadata' => [
                'model' => $this->getName(),
                'similar_days_found' => $similarPrices->count(),
                'trend_adjustment' => round($trendAdjustment * 100, 2) . '%',
                'base_prediction' => $prediction['price'],
            ],
        ];
    }

    public function predictRange(Carbon $start, Carbon $end, string $region): array
    {
        $predictions = [];
        $current = $start->copy();

        while ($current <= $end) {
            $prediction = $this->predict($current, $region);
            $prediction['timestamp'] = $current->copy();
            $predictions[] = $prediction;

            $current->addHour();
        }

        return $predictions;
    }

    public function train(string $region, int $lookbackDays = 180): bool
    {
        // This model doesn't require explicit training
        // It uses historic statistics which are built separately
        return $this->isReady($region);
    }

    public function getMetadata(): array
    {
        return [
            'name' => $this->getName(),
            'type' => 'pattern_matching',
            'description' => 'Finds similar historic periods and weights by recency',
            'parameters' => [
                'similar_days_count' => $this->similarDaysCount,
                'recency_weight' => $this->recencyWeight,
            ],
        ];
    }

    public function isReady(string $region): bool
    {
        // Check if we have historic statistics
        return HistoricPriceStatistic::where('region', $region)->exists();
    }

    /**
     * Find prices from similar days in the past
     */
    private function findSimilarDayPrices(Carbon $timestamp, string $region): \Illuminate\Support\Collection
    {
        $targetHour = $timestamp->hour;
        $targetDayOfWeek = $timestamp->dayOfWeek;

        // Find last N occurrences of same day-of-week and hour
        $prices = PricingHistory::where('region', $region)
            ->where('hour', $targetHour)
            ->whereRaw('DAYOFWEEK(date) = ?', [$targetDayOfWeek + 1]) // MySQL DAYOFWEEK is 1-7
            ->where('timestamp', '<', now())
            ->orderBy('timestamp', 'desc')
            ->limit($this->similarDaysCount)
            ->get();

        return $prices;
    }

    /**
     * Calculate weighted prediction with recency bias
     */
    private function calculateWeightedPrediction($similarPrices, $stat): array
    {
        $totalWeight = 0;
        $weightedSum = 0;
        $prices = [];

        // Weight recent prices more heavily
        foreach ($similarPrices as $index => $priceRecord) {
            $weight = pow($this->recencyWeight, $index); // Exponential decay
            $weightedSum += $priceRecord->price_per_kwh * $weight;
            $totalWeight += $weight;
            $prices[] = $priceRecord->price_per_kwh;
        }

        $prediction = $totalWeight > 0 ? $weightedSum / $totalWeight : $stat->avg_price;

        // Calculate confidence interval based on variance
        $variance = $this->calculateVariance($prices);
        $stdDev = sqrt($variance);

        $confidenceLow = $prediction - (1.96 * $stdDev);
        $confidenceHigh = $prediction + (1.96 * $stdDev);

        // Confidence score based on sample size and consistency
        $confidenceScore = min(95, 60 + ($similarPrices->count() * 5) - ($stdDev * 50));

        return [
            'price' => $prediction,
            'confidence_low' => max(0.01, $confidenceLow),
            'confidence_high' => $confidenceHigh,
            'confidence_score' => max(40, $confidenceScore),
        ];
    }

    /**
     * Calculate price trend adjustment
     */
    private function calculateTrendAdjustment(string $region): float
    {
        // Compare last 7 days average to previous 7 days
        $recent = PricingHistory::where('region', $region)
            ->where('timestamp', '>=', now()->subDays(7))
            ->avg('price_per_kwh');

        $previous = PricingHistory::where('region', $region)
            ->whereBetween('timestamp', [now()->subDays(14), now()->subDays(7)])
            ->avg('price_per_kwh');

        if (!$recent || !$previous || $previous == 0) {
            return 0;
        }

        // Calculate percentage change (cap at ±10%)
        $change = ($recent - $previous) / $previous;
        return max(-0.1, min(0.1, $change));
    }

    /**
     * Calculate variance of price array
     */
    private function calculateVariance(array $prices): float
    {
        if (count($prices) < 2) {
            return 0.01; // Default small variance
        }

        $mean = array_sum($prices) / count($prices);
        $squaredDiffs = array_map(function ($price) use ($mean) {
            return pow($price - $mean, 2);
        }, $prices);

        return array_sum($squaredDiffs) / count($prices);
    }

    /**
     * Calculate confidence score from statistics
     */
    private function calculateConfidence(HistoricPriceStatistic $stat): float
    {
        // Base confidence on sample count and variance
        $sampleConfidence = min(95, ($stat->sample_count / 90) * 100);

        // Reduce confidence if high variance
        $varianceConfidence = max(40, 100 - ($stat->std_deviation * 100));

        return ($sampleConfidence + $varianceConfidence) / 2;
    }

    /**
     * Default prediction when insufficient data
     */
    private function getDefaultPrediction(): array
    {
        return [
            'price' => 0.25,
            'confidence_low' => 0.15,
            'confidence_high' => 0.35,
            'confidence_score' => 30,
            'metadata' => [
                'model' => $this->getName(),
                'status' => 'insufficient_data',
            ],
        ];
    }
}
