<?php

namespace App\Services\Charging\Prediction;

use Carbon\Carbon;

interface PredictionModelInterface
{
    /**
     * Get model name
     */
    public function getName(): string;

    /**
     * Predict price for a specific timestamp
     *
     * @param Carbon $timestamp
     * @param string $region
     * @return array ['price' => float, 'confidence_low' => float, 'confidence_high' => float, 'confidence_score' => float, 'metadata' => array]
     */
    public function predict(Carbon $timestamp, string $region): array;

    /**
     * Predict prices for a range of timestamps
     *
     * @param Carbon $start
     * @param Carbon $end
     * @param string $region
     * @return array Array of predictions
     */
    public function predictRange(Carbon $start, Carbon $end, string $region): array;

    /**
     * Train or update the model with new data
     *
     * @param string $region
     * @param int $lookbackDays
     * @return bool Success status
     */
    public function train(string $region, int $lookbackDays = 180): bool;

    /**
     * Get model metadata
     */
    public function getMetadata(): array;

    /**
     * Check if model is ready to make predictions
     */
    public function isReady(string $region): bool;
}
