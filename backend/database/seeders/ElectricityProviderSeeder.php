<?php

namespace Database\Seeders;

use App\Models\ElectricityProvider;
use Illuminate\Database\Seeder;

class ElectricityProviderSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * Each provider is a company that supplies electricity.
     * The API base URL determines where to fetch pricing data from.
     */
    public function run(): void
    {
        $providers = [
            [
                'name' => 'pacific_gas_electric',
                'display_name' => 'Pacific Gas & Electric (PG&E)',
                'api_base_url' => 'https://api.pge.example.com',
                'description' => 'Major California utility company with time-of-use EV rates.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['off-peak', 'partial-peak', 'peak'],
                    'time_windows' => [
                        'off-peak' => ['00:00-06:00', '21:00-24:00'],
                        'partial-peak' => ['06:00-15:00', '19:00-21:00'],
                        'peak' => ['15:00-19:00'],
                    ],
                    'base_rates' => [
                        'off-peak' => 0.14,
                        'partial-peak' => 0.26,
                        'peak' => 0.42,
                    ],
                ],
            ],
            [
                'name' => 'southern_california_edison',
                'display_name' => 'Southern California Edison (SCE)',
                'api_base_url' => 'https://api.sce.example.com',
                'description' => 'Southern California utility with EV-specific TOU plans.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['super-off-peak', 'off-peak', 'mid-peak', 'on-peak'],
                    'time_windows' => [
                        'super-off-peak' => ['21:00-08:00'],
                        'off-peak' => ['08:00-12:00', '18:00-21:00'],
                        'mid-peak' => ['12:00-16:00'],
                        'on-peak' => ['16:00-18:00'],
                    ],
                    'base_rates' => [
                        'super-off-peak' => 0.11,
                        'off-peak' => 0.19,
                        'mid-peak' => 0.28,
                        'on-peak' => 0.39,
                    ],
                ],
            ],
            [
                'name' => 'texas_power_grid',
                'display_name' => 'Texas Power Grid',
                'api_base_url' => 'https://api.texaspower.example.com',
                'description' => 'Competitive Texas retailer with free overnight charging.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['free-nights', 'standard'],
                    'time_windows' => [
                        'free-nights' => ['21:00-06:00'],
                        'standard' => ['06:00-21:00'],
                    ],
                    'base_rates' => [
                        'free-nights' => 0.00,
                        'standard' => 0.13,
                    ],
                ],
            ],
            [
                'name' => 'octopus_energy',
                'display_name' => 'Octopus Energy',
                'api_base_url' => 'https://api.octopus.example.co.uk',
                'description' => 'Innovative UK energy company with Agile Octopus and EV-specific tariffs.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['super-off-peak', 'off-peak', 'peak'],
                    'time_windows' => [
                        'super-off-peak' => ['02:30-05:30'],
                        'off-peak' => ['00:00-02:30', '05:30-16:00', '19:00-24:00'],
                        'peak' => ['16:00-19:00'],
                    ],
                    'base_rates' => [
                        'super-off-peak' => 0.075,
                        'off-peak' => 0.15,
                        'peak' => 0.31,
                    ],
                ],
            ],
            [
                'name' => 'british_gas',
                'display_name' => 'British Gas',
                'api_base_url' => 'https://api.britishgas.example.co.uk',
                'description' => 'UK\'s largest energy supplier with Electric Driver tariff for EV owners.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['night', 'day'],
                    'time_windows' => [
                        'night' => ['00:00-05:00'],
                        'day' => ['05:00-24:00'],
                    ],
                    'base_rates' => [
                        'night' => 0.09,
                        'day' => 0.22,
                    ],
                ],
            ],
            [
                'name' => 'eon_energie',
                'display_name' => 'E.ON Energie',
                'api_base_url' => 'https://api.eon.example.de',
                'description' => 'German energy provider with renewable energy focus and smart charging rates.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['night', 'standard', 'peak'],
                    'time_windows' => [
                        'night' => ['22:00-06:00'],
                        'standard' => ['06:00-17:00', '20:00-22:00'],
                        'peak' => ['17:00-20:00'],
                    ],
                    'base_rates' => [
                        'night' => 0.18,
                        'standard' => 0.32,
                        'peak' => 0.45,
                    ],
                ],
            ],
            [
                'name' => 'origin_energy',
                'display_name' => 'Origin Energy',
                'api_base_url' => 'https://api.origin.example.com.au',
                'description' => 'Australian energy retailer with EV Saver plan and solar integration.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['overnight', 'shoulder', 'peak'],
                    'time_windows' => [
                        'overnight' => ['22:00-07:00'],
                        'shoulder' => ['07:00-14:00', '20:00-22:00'],
                        'peak' => ['14:00-20:00'],
                    ],
                    'base_rates' => [
                        'overnight' => 0.08,
                        'shoulder' => 0.20,
                        'peak' => 0.44,
                    ],
                ],
            ],
            [
                'name' => 'toronto_hydro',
                'display_name' => 'Toronto Hydro',
                'api_base_url' => 'https://api.torontohydro.example.ca',
                'description' => 'Toronto\'s electricity distributor with ultra-low overnight rates for EV charging.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['ultra-low-overnight', 'mid-peak', 'on-peak'],
                    'time_windows' => [
                        'ultra-low-overnight' => ['19:00-07:00'],
                        'mid-peak' => ['07:00-11:00', '17:00-19:00'],
                        'on-peak' => ['11:00-17:00'],
                    ],
                    'base_rates' => [
                        'ultra-low-overnight' => 0.065,
                        'mid-peak' => 0.13,
                        'on-peak' => 0.23,
                    ],
                ],
            ],
        ];

        foreach ($providers as $provider) {
            ElectricityProvider::create($provider);
        }
    }
}
