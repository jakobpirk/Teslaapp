<?php

namespace App\Services\Charging;

use App\Models\PricePrediction;
use App\Models\PricingHistory;
use App\Services\Charging\Prediction\EnsembleModel;
use App\Services\Charging\Prediction\ExponentialSmoothingModel;
use App\Services\Charging\Prediction\PatternBasedModel;
use App\Services\Charging\Prediction\PredictionModelInterface;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;

class PricePredictionService
{
    private ExponentialSmoothingModel $holtWinters;
    private PatternBasedModel $patternBased;
    private EnsembleModel $ensemble;

    public function __construct()
    {
        $this->holtWinters = new ExponentialSmoothingModel();
        $this->patternBased = new PatternBasedModel();
        $this->ensemble = new EnsembleModel();
    }

    /**
     * Generate predictions for future timestamps
     */
    public function predictPrices(
        Carbon $startTime,
        Carbon $endTime,
        string $region,
        string $model = 'ensemble'
    ): Collection {
        $predictor = $this->getModel($model);

        if (!$predictor->isReady($region)) {
            Log::warning('Prediction model not ready', [
                'model' => $model,
                'region' => $region,
            ]);

            // Train the model if possible
            if ($model !== 'ensemble') {
                $predictor->train($region);
            }
        }

        // Generate predictions
        $predictions = $predictor->predictRange($startTime, $endTime, $region);

        // Store predictions in database
        $this->storePredictions($predictions, $region, $model);

        return collect($predictions);
    }

    /**
     * Get prediction for a single timestamp
     */
    public function predictPrice(Carbon $timestamp, string $region, string $model = 'ensemble'): array
    {
        // Check if we have a recent prediction stored
        $stored = PricePrediction::getLatestPrediction($region, $timestamp, $model);

        if ($stored && $stored->predicted_at->diffInHours(now()) < 6) {
            return [
                'price' => $stored->predicted_price,
                'confidence_low' => $stored->confidence_interval_low,
                'confidence_high' => $stored->confidence_interval_high,
                'confidence_score' => $stored->confidence_score,
                'metadata' => array_merge($stored->prediction_metadata ?? [], [
                    'source' => 'cached',
                    'predicted_at' => $stored->predicted_at->toIso8601String(),
                ]),
            ];
        }

        // Generate new prediction
        $predictor = $this->getModel($model);
        return $predictor->predict($timestamp, $region);
    }

    /**
     * Evaluate prediction accuracy
     */
    public function evaluatePredictionAccuracy(Carbon $date, ?string $model = null): array
    {
        $query = PricePrediction::whereDate('predicted_for_timestamp', $date)
            ->whereNull('actual_price'); // Predictions that haven't been evaluated yet

        if ($model) {
            $query->where('prediction_model', $model);
        }

        $predictions = $query->get();

        $evaluated = 0;
        $accurateCount = 0;

        foreach ($predictions as $prediction) {
            // Get actual price
            $actual = PricingHistory::where('timestamp', $prediction->predicted_for_timestamp)
                ->first();

            if (!$actual) {
                continue;
            }

            // Record actual price and calculate error
            $prediction->recordActual($actual->price_per_kwh);
            $evaluated++;

            if ($prediction->isAccurate(10)) {
                $accurateCount++;
            }
        }

        $accuracy = $evaluated > 0 ? ($accurateCount / $evaluated) * 100 : 0;

        Log::info('Prediction accuracy evaluated', [
            'date' => $date->toDateString(),
            'model' => $model ?? 'all',
            'evaluated' => $evaluated,
            'accurate' => $accurateCount,
            'accuracy' => round($accuracy, 2) . '%',
        ]);

        return [
            'date' => $date->toDateString(),
            'model' => $model ?? 'all',
            'evaluated_count' => $evaluated,
            'accurate_count' => $accurateCount,
            'accuracy_percent' => round($accuracy, 2),
        ];
    }

    /**
     * Get best performing prediction model
     */
    public function getBestPredictionModel(string $region): string
    {
        $models = ['holt_winters', 'pattern_based'];
        $accuracies = [];

        foreach ($models as $model) {
            $recentPredictions = PricePrediction::where('region', $region)
                ->where('prediction_model', $model)
                ->whereNotNull('actual_price')
                ->where('predicted_at', '>=', now()->subDays(30))
                ->get();

            if ($recentPredictions->isEmpty()) {
                $accuracies[$model] = 0;
                continue;
            }

            // Calculate average accuracy
            $avgError = $recentPredictions->avg('prediction_error_percent');
            $accuracies[$model] = max(0, 100 - $avgError);
        }

        if (empty($accuracies) || max($accuracies) == 0) {
            return 'ensemble'; // Default
        }

        return array_search(max($accuracies), $accuracies);
    }

    /**
     * Train prediction models
     */
    public function trainModels(string $region, int $lookbackDays = 180): array
    {
        $results = [];

        // Train Holt-Winters
        try {
            $hwResult = $this->holtWinters->train($region, $lookbackDays);
            $results['holt_winters'] = $hwResult ? 'success' : 'failed';
        } catch (\Exception $e) {
            Log::error('Failed to train Holt-Winters model', [
                'region' => $region,
                'error' => $e->getMessage(),
            ]);
            $results['holt_winters'] = 'error';
        }

        // Pattern-based doesn't need explicit training
        $results['pattern_based'] = $this->patternBased->isReady($region) ? 'ready' : 'no_data';

        // Train ensemble (trains both sub-models)
        try {
            $ensembleResult = $this->ensemble->train($region, $lookbackDays);
            $results['ensemble'] = $ensembleResult ? 'success' : 'failed';
        } catch (\Exception $e) {
            Log::error('Failed to train ensemble model', [
                'region' => $region,
                'error' => $e->getMessage(),
            ]);
            $results['ensemble'] = 'error';
        }

        return $results;
    }

    /**
     * Get prediction performance metrics
     */
    public function getPerformanceMetrics(string $region, int $days = 30): array
    {
        $startDate = now()->subDays($days);

        $models = ['holt_winters', 'pattern_based', 'ensemble'];
        $metrics = [];

        foreach ($models as $model) {
            $predictions = PricePrediction::where('region', $region)
                ->where('prediction_model', $model)
                ->where('predicted_at', '>=', $startDate)
                ->whereNotNull('actual_price')
                ->get();

            if ($predictions->isEmpty()) {
                $metrics[$model] = [
                    'predictions_count' => 0,
                    'avg_error' => null,
                    'avg_error_percent' => null,
                    'accuracy_rate' => null,
                    'within_ci_rate' => null,
                ];
                continue;
            }

            $withinCI = $predictions->filter(fn($p) => $p->withinConfidenceInterval())->count();

            $metrics[$model] = [
                'predictions_count' => $predictions->count(),
                'avg_error' => round($predictions->avg('prediction_error'), 4),
                'avg_error_percent' => round($predictions->avg('prediction_error_percent'), 2),
                'accuracy_rate' => round($predictions->filter(fn($p) => $p->isAccurate(10))->count() / $predictions->count() * 100, 2),
                'within_ci_rate' => round($withinCI / $predictions->count() * 100, 2),
            ];
        }

        return $metrics;
    }

    /**
     * Store predictions in database
     */
    private function storePredictions(array $predictions, string $region, string $model): void
    {
        foreach ($predictions as $prediction) {
            PricePrediction::create([
                'region' => $region,
                'prediction_model' => $model,
                'predicted_for_timestamp' => $prediction['timestamp'],
                'predicted_price' => $prediction['price'],
                'confidence_interval_low' => $prediction['confidence_low'],
                'confidence_interval_high' => $prediction['confidence_high'],
                'confidence_score' => $prediction['confidence_score'],
                'prediction_metadata' => $prediction['metadata'],
                'predicted_at' => now(),
            ]);
        }
    }

    /**
     * Get prediction model instance
     */
    private function getModel(string $modelName): PredictionModelInterface
    {
        return match ($modelName) {
            'holt_winters' => $this->holtWinters,
            'pattern_based' => $this->patternBased,
            'ensemble' => $this->ensemble,
            default => $this->ensemble,
        };
    }

    /**
     * Clean up old predictions
     */
    public function cleanupOldPredictions(int $daysToKeep = 90): int
    {
        $cutoffDate = now()->subDays($daysToKeep);

        $deleted = PricePrediction::where('predicted_for_timestamp', '<', $cutoffDate)
            ->delete();

        Log::info('Old predictions cleaned up', [
            'deleted_count' => $deleted,
            'kept_after' => $cutoffDate->toDateString(),
        ]);

        return $deleted;
    }
}
