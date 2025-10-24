<?php

namespace Database\Seeders;

use App\Models\ChargingFactor;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class ChargingFactorSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $factors = [
            [
                'id' => Str::uuid(),
                'name' => 'price',
                'display_name' => 'Electricity Price',
                'description' => 'Cost per kilowatt-hour of electricity',
                'weight' => 1.00,
                'is_enabled' => true,
                'unit' => '$/kWh',
                'data_type' => 'numeric',
                'configuration' => [
                    'optimization_goal' => 'minimize',
                    'threshold_low' => 0.10,
                    'threshold_high' => 0.30,
                ],
            ],
            [
                'id' => Str::uuid(),
                'name' => 'weather',
                'display_name' => 'Weather Conditions',
                'description' => 'Temperature and weather impact on charging efficiency',
                'weight' => 0.30,
                'is_enabled' => false, // Not implemented yet
                'unit' => '°C',
                'data_type' => 'numeric',
                'configuration' => [
                    'optimization_goal' => 'moderate',
                    'optimal_range' => [15, 25],
                ],
            ],
            [
                'id' => Str::uuid(),
                'name' => 'carbon_intensity',
                'display_name' => 'Grid Carbon Intensity',
                'description' => 'Carbon emissions per kWh from the grid',
                'weight' => 0.50,
                'is_enabled' => false, // Not implemented yet
                'unit' => 'gCO2/kWh',
                'data_type' => 'numeric',
                'configuration' => [
                    'optimization_goal' => 'minimize',
                ],
            ],
            [
                'id' => Str::uuid(),
                'name' => 'grid_demand',
                'display_name' => 'Grid Demand',
                'description' => 'Current demand on the electrical grid',
                'weight' => 0.40,
                'is_enabled' => false, // Not implemented yet
                'unit' => 'MW',
                'data_type' => 'numeric',
                'configuration' => [
                    'optimization_goal' => 'minimize',
                ],
            ],
        ];

        foreach ($factors as $factor) {
            ChargingFactor::updateOrCreate(
                ['name' => $factor['name']],
                $factor
            );
        }
    }
}
