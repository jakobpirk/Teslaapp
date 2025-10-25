<?php

namespace App\Services\Charging\Factors;

use App\Models\HistoricPriceStatistic;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class HistoricPriceFactorService implements ChargingFactorInterface
{
    private float $weight = 0.20; // 20% base weight

    public function getName(): string
    {
        return 'historic_pattern';
    }

    public function getDisplayName(): string
    {
        return 'Historic Price Pattern';
    }

    public function getData(Carbon $start, Carbon $end, string $region): Collection
    {
        $data = collect();
        $current = $start->copy();

        while ($current <= $end) {
            $stat = HistoricPriceStatistic::getTypicalPrice(
                $region,
                $current->hour,
                $current->dayOfWeek,
                null // Don't filter by month for now
            );

            if ($stat) {
                $data->push([
                    'timestamp' => $current->copy(),
                    'avg_price' => $stat->avg_price,
                    'median_price' => $stat->median_price,
                    'percentile_25' => $stat->percentile_25,
                    'percentile_75' => $stat->percentile_75,
                    'sample_count' => $stat->sample_count,
                ]);
            }

            $current->addHour();
        }

        return $data;
    }

    public function scoreWindow(Carbon $windowStart, Carbon $windowEnd, string $region): float
    {
        $historicData = $this->getData($windowStart, $windowEnd, $region);

        if ($historicData->isEmpty()) {
            return 50; // Neutral score
        }

        // Calculate how this window compares to all hours of the day historically
        $avgWindowPrice = $historicData->avg('avg_price');

        // Get all 24 hour statistics to compare
        $allHourStats = collect(range(0, 23))->map(function ($hour) use ($region) {
            return HistoricPriceStatistic::getHourlyPattern($region, $hour);
        })->filter()->pluck('avg_price');

        if ($allHourStats->isEmpty()) {
            return 50;
        }

        $minHistoricPrice = $allHourStats->min();
        $maxHistoricPrice = $allHourStats->max();

        // Score based on percentile rank (lower price = higher score)
        $normalized = ($maxHistoricPrice - $avgWindowPrice) / ($maxHistoricPrice - $minHistoricPrice);
        $score = $normalized * 100;

        return max(0, min(100, $score));
    }

    public function getWeight(): float
    {
        return $this->weight;
    }

    public function getConfidence(Carbon $timestamp, string $region): float
    {
        $stat = HistoricPriceStatistic::getTypicalPrice(
            $region,
            $timestamp->hour,
            $timestamp->dayOfWeek
        );

        if (!$stat) {
            return 0.0;
        }

        // Confidence based on sample size
        // 30 samples = 50% confidence, 90+ samples = 100% confidence
        $sampleCount = $stat->sample_count;
        $confidence = min(1.0, $sampleCount / 90);

        return max(0.3, $confidence); // Minimum 30% confidence
    }

    public function getMetadata(): array
    {
        return [
            'unit' => '$/kWh',
            'data_type' => 'numeric',
            'source' => 'Historic price analysis',
            'lookback_period' => '6 months',
        ];
    }

    public function isEnabled(): bool
    {
        // Check if we have any historic statistics
        return HistoricPriceStatistic::count() > 0;
    }

    public function getScoreExplanation(Carbon $windowStart, Carbon $windowEnd, string $region): string
    {
        $historicData = $this->getData($windowStart, $windowEnd, $region);

        if ($historicData->isEmpty()) {
            return 'No historic data available for this time period';
        }

        $avgPrice = $historicData->avg('avg_price');
        $sampleCount = $historicData->avg('sample_count');

        // Get percentile rank
        $hourStat = HistoricPriceStatistic::getTypicalPrice($region, $windowStart->hour);
        $percentileRank = $hourStat ? $hourStat->getPercentileRank($avgPrice) : 50;

        return sprintf(
            'Historically averages $%.3f/kWh (better than %d%% of similar periods, based on %d samples)',
            $avgPrice,
            100 - $percentileRank,
            (int)$sampleCount
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
