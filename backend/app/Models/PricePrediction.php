<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PricePrediction extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'price_predictions';

    protected $fillable = [
        'region',
        'prediction_model',
        'predicted_for_timestamp',
        'predicted_price',
        'confidence_interval_low',
        'confidence_interval_high',
        'confidence_score',
        'prediction_metadata',
        'actual_price',
        'prediction_error',
        'prediction_error_percent',
        'predicted_at',
    ];

    protected $casts = [
        'predicted_for_timestamp' => 'datetime',
        'predicted_price' => 'float',
        'confidence_interval_low' => 'float',
        'confidence_interval_high' => 'float',
        'confidence_score' => 'float',
        'prediction_metadata' => 'array',
        'actual_price' => 'float',
        'prediction_error' => 'float',
        'prediction_error_percent' => 'float',
        'predicted_at' => 'datetime',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get latest prediction for a specific timestamp and region
     */
    public static function getLatestPrediction(string $region, \DateTime $timestamp, ?string $model = null)
    {
        $query = static::where('region', $region)
            ->where('predicted_for_timestamp', $timestamp)
            ->orderBy('predicted_at', 'desc');

        if ($model) {
            $query->where('prediction_model', $model);
        }

        return $query->first();
    }

    /**
     * Get predictions for a time range
     */
    public static function getPredictionsForRange(string $region, \DateTime $start, \DateTime $end, ?string $model = null)
    {
        $query = static::where('region', $region)
            ->whereBetween('predicted_for_timestamp', [$start, $end])
            ->orderBy('predicted_for_timestamp');

        if ($model) {
            $query->where('prediction_model', $model);
        }

        return $query->get();
    }

    /**
     * Fill in actual price and calculate error
     */
    public function recordActual(float $actualPrice): void
    {
        $error = abs($this->predicted_price - $actualPrice);
        $errorPercent = ($error / $actualPrice) * 100;

        $this->update([
            'actual_price' => $actualPrice,
            'prediction_error' => $error,
            'prediction_error_percent' => $errorPercent,
        ]);
    }

    /**
     * Check if prediction was accurate within tolerance
     */
    public function isAccurate(float $tolerancePercent = 10.0): bool
    {
        return $this->actual_price !== null
            && $this->prediction_error_percent <= $tolerancePercent;
    }

    /**
     * Get prediction interval width (uncertainty measure)
     */
    public function getUncertainty(): float
    {
        return $this->confidence_interval_high - $this->confidence_interval_low;
    }

    /**
     * Check if actual price fell within confidence interval
     */
    public function withinConfidenceInterval(): ?bool
    {
        if ($this->actual_price === null) {
            return null;
        }

        return $this->actual_price >= $this->confidence_interval_low
            && $this->actual_price <= $this->confidence_interval_high;
    }
}
