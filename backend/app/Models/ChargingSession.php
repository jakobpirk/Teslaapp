<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChargingSession extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'charging_sessions';

    protected $fillable = [
        'vehicle_id',
        'start_time',
        'end_time',
        'energy_added',
        'cost',
        'charge_rate',
        'start_battery_level',
        'end_battery_level',
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'energy_added' => 'float',
        'cost' => 'float',
        'charge_rate' => 'float',
        'start_battery_level' => 'integer',
        'end_battery_level' => 'integer',
    ];

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get the vehicle that owns this charging session.
     */
    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    /**
     * Get the user who owns the vehicle (via vehicle relationship).
     */
    public function user(): BelongsTo
    {
        return $this->vehicle->user();
    }
}
