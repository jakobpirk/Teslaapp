<?php

namespace App\Services;

use App\Models\ChargingFactor;
use App\Models\ChargingFactorValue;
use App\Models\ChargingRecommendation;
use App\Models\PricingHistory;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Str;

class SmartChargingService
{
    private const TYPICAL_CHARGING_HOURS = 4; // Typical time to charge to 80%
    private const LOOK_AHEAD_HOURS = 48; // How far ahead to look for optimal pricing

    /**
     * Generate a charging recommendation for a vehicle
     *
     * @param string $vehicleId
     * @param array $options Optional parameters (required_by, energy_needed, user)
     * @return ChargingRecommendation
     */
    public function generateRecommendation(string $vehicleId, array $options = []): ChargingRecommendation
    {
        $requiredBy = isset($options['required_by']) ? Carbon::parse($options['required_by']) : Carbon::now()->addHours(self::LOOK_AHEAD_HOURS);
        $energyNeeded = $options['energy_needed'] ?? 50; // kWh
        $user = $options['user'] ?? null; // User model instance for pricing region

        // Get enabled factors
        $enabledFactors = ChargingFactor::getEnabled();

        // Calculate scores for all possible charging windows
        $now = Carbon::now();
        $chargingWindows = $this->analyzeChargingWindows(
            $now,
            $requiredBy,
            $energyNeeded,
            $enabledFactors,
            $user
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

        // Generate human-readable reasoning
        $reasoning = $this->generateReasoning(
            $optimalWindow,
            $shouldChargeNow,
            $costSavings,
            $enabledFactors
        );

        // Create and save recommendation
        $recommendation = ChargingRecommendation::create([
            'id' => Str::uuid(),
            'vehicle_id' => $vehicleId,
            'recommended_start_time' => $optimalWindow['start_time'],
            'recommended_end_time' => $optimalWindow['end_time'],
            'estimated_cost' => $estimatedCost,
            'cost_savings' => max(0, $costSavings),
            'confidence_score' => $this->calculateConfidenceScore($optimalWindow, $enabledFactors),
            'should_charge_now' => $shouldChargeNow,
            'factor_scores' => $optimalWindow['factor_scores'] ?? [],
            'reasoning' => $reasoning,
            'status' => 'pending',
        ]);

        return $recommendation;
    }

    /**
     * Analyze all possible charging windows
     */
    private function analyzeChargingWindows(
        Carbon $startTime,
        Carbon $endTime,
        float $energyNeeded,
        $enabledFactors,
        ?User $user = null
    ): array {
        $windows = [];
        $current = $startTime->copy();

        // Analyze hourly windows
        while ($current->addHour()->lte($endTime->copy()->subHours(self::TYPICAL_CHARGING_HOURS))) {
            $windowStart = $current->copy();
            $windowEnd = $current->copy()->addHours(self::TYPICAL_CHARGING_HOURS);

            $windowScore = $this->scoreChargingWindow(
                $windowStart,
                $windowEnd,
                $energyNeeded,
                $enabledFactors,
                $user
            );

            $windows[] = [
                'start_time' => $windowStart,
                'end_time' => $windowEnd,
                'score' => $windowScore['total_score'],
                'factor_scores' => $windowScore['factor_scores'],
                'estimated_cost' => $windowScore['estimated_cost'],
            ];
        }

        return $windows;
    }

    /**
     * Score a specific charging window based on all enabled factors
     */
    private function scoreChargingWindow(
        Carbon $startTime,
        Carbon $endTime,
        float $energyNeeded,
        $enabledFactors,
        ?User $user = null
    ): array {
        $factorScores = [];
        $totalScore = 0;
        $totalWeight = 0;
        $estimatedCost = 0;

        foreach ($enabledFactors as $factor) {
            $factorScore = $this->scoreFactorForWindow(
                $factor,
                $startTime,
                $endTime,
                $energyNeeded,
                $user
            );

            $weightedScore = $factorScore['normalized_score'] * $factor->weight;
            $totalScore += $weightedScore;
            $totalWeight += $factor->weight;

            $factorScores[$factor->name] = [
                'score' => $factorScore['normalized_score'],
                'weighted_score' => $weightedScore,
                'raw_value' => $factorScore['raw_value'],
                'unit' => $factor->unit,
            ];

            // If this is the price factor, calculate estimated cost
            if ($factor->name === 'price') {
                $estimatedCost = $factorScore['raw_value'] * $energyNeeded;
            }
        }

        // Normalize total score
        $normalizedScore = $totalWeight > 0 ? $totalScore / $totalWeight : 0;

        return [
            'total_score' => $normalizedScore,
            'factor_scores' => $factorScores,
            'estimated_cost' => $estimatedCost,
        ];
    }

    /**
     * Score a specific factor for a charging window
     */
    private function scoreFactorForWindow(
        ChargingFactor $factor,
        Carbon $startTime,
        Carbon $endTime,
        float $energyNeeded,
        ?User $user = null
    ): array {
        // For now, only price factor is implemented
        if ($factor->name === 'price') {
            $query = PricingHistory::whereBetween('timestamp', [$startTime, $endTime]);

            // If user has a pricing region set, filter by region
            if ($user && $user->hasPricingRegion()) {
                $query->where('region', $user->getPricingRegion());
            }

            // If user has an electricity provider, filter by provider
            if ($user && $user->hasElectricityProvider()) {
                $provider = $user->electricityProvider;
                if ($provider) {
                    $query->where('utility_provider', $provider->display_name);
                }
            }

            $avgPrice = $query->avg('price_per_kwh') ?? 0.15;

            // Normalize: lower prices get higher scores (0-100)
            // Assume price range $0.05 - $0.50 per kWh (DKK in Denmark)
            $minPrice = 0.05;
            $maxPrice = 0.50;
            $normalizedScore = 100 * (1 - (($avgPrice - $minPrice) / ($maxPrice - $minPrice)));
            $normalizedScore = max(0, min(100, $normalizedScore));

            return [
                'raw_value' => $avgPrice,
                'normalized_score' => $normalizedScore,
            ];
        }

        // Placeholder for other factors
        return [
            'raw_value' => 0,
            'normalized_score' => 50, // Neutral score
        ];
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

        // If optimal time is now or very soon (within 2 hours), charge now
        if ($optimalStart->lte($now->copy()->addHours(2))) {
            return true;
        }

        // If we're running out of time, charge now
        $hoursUntilRequired = $now->diffInHours($requiredBy);
        if ($hoursUntilRequired < self::TYPICAL_CHARGING_HOURS + 2) {
            return true;
        }

        // If current score is very close to optimal (within 10%), charge now
        $scoreDifference = $optimalWindow['score'] - $currentWindow['score'];
        if ($scoreDifference < 10) {
            return true;
        }

        return false;
    }

    /**
     * Calculate confidence score for the recommendation
     */
    private function calculateConfidenceScore(array $optimalWindow, $enabledFactors): int
    {
        // Base confidence on:
        // 1. How much data we have (more factors = higher confidence)
        // 2. The score itself (higher scores = more confident)

        $factorCount = $enabledFactors->count();
        $maxFactors = 4; // Total possible factors
        $factorConfidence = ($factorCount / $maxFactors) * 50;

        $scoreConfidence = ($optimalWindow['score'] / 100) * 50;

        return (int) round($factorConfidence + $scoreConfidence);
    }

    /**
     * Generate human-readable reasoning
     */
    private function generateReasoning(
        array $optimalWindow,
        bool $shouldChargeNow,
        float $costSavings,
        $enabledFactors
    ): string {
        $reasoning = [];

        if ($shouldChargeNow) {
            $reasoning[] = "✓ Recommended to start charging now.";

            if ($costSavings > 0) {
                $reasoning[] = sprintf("You could save approximately $%.2f compared to charging at a different time.", $costSavings);
            } else {
                $reasoning[] = "Current rates are optimal for charging.";
            }
        } else {
            $optimalTime = $optimalWindow['start_time']->format('g:i A');
            $reasoning[] = sprintf("⏰ Recommended to wait until %s to start charging.", $optimalTime);

            if ($costSavings > 0) {
                $reasoning[] = sprintf("You could save approximately $%.2f by waiting.", $costSavings);
            }
        }

        // Add factor-specific reasoning
        if (isset($optimalWindow['factor_scores']['price'])) {
            $priceScore = $optimalWindow['factor_scores']['price'];
            $avgPrice = $priceScore['raw_value'];
            $reasoning[] = sprintf("Average electricity rate during optimal window: $%.4f/kWh.", $avgPrice);
        }

        return implode("\n", $reasoning);
    }

    /**
     * Check if a recommendation is still valid
     */
    public function isRecommendationValid(ChargingRecommendation $recommendation): bool
    {
        return $recommendation->isValid();
    }
}
