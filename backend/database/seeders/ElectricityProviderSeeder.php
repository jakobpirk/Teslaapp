<?php

namespace Database\Seeders;

use App\Models\ElectricityProvider;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class ElectricityProviderSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $providers = [
            [
                'name' => 'gridpower_us',
                'display_name' => 'GridPower USA',
                'country' => 'US',
                'region' => 'California',
                'api_base_url' => 'https://api.gridpower.example.com',
                'description' => 'California\'s leading electricity provider with competitive time-of-use rates.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['off-peak', 'mid-peak', 'peak'],
                    'time_windows' => [
                        'off-peak' => ['00:00-06:00', '22:00-24:00'],
                        'mid-peak' => ['06:00-14:00', '20:00-22:00'],
                        'peak' => ['14:00-20:00'],
                    ],
                    'base_rates' => [
                        'off-peak' => 0.12,
                        'mid-peak' => 0.22,
                        'peak' => 0.35,
                    ],
                ],
            ],
            [
                'name' => 'ecoenergy_eu',
                'display_name' => 'EcoEnergy Europe',
                'country' => 'DE',
                'region' => 'Bavaria',
                'api_base_url' => 'https://api.ecoenergy.example.eu',
                'description' => 'Germany\'s renewable energy provider with dynamic pricing.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['low', 'standard', 'high'],
                    'time_windows' => [
                        'low' => ['01:00-05:00', '13:00-15:00'],
                        'standard' => ['05:00-13:00', '15:00-18:00', '21:00-01:00'],
                        'high' => ['18:00-21:00'],
                    ],
                    'base_rates' => [
                        'low' => 0.15,
                        'standard' => 0.28,
                        'high' => 0.42,
                    ],
                ],
            ],
            [
                'name' => 'powerplus_uk',
                'display_name' => 'PowerPlus UK',
                'country' => 'GB',
                'region' => 'London',
                'api_base_url' => 'https://api.powerplus.example.co.uk',
                'description' => 'UK\'s smart grid electricity provider with EV-optimized rates.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['overnight', 'day', 'evening'],
                    'time_windows' => [
                        'overnight' => ['00:30-04:30'],
                        'day' => ['04:30-16:00'],
                        'evening' => ['16:00-00:30'],
                    ],
                    'base_rates' => [
                        'overnight' => 0.09,
                        'day' => 0.20,
                        'evening' => 0.32,
                    ],
                ],
            ],
            [
                'name' => 'sunpower_au',
                'display_name' => 'SunPower Australia',
                'country' => 'AU',
                'region' => 'New South Wales',
                'api_base_url' => 'https://api.sunpower.example.com.au',
                'description' => 'Australia\'s solar-focused provider with feed-in tariffs.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['super-off-peak', 'off-peak', 'peak'],
                    'time_windows' => [
                        'super-off-peak' => ['01:00-06:00'],
                        'off-peak' => ['06:00-14:00', '20:00-01:00'],
                        'peak' => ['14:00-20:00'],
                    ],
                    'base_rates' => [
                        'super-off-peak' => 0.08,
                        'off-peak' => 0.18,
                        'peak' => 0.38,
                    ],
                ],
            ],
            [
                'name' => 'voltstream_ca',
                'display_name' => 'VoltStream Canada',
                'country' => 'CA',
                'region' => 'Ontario',
                'api_base_url' => 'https://api.voltstream.example.ca',
                'description' => 'Canadian electricity provider with ultra-low overnight rates.',
                'is_active' => true,
                'pricing_structure' => [
                    'rate_types' => ['ultra-low', 'mid', 'on-peak'],
                    'time_windows' => [
                        'ultra-low' => ['23:00-07:00'],
                        'mid' => ['07:00-11:00', '17:00-23:00'],
                        'on-peak' => ['11:00-17:00'],
                    ],
                    'base_rates' => [
                        'ultra-low' => 0.07,
                        'mid' => 0.15,
                        'on-peak' => 0.29,
                    ],
                ],
            ],
        ];

        foreach ($providers as $provider) {
            ElectricityProvider::create($provider);
        }
    }
}
