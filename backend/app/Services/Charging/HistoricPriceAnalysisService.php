<?php

namespace App\Services\Charging;

use App\Models\HistoricPriceStatistic;
use App\Models\PricingHistory;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class HistoricPriceAnalysisService
{
    private int $defaultLookbackDays = 180; // 6 months

    /**
     * Build statistical models from historic data
     */
    public function buildStatisticalModels(string $region, ?int $lookbackDays = null): array
    {
        $lookbackDays = $lookbackDays ?? $this->defaultLookbackDays;
        $startDate = now()->subDays($lookbackDays);

        Log::info('Building historic price statistical models', [
            'region' => $region,
            'lookback_days' => $lookbackDays,
            'start_date' => $startDate->toDateString(),
        ]);

        $stats = [
            'hourly' => $this->buildHourlyStatistics($region, $startDate),
            'hourly_by_day' => $this->buildHourlyByDayStatistics($region, $startDate),
            'hourly_by_month' => $this->buildHourlyByMonthStatistics($region, $startDate),
        ];

        $totalStats = array_sum($stats);

        Log::info('Historic price statistical models built', [
            'region' => $region,
            'total_statistics' => $totalStats,
            'breakdown' => $stats,
        ]);

        return $stats;
    }

    /**
     * Build hourly statistics (24 records, one per hour)
     */
    private function buildHourlyStatistics(string $region, Carbon $startDate): int
    {
        $count = 0;

        for ($hour = 0; $hour < 24; $hour++) {
            $prices = PricingHistory::where('region', $region)
                ->where('timestamp', '>=', $startDate)
                ->where('hour', $hour)
                ->pluck('price_per_kwh')
                ->toArray();

            if (count($prices) < 10) {
                continue; // Skip if insufficient data
            }

            $statistics = $this->calculateStatistics($prices);

            HistoricPriceStatistic::updateOrCreate(
                [
                    'region' => $region,
                    'hour_of_day' => $hour,
                    'day_of_week' => null,
                    'month' => null,
                ],
                array_merge($statistics, [
                    'data_start_date' => $startDate->toDateString(),
                    'data_end_date' => now()->toDateString(),
                    'last_updated' => now(),
                ])
            );

            $count++;
        }

        return $count;
    }

    /**
     * Build hourly statistics by day of week (168 records: 24 hours × 7 days)
     */
    private function buildHourlyByDayStatistics(string $region, Carbon $startDate): int
    {
        $count = 0;

        for ($dayOfWeek = 0; $dayOfWeek < 7; $dayOfWeek++) {
            for ($hour = 0; $hour < 24; $hour++) {
                $prices = PricingHistory::where('region', $region)
                    ->where('timestamp', '>=', $startDate)
                    ->where('hour', $hour)
                    ->whereRaw('DAYOFWEEK(date) = ?', [($dayOfWeek + 1) % 7 + 1]) // Convert to MySQL DAYOFWEEK
                    ->pluck('price_per_kwh')
                    ->toArray();

                if (count($prices) < 5) {
                    continue; // Skip if insufficient data
                }

                $statistics = $this->calculateStatistics($prices);

                HistoricPriceStatistic::updateOrCreate(
                    [
                        'region' => $region,
                        'hour_of_day' => $hour,
                        'day_of_week' => $dayOfWeek,
                        'month' => null,
                    ],
                    array_merge($statistics, [
                        'data_start_date' => $startDate->toDateString(),
                        'data_end_date' => now()->toDateString(),
                        'last_updated' => now(),
                    ])
                );

                $count++;
            }
        }

        return $count;
    }

    /**
     * Build hourly statistics by month (288 records: 24 hours × 12 months)
     */
    private function buildHourlyByMonthStatistics(string $region, Carbon $startDate): int
    {
        $count = 0;

        for ($month = 1; $month <= 12; $month++) {
            for ($hour = 0; $hour < 24; $hour++) {
                $prices = PricingHistory::where('region', $region)
                    ->where('timestamp', '>=', $startDate)
                    ->where('hour', $hour)
                    ->whereRaw('MONTH(date) = ?', [$month])
                    ->pluck('price_per_kwh')
                    ->toArray();

                if (count($prices) < 5) {
                    continue; // Skip if insufficient data
                }

                $statistics = $this->calculateStatistics($prices);

                HistoricPriceStatistic::updateOrCreate(
                    [
                        'region' => $region,
                        'hour_of_day' => $hour,
                        'day_of_week' => null,
                        'month' => $month,
                    ],
                    array_merge($statistics, [
                        'data_start_date' => $startDate->toDateString(),
                        'data_end_date' => now()->toDateString(),
                        'last_updated' => now(),
                    ])
                );

                $count++;
            }
        }

        return $count;
    }

    /**
     * Calculate statistical metrics from price array
     */
    private function calculateStatistics(array $prices): array
    {
        sort($prices);
        $count = count($prices);

        return [
            'avg_price' => array_sum($prices) / $count,
            'median_price' => $this->percentile($prices, 50),
            'min_price' => min($prices),
            'max_price' => max($prices),
            'percentile_10' => $this->percentile($prices, 10),
            'percentile_25' => $this->percentile($prices, 25),
            'percentile_75' => $this->percentile($prices, 75),
            'percentile_90' => $this->percentile($prices, 90),
            'std_deviation' => $this->standardDeviation($prices),
            'variance' => $this->variance($prices),
            'sample_count' => $count,
        ];
    }

    /**
     * Calculate percentile
     */
    private function percentile(array $sortedArray, float $percentile): float
    {
        $index = ($percentile / 100) * (count($sortedArray) - 1);
        $lower = floor($index);
        $upper = ceil($index);

        if ($lower == $upper) {
            return $sortedArray[$lower];
        }

        $fraction = $index - $lower;
        return $sortedArray[$lower] * (1 - $fraction) + $sortedArray[$upper] * $fraction;
    }

    /**
     * Calculate standard deviation
     */
    private function standardDeviation(array $values): float
    {
        return sqrt($this->variance($values));
    }

    /**
     * Calculate variance
     */
    private function variance(array $values): float
    {
        $mean = array_sum($values) / count($values);
        $squaredDiffs = array_map(function ($value) use ($mean) {
            return pow($value - $mean, 2);
        }, $values);

        return array_sum($squaredDiffs) / count($values);
    }

    /**
     * Get typical price for a specific hour/day pattern
     */
    public function getTypicalPrice(Carbon $timestamp, string $region): ?HistoricPriceStatistic
    {
        // Try most specific pattern first (hour + day of week)
        $stat = HistoricPriceStatistic::getTypicalPrice(
            $region,
            $timestamp->hour,
            $timestamp->dayOfWeek
        );

        if ($stat) {
            return $stat;
        }

        // Fall back to hourly pattern
        return HistoricPriceStatistic::getHourlyPattern($region, $timestamp->hour);
    }

    /**
     * Detect if current prices are anomalous
     */
    public function detectPriceAnomaly(float $price, Carbon $timestamp, string $region): bool
    {
        $stat = $this->getTypicalPrice($timestamp, $region);

        if (!$stat) {
            return false;
        }

        return $stat->isAnomalous($price, 2.0); // 2 standard deviations
    }

    /**
     * Find similar historic periods
     */
    public function findSimilarPeriods(
        Carbon $targetDate,
        string $region,
        array $criteria = []
    ): Collection {
        $query = PricingHistory::where('region', $region)
            ->where('date', '<', now()->toDateString());

        // Match hour
        if (isset($criteria['hour'])) {
            $query->where('hour', $criteria['hour']);
        } else {
            $query->where('hour', $targetDate->hour);
        }

        // Match day of week
        if (isset($criteria['day_of_week'])) {
            $query->whereRaw('DAYOFWEEK(date) = ?', [($criteria['day_of_week'] + 1) % 7 + 1]);
        } else {
            $query->whereRaw('DAYOFWEEK(date) = ?', [($targetDate->dayOfWeek + 1) % 7 + 1]);
        }

        // Match month (seasonal)
        if (isset($criteria['month'])) {
            $query->whereRaw('MONTH(date) = ?', [$criteria['month']]);
        }

        // Limit and order by recency
        $limit = $criteria['limit'] ?? 10;
        $query->orderBy('date', 'desc')->limit($limit);

        return $query->get();
    }

    /**
     * Get price distribution for a time period
     */
    public function getPriceDistribution(string $region, int $lookbackDays = 30): array
    {
        $startDate = now()->subDays($lookbackDays);

        $prices = PricingHistory::where('region', $region)
            ->where('timestamp', '>=', $startDate)
            ->pluck('price_per_kwh')
            ->toArray();

        if (empty($prices)) {
            return [];
        }

        sort($prices);

        return [
            'min' => min($prices),
            'max' => max($prices),
            'avg' => array_sum($prices) / count($prices),
            'median' => $this->percentile($prices, 50),
            'p10' => $this->percentile($prices, 10),
            'p25' => $this->percentile($prices, 25),
            'p75' => $this->percentile($prices, 75),
            'p90' => $this->percentile($prices, 90),
            'std_dev' => $this->standardDeviation($prices),
            'sample_count' => count($prices),
        ];
    }

    /**
     * Get best charging hours historically
     */
    public function getBestChargingHours(string $region, int $limit = 5): Collection
    {
        return HistoricPriceStatistic::where('region', $region)
            ->whereNull('day_of_week')
            ->whereNull('month')
            ->orderBy('avg_price')
            ->limit($limit)
            ->get();
    }

    /**
     * Get worst charging hours historically
     */
    public function getWorstChargingHours(string $region, int $limit = 5): Collection
    {
        return HistoricPriceStatistic::where('region', $region)
            ->whereNull('day_of_week')
            ->whereNull('month')
            ->orderBy('avg_price', 'desc')
            ->limit($limit)
            ->get();
    }
}
