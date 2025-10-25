<?php

namespace App\Services\Charging;

use App\Models\ChargingOptimization;
use App\Models\PricingHistory;
use App\Services\Charging\Factors\CarbonIntensityFactorService;
use App\Services\Charging\Factors\ChargingFactorInterface;
use App\Services\Charging\Factors\HistoricPriceFactorService;
use App\Services\Charging\Factors\PriceFactorService;
use App\Services\Charging\Factors\WeatherFactorService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class OptimizationStrategyService
{
    private array $baseWeights = [
        'price' => 0.40,
        'historic_pattern' => 0.20,
        'weather' => 0.20,
        'carbon_intensity' => 0.20,
    ];

    private PriceFactorService $priceFactor;
    private HistoricPriceFactorService $historicFactor;
    private WeatherFactorService $weatherFactor;
    private CarbonIntensityFactorService $carbonFactor;
    private PricePredictionService $predictionService;

    public function __construct()
    {
        $this->priceFactor = new PriceFactorService();
        $this->historicFactor = new HistoricPriceFactorService();
        $this->weatherFactor = new WeatherFactorService();
        $this->carbonFactor = new CarbonIntensityFactorService();
        $this->predictionService = new PricePredictionService();
    }

    /**
     * Score a charging window using all enabled factors
     */
    public function scoreChargingWindow(
        Carbon $windowStart,
        Carbon $windowEnd,
        string $region,
        ?array $historicContext = []
    ): array {
        // Get all enabled factors
        $factors = $this->getEnabledFactors();

        // Calculate dynamic weights based on confidence and performance
        $weights = $this->calculateDynamicWeights($factors, $windowStart, $region);

        // Score each factor
        $factorScores = [];
        $totalWeightedScore = 0;

        foreach ($factors as $name => $factor) {
            try {
                $score = $factor->scoreWindow($windowStart, $windowEnd, $region);
                $weight = $weights[$name];
                $confidence = $factor->getConfidence($windowStart, $region);

                $factorScores[$name] = [
                    'score' => round($score, 2),
                    'weight' => round($weight, 3),
                    'confidence' => round($confidence, 2),
                    'contribution' => round($score * $weight, 2),
                    'explanation' => $factor->getScoreExplanation($windowStart, $windowEnd, $region),
                ];

                $totalWeightedScore += $score * $weight;
            } catch (\Exception $e) {
                Log::error('Error scoring factor', [
                    'factor' => $name,
                    'error' => $e->getMessage(),
                ]);

                $factorScores[$name] = [
                    'score' => 50,
                    'weight' => 0,
                    'confidence' => 0,
                    'contribution' => 0,
                    'explanation' => 'Error calculating score',
                ];
            }
        }

        // Normalize composite score (should already be 0-100)
        $compositeScore = $totalWeightedScore;

        return [
            'composite_score' => round($compositeScore, 2),
            'factor_scores' => $factorScores,
            'weights_used' => $weights,
        ];
    }

    /**
     * Compare current window against historic optimal
     */
    public function compareToHistoricOptimal(
        Carbon $windowStart,
        Carbon $windowEnd,
        string $region
    ): array {
        $currentScore = $this->scoreChargingWindow($windowStart, $windowEnd, $region);

        // Get historic data for same day of week and hour
        $historicAnalysis = app(HistoricPriceAnalysisService::class);
        $similarPeriods = $historicAnalysis->findSimilarPeriods(
            $windowStart,
            $region,
            ['limit' => 20]
        );

        if ($similarPeriods->isEmpty()) {
            return [
                'current_score' => $currentScore['composite_score'],
                'historic_comparison' => 'insufficient_data',
            ];
        }

        $avgHistoricPrice = $similarPeriods->avg('price_per_kwh');
        $currentPrices = PricingHistory::whereBetween('timestamp', [$windowStart, $windowEnd])
            ->where('region', $region)
            ->avg('price_per_kwh');

        $percentBetter = $currentPrices && $avgHistoricPrice
            ? (($avgHistoricPrice - $currentPrices) / $avgHistoricPrice) * 100
            : 0;

        return [
            'current_score' => $currentScore['composite_score'],
            'historic_avg_price' => round($avgHistoricPrice, 4),
            'current_avg_price' => round($currentPrices ?? 0, 4),
            'percent_better_than_historic' => round($percentBetter, 2),
            'similar_periods_analyzed' => $similarPeriods->count(),
        ];
    }

    /**
     * Assess risk of delaying charging
     */
    public function assessDelayRisk(
        Carbon $proposedStart,
        int $currentBatteryLevel,
        float $priceUncertainty
    ): array {
        $hoursUntilStart = now()->diffInHours($proposedStart, false);

        // Battery risk: how many hours of range remaining
        $estimatedRangeHours = ($currentBatteryLevel / 100) * 12; // Assume 12h range at 100%
        $batteryRisk = $estimatedRangeHours < $hoursUntilStart ? 'high' : 'low';

        // Price uncertainty risk
        $uncertaintyRisk = $priceUncertainty > 0.10 ? 'high' : ($priceUncertainty > 0.05 ? 'medium' : 'low');

        // Time risk: further in future = more uncertain
        $timeRisk = $hoursUntilStart > 48 ? 'high' : ($hoursUntilStart > 24 ? 'medium' : 'low');

        // Overall risk
        $riskScore = 0;
        if ($batteryRisk === 'high') $riskScore += 40;
        if ($uncertaintyRisk === 'high') $riskScore += 30;
        elseif ($uncertaintyRisk === 'medium') $riskScore += 15;
        if ($timeRisk === 'high') $riskScore += 30;
        elseif ($timeRisk === 'medium') $riskScore += 15;

        $overallRisk = $riskScore > 50 ? 'high' : ($riskScore > 25 ? 'medium' : 'low');

        return [
            'overall_risk' => $overallRisk,
            'risk_score' => $riskScore,
            'battery_risk' => $batteryRisk,
            'uncertainty_risk' => $uncertaintyRisk,
            'time_risk' => $timeRisk,
            'estimated_range_hours' => round($estimatedRangeHours, 1),
            'hours_until_charging' => $hoursUntilStart,
        ];
    }

    /**
     * Calculate dynamic weights based on confidence and performance
     */
    private function calculateDynamicWeights(array $factors, Carbon $timestamp, string $region): array
    {
        $weights = [];
        $adjustedWeights = [];

        foreach ($factors as $name => $factor) {
            $baseWeight = $this->baseWeights[$name] ?? 0.25;
            $confidence = $factor->getConfidence($timestamp, $region);
            $performance = $this->getFactorPerformance($name, $region);

            // Adjust weight: base × confidence × performance
            $adjusted = $baseWeight * $confidence * $performance;
            $weights[$name] = $baseWeight;
            $adjustedWeights[$name] = $adjusted;
        }

        // Normalize adjusted weights to sum to 1.0
        $totalAdjusted = array_sum($adjustedWeights);

        if ($totalAdjusted > 0) {
            foreach ($adjustedWeights as $name => $weight) {
                $adjustedWeights[$name] = $weight / $totalAdjusted;
            }
        } else {
            // Fall back to base weights
            $adjustedWeights = $this->baseWeights;
        }

        return $adjustedWeights;
    }

    /**
     * Get factor performance score from recent optimizations
     */
    private function getFactorPerformance(string $factorName, string $region): float
    {
        // Analyze last 30 days of optimizations
        $recentOptimizations = ChargingOptimization::where('was_executed', true)
            ->whereNotNull('actual_cost')
            ->where('decision_timestamp', '>=', now()->subDays(30))
            ->get();

        if ($recentOptimizations->isEmpty()) {
            return 1.0; // Default neutral performance
        }

        // Calculate how well optimizations performed when this factor had high scores
        $factorHighScoreOptimizations = $recentOptimizations->filter(function ($opt) use ($factorName) {
            $breakdown = $opt->factors_breakdown;
            return isset($breakdown[$factorName]) && $breakdown[$factorName]['score'] >= 70;
        });

        if ($factorHighScoreOptimizations->isEmpty()) {
            return 1.0;
        }

        // Average prediction accuracy when this factor scored high
        $avgAccuracy = $factorHighScoreOptimizations->avg('prediction_accuracy');

        if ($avgAccuracy === null) {
            return 1.0;
        }

        // Convert accuracy (0-100) to performance multiplier (0.5-1.5)
        return 0.5 + ($avgAccuracy / 100);
    }

    /**
     * Get all enabled factors
     */
    private function getEnabledFactors(): array
    {
        $factors = [];

        // Price factor is always enabled
        $factors['price'] = $this->priceFactor;

        // Historic factor if data available
        if ($this->historicFactor->isEnabled()) {
            $factors['historic_pattern'] = $this->historicFactor;
        }

        // Weather factor if API configured
        if ($this->weatherFactor->isEnabled()) {
            $factors['weather'] = $this->weatherFactor;
        }

        // Carbon intensity factor
        if ($this->carbonFactor->isEnabled()) {
            $factors['carbon_intensity'] = $this->carbonFactor;
        }

        return $factors;
    }

    /**
     * Generate comprehensive optimization report
     */
    public function generateOptimizationReport(
        Carbon $windowStart,
        Carbon $windowEnd,
        string $region,
        array $vehicleContext = []
    ): array {
        $scoring = $this->scoreChargingWindow($windowStart, $windowEnd, $region);
        $comparison = $this->compareToHistoricOptimal($windowStart, $windowEnd, $region);

        $batteryLevel = $vehicleContext['battery_level'] ?? 50;
        $priceUncertainty = $scoring['factor_scores']['price']['confidence'] ?? 0.9;
        $priceUncertainty = 1 - $priceUncertainty; // Convert confidence to uncertainty

        $risk = $this->assessDelayRisk($windowStart, $batteryLevel, $priceUncertainty);

        return [
            'window' => [
                'start' => $windowStart->toIso8601String(),
                'end' => $windowEnd->toIso8601String(),
                'duration_hours' => $windowStart->diffInHours($windowEnd),
            ],
            'scoring' => $scoring,
            'historic_comparison' => $comparison,
            'risk_assessment' => $risk,
            'recommendation' => $this->generateRecommendation($scoring, $risk),
        ];
    }

    /**
     * Generate recommendation based on scoring and risk
     */
    private function generateRecommendation(array $scoring, array $risk): array
    {
        $score = $scoring['composite_score'];
        $riskLevel = $risk['overall_risk'];

        // High risk overrides good score
        if ($riskLevel === 'high') {
            return [
                'action' => 'charge_now',
                'confidence' => 'high',
                'reason' => 'High risk warrants immediate charging despite potential savings',
            ];
        }

        // Very good score and low/medium risk
        if ($score >= 80 && $riskLevel !== 'high') {
            return [
                'action' => 'charge_at_window',
                'confidence' => 'high',
                'reason' => 'Excellent window with acceptable risk',
            ];
        }

        // Good score and low risk
        if ($score >= 70 && $riskLevel === 'low') {
            return [
                'action' => 'charge_at_window',
                'confidence' => 'medium',
                'reason' => 'Good window with low risk',
            ];
        }

        // Moderate score or medium risk
        if ($score >= 60 || $riskLevel === 'medium') {
            return [
                'action' => 'consider_alternatives',
                'confidence' => 'low',
                'reason' => 'Moderate optimization potential, explore other windows',
            ];
        }

        // Poor score
        return [
            'action' => 'avoid',
            'confidence' => 'medium',
            'reason' => 'Better windows likely available',
        ];
    }
}
