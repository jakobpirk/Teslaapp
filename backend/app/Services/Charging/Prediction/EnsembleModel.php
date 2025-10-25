<?php

namespace App\Services\Charging\Prediction;

use App\Models\PricePrediction;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class EnsembleModel implements PredictionModelInterface
{
    private ExponentialSmoothingModel $holtWinters;
    private PatternBasedModel $patternBased;

    public function __construct()
    {
        $this->holtWinters = new ExponentialSmoothingModel();
        $this->patternBased = new PatternBasedModel();
    }

    public function getName(): string
    {
        return 'ensemble';
    }

    public function predict(Carbon $timestamp, string $region): array
    {
        // Get predictions from both models
        $predictions = [];
        $weights = [];

        // Holt-Winters prediction
        if ($this->holtWinters->isReady($region)) {
            $hwPrediction = $this->holtWinters->predict($timestamp, $region);
            $predictions['holt_winters'] = $hwPrediction;
            $weights['holt_winters'] = $this->getModelWeight('holt_winters', $region);
        }

        // Pattern-based prediction
        if ($this->patternBased->isReady($region)) {
            $pbPrediction = $this->patternBased->predict($timestamp, $region);
            $predictions['pattern_based'] = $pbPrediction;
            $weights['pattern_based'] = $this->getModelWeight('pattern_based', $region);
        }

        if (empty($predictions)) {
            return $this->getDefaultPrediction();
        }

        // If only one model available, use it
        if (count($predictions) === 1) {
            $prediction = reset($predictions);
            $prediction['metadata']['ensemble_note'] = 'Only one model available';
            return $prediction;
        }

        // Combine predictions using weighted average
        $totalWeight = array_sum($weights);
        if ($totalWeight == 0) {
            $totalWeight = count($weights);
            $weights = array_fill_keys(array_keys($weights), 1);
        }

        $ensemblePrice = 0;
        $ensembleConfidenceLow = 0;
        $ensembleConfidenceHigh = 0;
        $ensembleConfidenceScore = 0;

        foreach ($predictions as $modelName => $prediction) {
            $weight = $weights[$modelName] / $totalWeight;
            $ensemblePrice += $prediction['price'] * $weight;
            $ensembleConfidenceLow += $prediction['confidence_low'] * $weight;
            $ensembleConfidenceHigh += $prediction['confidence_high'] * $weight;
            $ensembleConfidenceScore += $prediction['confidence_score'] * $weight;
        }

        return [
            'price' => round($ensemblePrice, 4),
            'confidence_low' => round($ensembleConfidenceLow, 4),
            'confidence_high' => round($ensembleConfidenceHigh, 4),
            'confidence_score' => round($ensembleConfidenceScore, 2),
            'metadata' => [
                'model' => $this->getName(),
                'models_used' => array_keys($predictions),
                'weights' => $weights,
                'individual_predictions' => array_map(function ($p) {
                    return ['price' => $p['price'], 'confidence' => $p['confidence_score']];
                }, $predictions),
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
        // Train both component models
        $hwTrained = $this->holtWinters->train($region, $lookbackDays);
        $pbTrained = $this->patternBased->train($region, $lookbackDays);

        return $hwTrained || $pbTrained;
    }

    public function getMetadata(): array
    {
        return [
            'name' => $this->getName(),
            'type' => 'ensemble',
            'description' => 'Combines multiple models with performance-based weighting',
            'component_models' => [
                $this->holtWinters->getMetadata(),
                $this->patternBased->getMetadata(),
            ],
        ];
    }

    public function isReady(string $region): bool
    {
        return $this->holtWinters->isReady($region) || $this->patternBased->isReady($region);
    }

    /**
     * Get model weight based on recent performance
     */
    private function getModelWeight(string $modelName, string $region): float
    {
        // Analyze last 7 days of predictions for this model
        $recentPredictions = PricePrediction::where('region', $region)
            ->where('prediction_model', $modelName)
            ->where('predicted_at', '>=', now()->subDays(7))
            ->whereNotNull('actual_price')
            ->get();

        if ($recentPredictions->isEmpty()) {
            // No performance data, use default weights
            return $this->getDefaultWeight($modelName);
        }

        // Calculate accuracy (inverse of average error)
        $accuracyScores = $recentPredictions->map(function ($prediction) {
            // Predictions within 10% are considered good
            $errorPercent = $prediction->prediction_error_percent;
            return max(0, 100 - $errorPercent) / 100;
        });

        $avgAccuracy = $accuracyScores->avg();

        // Weight is proportional to accuracy (0.5 to 1.5 range)
        return 0.5 + ($avgAccuracy * 1.0);
    }

    /**
     * Get default weight for a model
     */
    private function getDefaultWeight(string $modelName): float
    {
        return match ($modelName) {
            'holt_winters' => 0.6,      // Slightly prefer ML model
            'pattern_based' => 0.4,
            default => 0.5,
        };
    }

    /**
     * Default prediction when no models available
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
                'status' => 'no_models_available',
            ],
        ];
    }
}
