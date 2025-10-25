<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChargingFactorValue extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'charging_factor_values';

    protected $fillable = [
        'charging_factor_id',
        'timestamp',
        'value',
        'value_text',
        'value_boolean',
        'metadata',
    ];

    protected $casts = [
        'timestamp' => 'datetime',
        'value' => 'float',
        'value_boolean' => 'boolean',
        'metadata' => 'array',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get the factor this value belongs to
     */
    public function chargingFactor(): BelongsTo
    {
        return $this->belongsTo(ChargingFactor::class);
    }

    /**
     * Get the actual value based on data type
     */
    public function getActualValue()
    {
        $factor = $this->chargingFactor;

        if (!$factor) {
            return $this->value;
        }

        return match ($factor->data_type) {
            'boolean' => $this->value_boolean,
            'categorical' => $this->value_text,
            default => $this->value,
        };
    }

    /**
     * Get values for a specific factor and time range
     */
    public static function getForFactorAndTimeRange($factorId, $startTime, $endTime)
    {
        return static::where('charging_factor_id', $factorId)
            ->whereBetween('timestamp', [$startTime, $endTime])
            ->orderBy('timestamp')
            ->get();
    }
}
