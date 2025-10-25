<?php

namespace App\Services;

use App\Models\ChargingOptimization;
use App\Models\ChargingRecommendation;
use App\Models\PricingHistory;
use App\Services\Charging\HistoricPriceAnalysisService;
use App\Services\Charging\OptimizationStrategyService;
use App\Services\Charging\PricePredictionService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class SmartChargingService
{
    private const TYPICAL_CHARGING_HOURS = 4; // Typical time to charge to 80%
    private const LOOK_AHEAD_HOURS = 48; // How far ahead to look for optimal pricing
    private const OPTIMIZATION_VERSION = 'v2_multi_factor'; // Track optimization version
    private const CHARGE_NOW_THRESHOLD_HOURS = 2; // If optimal is within this time, charge now
    private const SCORE_DIFFERENCE_THRESHOLD = 10; // If score difference is less than this, charge now
    private const DEFAULT_ENERGY_NEEDED_KWH = 50; // Default energy needed in kWh
    private const DEFAULT_BATTERY_LEVEL_PERCENT = 50; // Default battery percentage
    private const DEFAULT_REGION = 'east'; // Default pricing region

    private OptimizationStrategyService $optimizationService;
    private PricePredictionService $predictionService;
    private HistoricPriceAnalysisService $historicAnalysisService;

    public function __construct()
    {
        $this->optimizationService = new OptimizationStrategyService();
        $this->predictionService = new PricePredictionService();
        $this->historicAnalysisService = new HistoricPriceAnalysisService();
    }

    /**
     * Generate a charging recommendation for a vehicle
     *
     * @param string $vehicleId
     * @param array $options Optional parameters (required_by, energy_needed, user, battery_level)
     * @return ChargingRecommendation
     */
    public function generateRecommendation(string $vehicleId, array $options = []): ChargingRecommendation
    {
        $requiredBy = isset($options['required_by']) ? Carbon::parse($options['required_by']) : Carbon::now()->addHours(self::LOOK_AHEAD_HOURS);
        $energyNeeded = $options['energy_needed'] ?? self::DEFAULT_ENERGY_NEEDED_KWH;
        $user = $options['user'] ?? null; // User model instance for pricing region
        $batteryLevel = $options['battery_level'] ?? self::DEFAULT_BATTERY_LEVEL_PERCENT;

        $region = $user ? $user->getPricingRegion() : self::DEFAULT_REGION;

        Log::info('Generating charging recommendation with multi-factor optimization', [
            'vehicle_id' => $vehicleId,
            'optimization_version' => self::OPTIMIZATION_VERSION,
            'region' => $region,
        ]);

        // Calculate scores for all possible charging windows using new optimization
        $now = Carbon::now();
        $chargingWindows = $this->analyzeChargingWindowsV2(
            $now,
            $requiredBy,
            $energyNeeded,
            $region,
            $batteryLevel
        );

        // Find the optimal window
        $optimalWindow = $this->findOptimalWindow($chargingWindows);
        $currentWindowScore = $this->getCurrentWindowScore($chargingWindows);

        // Determine if we should charge now
        $shouldChargeNow = $this->shouldChargeNow($optimalWindow, $currentWindowScore, $requiredBy);

        // Calculate cost estimates
        $estimatedCost = $optimalWindow['estimated_cost'] ?? 0;
        $currentCost = $currentWindowScore['estimated_cost'] ?? 0;
        $costSavings = $currentCost - $estimatedCost;

        // Generate comprehensive reasoning
        $reasoning = $this->generateReasoningV2(
            $optimalWindow,
            $shouldChargeNow,
            $costSavings,
            $region
        );

        // Create and save recommendation
        $recommendation = ChargingRecommendation::create([
            'id' => Str::uuid(),
            'vehicle_id' => $vehicleId,
            'recommended_start_time' => $optimalWindow['start_time'],
            'recommended_end_time' => $optimalWindow['end_time'],
            'estimated_cost' => $estimatedCost,
            'cost_savings' => max(0, $costSavings),
            'confidence_score' => $optimalWindow['confidence'] ?? 70,
            'should_charge_now' => $shouldChargeNow,
            'factor_scores' => $optimalWindow['factor_breakdown'] ?? [],
            'reasoning' => $reasoning,
            'status' => 'pending',
        ]);

        // Track optimization for performance analysis
        $this->trackOptimization(
            $vehicleId,
            $recommendation->id,
            $optimalWindow,
            $region,
            $batteryLevel
        );

        Log::info('Charging recommendation generated', [
            'recommendation_id' => $recommendation->id,
            'should_charge_now' => $shouldChargeNow,
            'estimated_savings' => round($costSavings, 2),
            'confidence' => $optimalWindow['confidence'] ?? 70,
        ]);

        return $recommendation;
    }


    /**
     * Find the optimal charging window (highest score)
     */
    private function findOptimalWindow(array $windows): array
    {
        if (empty($windows)) {
            return [
                'start_time' => Carbon::now(),
                'end_time' => Carbon::now()->addHours(self::TYPICAL_CHARGING_HOURS),
                'score' => 0,
                'estimated_cost' => 0,
            ];
        }

        usort($windows, fn($a, $b) => $b['score'] <=> $a['score']);

        return $windows[0];
    }

    /**
     * Get the score for charging right now
     */
    private function getCurrentWindowScore(array $windows): array
    {
        return $windows[0] ?? [
            'start_time' => Carbon::now(),
            'end_time' => Carbon::now()->addHours(self::TYPICAL_CHARGING_HOURS),
            'score' => 0,
            'estimated_cost' => 0,
        ];
    }

    /**
     * Determine if charging should start now
     */
    private function shouldChargeNow(array $optimalWindow, array $currentWindow, Carbon $requiredBy): bool
    {
        $now = Carbon::now();
        $optimalStart = $optimalWindow['start_time'];

        // If optimal time is now or very soon, charge now
        if ($optimalStart->lte($now->copy()->addHours(self::CHARGE_NOW_THRESHOLD_HOURS))) {
            return true;
        }

        // If we're running out of time, charge now
        $hoursUntilRequired = $now->diffInHours($requiredBy);
        if ($hoursUntilRequired < self::TYPICAL_CHARGING_HOURS + self::CHARGE_NOW_THRESHOLD_HOURS) {
            return true;
        }

        // If current score is very close to optimal, charge now
        $scoreDifference = $optimalWindow['score'] - $currentWindow['score'];
        if ($scoreDifference < self::SCORE_DIFFERENCE_THRESHOLD) {
            return true;
        }

        return false;
    }


    /**
     * Check if a recommendation is still valid
     */
    public function isRecommendationValid(ChargingRecommendation $recommendation): bool
    {
        return $recommendation->isValid();
    }

    /**
     * Analyze charging windows using V2 multi-factor optimization
     */
    private function analyzeChargingWindowsV2(
        Carbon $startTime,
        Carbon $endTime,
        float $energyNeeded,
        string $region,
        int $batteryLevel
    ): array {
        $windows = [];
        $current = $startTime->copy();

        // Analyze hourly windows
        while ($current->addHour()->lte($endTime->copy()->subHours(self::TYPICAL_CHARGING_HOURS))) {
            $windowStart = $current->copy();
            $windowEnd = $current->copy()->addHours(self::TYPICAL_CHARGING_HOURS);

            try {
                // Use OptimizationStrategyService for multi-factor scoring
                $scoring = $this->optimizationService->scoreChargingWindow(
                    $windowStart,
                    $windowEnd,
                    $region
                );

                // Generate comprehensive report
                $report = $this->optimizationService->generateOptimizationReport(
                    $windowStart,
                    $windowEnd,
                    $region,
                    ['battery_level' => $batteryLevel]
                );

                // Calculate cost estimate
                $avgPrice = $this->getAveragePriceForWindow($windowStart, $windowEnd, $region);
                $estimatedCost = $avgPrice * $energyNeeded;

                $windows[] = [
                    'start_time' => $windowStart,
                    'end_time' => $windowEnd,
                    'score' => $scoring['composite_score'],
                    'confidence' => $scoring['composite_score'],
                    'factor_breakdown' => $scoring['factor_scores'],
                    'estimated_cost' => $estimatedCost,
                    'avg_price' => $avgPrice,
                    'risk_assessment' => $report['risk_assessment'],
                    'historic_comparison' => $report['historic_comparison'],
                ];
            } catch (\Exception $e) {
                Log::error('Error analyzing window', [
                    'window_start' => $windowStart->toIso8601String(),
                    'error' => $e->getMessage(),
                ]);

                // Fallback to basic scoring
                $windows[] = [
                    'start_time' => $windowStart,
                    'end_time' => $windowEnd,
                    'score' => 50,
                    'confidence' => 30,
                    'estimated_cost' => $energyNeeded * 0.25,
                    'avg_price' => 0.25,
                ];
            }
        }

        return $windows;
    }

    /**
     * Get average price for a window (including predictions)
     */
    private function getAveragePriceForWindow(Carbon $start, Carbon $end, string $region): float
    {
        // Try to get actual prices first
        $actualPrices = PricingHistory::whereBetween('timestamp', [$start, $end])
            ->where('region', $region)
            ->pluck('price_per_kwh');

        $hoursInWindow = $start->diffInHours($end);

        // If we have all actual prices, use them
        if ($actualPrices->count() >= $hoursInWindow) {
            return $actualPrices->avg();
        }

        // Otherwise, combine actual + predicted prices
        $current = $start->copy();
        $prices = [];

        while ($current < $end) {
            $actualPrice = PricingHistory::where('timestamp', $current)
                ->where('region', $region)
                ->value('price_per_kwh');

            if ($actualPrice !== null) {
                $prices[] = $actualPrice;
            } else {
                // Get prediction
                $prediction = $this->predictionService->predictPrice($current, $region);
                $prices[] = $prediction['price'];
            }

            $current->addHour();
        }

        return count($prices) > 0 ? array_sum($prices) / count($prices) : 0.25;
    }

    /**
     * Generate comprehensive reasoning using V2 optimization data
     */
    private function generateReasoningV2(
        array $optimalWindow,
        bool $shouldChargeNow,
        float $costSavings,
        string $region
    ): string {
        $reasoning = [];

        if ($shouldChargeNow) {
            $reasoning[] = "✓ Recommended to start charging now.";

            if ($costSavings > 0) {
                $reasoning[] = sprintf("Estimated savings: $%.2f compared to sub-optimal windows.", $costSavings);
            } else {
                $reasoning[] = "Current conditions are optimal for charging.";
            }
        } else {
            $optimalTime = $optimalWindow['start_time']->format('g:i A, l');
            $reasoning[] = sprintf("⏰ Recommended to wait until %s.", $optimalTime);

            if ($costSavings > 0) {
                $reasoning[] = sprintf("Estimated savings: $%.2f by waiting for optimal window.", $costSavings);
            }
        }

        // Add multi-factor insights
        $factorBreakdown = $optimalWindow['factor_breakdown'] ?? [];

        if (!empty($factorBreakdown)) {
            $reasoning[] = "\n📊 Optimization Factors:";

            foreach ($factorBreakdown as $factorName => $factorData) {
                $score = $factorData['score'] ?? 0;
                $explanation = $factorData['explanation'] ?? '';

                if ($score >= 80) {
                    $rating = 'Excellent';
                } elseif ($score >= 70) {
                    $rating = 'Good';
                } elseif ($score >= 60) {
                    $rating = 'Fair';
                } else {
                    $rating = 'Poor';
                }

                $factorLabel = match ($factorName) {
                    'price' => '💰 Price',
                    'historic_pattern' => '📈 Historic Pattern',
                    'weather' => '🌤️  Weather',
                    'carbon_intensity' => '🌱 Carbon Intensity',
                    default => $factorName,
                };

                $reasoning[] = sprintf("%s: %s (%d/100) - %s", $factorLabel, $rating, $score, $explanation);
            }
        }

        // Add historic comparison if available
        if (isset($optimalWindow['historic_comparison'])) {
            $comparison = $optimalWindow['historic_comparison'];
            if (isset($comparison['percent_better_than_historic'])) {
                $percent = $comparison['percent_better_than_historic'];
                if ($percent > 0) {
                    $reasoning[] = sprintf("\n📊 This window is %.1f%% better than historic average for similar periods.", $percent);
                }
            }
        }

        // Add risk assessment
        if (isset($optimalWindow['risk_assessment'])) {
            $risk = $optimalWindow['risk_assessment'];
            $riskLevel = $risk['overall_risk'] ?? 'unknown';

            if ($riskLevel === 'high') {
                $reasoning[] = "\n⚠️  Risk: High - Consider charging sooner if battery is low.";
            } elseif ($riskLevel === 'medium') {
                $reasoning[] = "\n⚡ Risk: Medium - Monitor battery level.";
            }
        }

        return implode("\n", $reasoning);
    }

    /**
     * Track optimization decision for performance analysis
     */
    private function trackOptimization(
        string $vehicleId,
        string $recommendationId,
        array $optimalWindow,
        string $region,
        int $batteryLevel
    ): void {
        try {
            ChargingOptimization::create([
                'id' => Str::uuid(),
                'vehicle_id' => $vehicleId,
                'charging_recommendation_id' => $recommendationId,
                'decision_timestamp' => now(),
                'optimization_version' => self::OPTIMIZATION_VERSION,
                'recommended_window_start' => $optimalWindow['start_time'],
                'recommended_window_end' => $optimalWindow['end_time'],
                'was_executed' => false,
                'predicted_cost' => $optimalWindow['estimated_cost'] ?? 0,
                'predicted_savings' => 0, // Will be calculated when executed
                'factors_used' => array_keys($optimalWindow['factor_breakdown'] ?? []),
                'factors_breakdown' => $optimalWindow['factor_breakdown'] ?? [],
                'factor_weights' => [], // Weights are embedded in factor_breakdown
                'weather_data' => $this->extractWeatherData($optimalWindow),
                'carbon_data' => $this->extractCarbonData($optimalWindow),
                'price_data' => $this->extractPriceData($optimalWindow),
                'composite_score' => $optimalWindow['score'] ?? 0,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to track optimization', [
                'vehicle_id' => $vehicleId,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Extract weather data from optimization window
     */
    private function extractWeatherData(array $window): ?array
    {
        $factorBreakdown = $window['factor_breakdown'] ?? [];

        if (isset($factorBreakdown['weather'])) {
            return [
                'score' => $factorBreakdown['weather']['score'] ?? null,
                'explanation' => $factorBreakdown['weather']['explanation'] ?? null,
            ];
        }

        return null;
    }

    /**
     * Extract carbon data from optimization window
     */
    private function extractCarbonData(array $window): ?array
    {
        $factorBreakdown = $window['factor_breakdown'] ?? [];

        if (isset($factorBreakdown['carbon_intensity'])) {
            return [
                'score' => $factorBreakdown['carbon_intensity']['score'] ?? null,
                'explanation' => $factorBreakdown['carbon_intensity']['explanation'] ?? null,
            ];
        }

        return null;
    }

    /**
     * Extract price data from optimization window
     */
    private function extractPriceData(array $window): ?array
    {
        $factorBreakdown = $window['factor_breakdown'] ?? [];

        if (isset($factorBreakdown['price'])) {
            return [
                'score' => $factorBreakdown['price']['score'] ?? null,
                'avg_price' => $window['avg_price'] ?? null,
                'explanation' => $factorBreakdown['price']['explanation'] ?? null,
            ];
        }

        return null;
    }
}
