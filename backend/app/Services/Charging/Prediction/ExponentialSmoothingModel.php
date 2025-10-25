<?php

namespace App\Services\Charging\Prediction;

use App\Models\PricingHistory;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class ExponentialSmoothingModel implements PredictionModelInterface
{
    // Holt-Winters parameters
    private float $alpha = 0.3;  // Level smoothing
    private float $beta = 0.1;   // Trend smoothing
    private float $gamma = 0.2;  // Seasonal smoothing
    private int $seasonPeriod = 168; // Weekly pattern (168 hours)

    public function getName(): string
    {
        return 'holt_winters';
    }

    public function predict(Carbon $timestamp, string $region): array
    {
        // Get model parameters from cache
        $params = $this->getModelParameters($region);

        if (!$params) {
            return $this->getDefaultPrediction();
        }

        // Calculate hours ahead from last known data point
        $lastDataPoint = Carbon::parse($params['last_timestamp']);
        $hoursAhead = $lastDataPoint->diffInHours($timestamp, false);

        if ($hoursAhead < 0) {
            // Requesting past data, not a prediction
            return $this->getDefaultPrediction();
        }

        // Triple exponential smoothing forecast
        $level = $params['level'];
        $trend = $params['trend'];
        $seasonal = $params['seasonal'];

        // Forecast: L_t + h*b_t + s_{t+h-m}
        $seasonalIndex = $hoursAhead % $this->seasonPeriod;
        $forecast = $level + ($hoursAhead * $trend) + ($seasonal[$seasonalIndex] ?? 0);

        // Calculate confidence interval
        // Wider interval for further predictions
        $baseError = $params['avg_error'] ?? 0.02;
        $timeDecay = 1 + ($hoursAhead / 24) * 0.1; // Increase uncertainty by 10% per day
        $error = $baseError * $timeDecay;

        $confidenceLow = max(0.01, $forecast - (1.96 * $error));  // 95% CI
        $confidenceHigh = $forecast + (1.96 * $error);

        // Confidence score decreases with time
        $confidenceScore = max(40, 95 - ($hoursAhead / 24 * 5));

        return [
            'price' => round($forecast, 4),
            'confidence_low' => round($confidenceLow, 4),
            'confidence_high' => round($confidenceHigh, 4),
            'confidence_score' => round($confidenceScore, 2),
            'metadata' => [
                'model' => $this->getName(),
                'hours_ahead' => $hoursAhead,
                'level' => $level,
                'trend' => $trend,
                'seasonal_component' => $seasonal[$seasonalIndex] ?? 0,
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
        try {
            // Get historical pricing data
            $startDate = now()->subDays($lookbackDays);
            $prices = PricingHistory::where('region', $region)
                ->where('timestamp', '>=', $startDate)
                ->orderBy('timestamp')
                ->pluck('price_per_kwh', 'timestamp')
                ->toArray();

            if (count($prices) < $this->seasonPeriod * 2) {
                Log::warning('Insufficient data for Holt-Winters training', [
                    'region' => $region,
                    'data_points' => count($prices),
                ]);
                return false;
            }

            // Initialize components
            $level = array_sum(array_slice($prices, 0, $this->seasonPeriod)) / $this->seasonPeriod;
            $trend = 0;
            $seasonal = $this->initializeSeasonalComponents($prices);

            // Apply Holt-Winters smoothing
            $errors = [];
            $timestamps = array_keys($prices);

            foreach ($prices as $timestamp => $actual) {
                $timestampIndex = array_search($timestamp, $timestamps);
                $seasonalIndex = $timestampIndex % $this->seasonPeriod;

                // Forecast
                $forecast = $level + $trend + $seasonal[$seasonalIndex];
                $errors[] = abs($actual - $forecast);

                // Update components
                $prevLevel = $level;
                $level = $this->alpha * ($actual - $seasonal[$seasonalIndex]) + (1 - $this->alpha) * ($level + $trend);
                $trend = $this->beta * ($level - $prevLevel) + (1 - $this->beta) * $trend;
                $seasonal[$seasonalIndex] = $this->gamma * ($actual - $level) + (1 - $this->gamma) * $seasonal[$seasonalIndex];
            }

            // Calculate average error for confidence intervals
            $avgError = count($errors) > 0 ? array_sum($errors) / count($errors) : 0.02;

            // Store model parameters in cache
            $params = [
                'level' => $level,
                'trend' => $trend,
                'seasonal' => $seasonal,
                'avg_error' => $avgError,
                'last_timestamp' => end($timestamps),
                'trained_at' => now()->toIso8601String(),
                'data_points' => count($prices),
            ];

            Cache::put("holt_winters_model_{$region}", $params, now()->addDays(1));

            Log::info('Holt-Winters model trained successfully', [
                'region' => $region,
                'data_points' => count($prices),
                'avg_error' => $avgError,
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Failed to train Holt-Winters model', [
                'region' => $region,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    public function getMetadata(): array
    {
        return [
            'name' => $this->getName(),
            'type' => 'exponential_smoothing',
            'description' => 'Triple exponential smoothing (Holt-Winters) with trend and seasonality',
            'parameters' => [
                'alpha' => $this->alpha,
                'beta' => $this->beta,
                'gamma' => $this->gamma,
                'season_period' => $this->seasonPeriod,
            ],
        ];
    }

    public function isReady(string $region): bool
    {
        return Cache::has("holt_winters_model_{$region}");
    }

    /**
     * Initialize seasonal components using classical decomposition
     */
    private function initializeSeasonalComponents(array $prices): array
    {
        $seasonal = array_fill(0, $this->seasonPeriod, 0);
        $pricesArray = array_values($prices);

        // Calculate average for each seasonal period
        $seasonalSums = array_fill(0, $this->seasonPeriod, 0);
        $seasonalCounts = array_fill(0, $this->seasonPeriod, 0);

        foreach ($pricesArray as $index => $price) {
            $seasonalIndex = $index % $this->seasonPeriod;
            $seasonalSums[$seasonalIndex] += $price;
            $seasonalCounts[$seasonalIndex]++;
        }

        // Calculate overall average
        $overallAvg = array_sum($pricesArray) / count($pricesArray);

        // Calculate seasonal indices (difference from overall average)
        for ($i = 0; $i < $this->seasonPeriod; $i++) {
            if ($seasonalCounts[$i] > 0) {
                $seasonal[$i] = ($seasonalSums[$i] / $seasonalCounts[$i]) - $overallAvg;
            }
        }

        return $seasonal;
    }

    /**
     * Get model parameters from cache
     */
    private function getModelParameters(string $region): ?array
    {
        return Cache::get("holt_winters_model_{$region}");
    }

    /**
     * Default prediction when model is not ready
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
                'status' => 'not_trained',
            ],
        ];
    }
}
