<?php

namespace App\Services\Charging\Factors;

use Carbon\Carbon;
use Illuminate\Support\Collection;

interface ChargingFactorInterface
{
    /**
     * Get unique identifier for this factor
     */
    public function getName(): string;

    /**
     * Get human-readable display name
     */
    public function getDisplayName(): string;

    /**
     * Get factor data for a time range
     * Returns collection of data points with timestamp and value
     */
    public function getData(Carbon $start, Carbon $end, string $region): Collection;

    /**
     * Score a charging window (0-100)
     * Higher score = better for charging
     *
     * @param Carbon $windowStart
     * @param Carbon $windowEnd
     * @param string $region
     * @return float Score between 0 and 100
     */
    public function scoreWindow(Carbon $windowStart, Carbon $windowEnd, string $region): float;

    /**
     * Get factor weight (0-1)
     * Can be dynamic based on recent performance
     */
    public function getWeight(): float;

    /**
     * Get confidence in factor data (0-1)
     * Lower confidence = less weight in final decision
     */
    public function getConfidence(Carbon $timestamp, string $region): float;

    /**
     * Get factor metadata and additional information
     */
    public function getMetadata(): array;

    /**
     * Check if this factor is enabled
     */
    public function isEnabled(): bool;

    /**
     * Get detailed explanation for the score
     */
    public function getScoreExplanation(Carbon $windowStart, Carbon $windowEnd, string $region): string;
}
