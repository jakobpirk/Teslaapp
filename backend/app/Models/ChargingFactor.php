<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChargingFactor extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'charging_factors';

    protected $fillable = [
        'name',
        'display_name',
        'description',
        'weight',
        'is_enabled',
        'unit',
        'data_type',
        'configuration',
    ];

    protected $casts = [
        'weight' => 'float',
        'is_enabled' => 'boolean',
        'configuration' => 'array',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get the factor values for this factor
     */
    public function values(): HasMany
    {
        return $this->hasMany(ChargingFactorValue::class);
    }

    /**
     * Get only enabled factors
     */
    public static function getEnabled()
    {
        return static::where('is_enabled', true)->get();
    }

    /**
     * Get factor by name
     */
    public static function getByName(string $name)
    {
        return static::where('name', $name)->first();
    }
}
