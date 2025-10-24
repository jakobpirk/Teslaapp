<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ElectricityProvider extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'name',
        'display_name',
        'country',
        'region',
        'api_base_url',
        'description',
        'is_active',
        'pricing_structure',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'pricing_structure' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the users who have selected this provider.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'electricity_provider_id');
    }

    /**
     * Scope to get only active providers.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to filter by country.
     */
    public function scopeByCountry($query, string $country)
    {
        return $query->where('country', $country);
    }
}
