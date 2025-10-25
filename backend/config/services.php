<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'weatherapi' => [
        'key' => env('WEATHERAPI_KEY'),
        'base_url' => 'https://api.weatherapi.com/v1',
    ],

    'energinet' => [
        'base_url' => 'https://api.energidataservice.dk',
        // No API key needed (public API)
    ],

    // Vehicle API Providers Configuration
    'vehicle_api' => [
        'default_provider' => env('DEFAULT_VEHICLE_API_PROVIDER', 'tessie'),

        'providers' => [
            'tessie' => [
                'base_url' => env('TESSIE_API_BASE_URL', 'https://api.tessie.com'),
                'timeout' => 30,
                // API key is per-user, stored in users table
            ],

            'tesla' => [
                'base_url' => env('TESLA_API_BASE_URL', 'https://owner-api.teslamotors.com'),
                'timeout' => 30,
                // API key is per-user, stored in users table
                // Note: Tesla official API may require OAuth tokens
            ],

            // Add more providers here as needed
            // 'nio' => [
            //     'base_url' => env('NIO_API_BASE_URL'),
            //     'timeout' => 30,
            // ],
        ],
    ],

    // Legacy Tessie configuration (kept for backwards compatibility)
    'tessie' => [
        'base_url' => 'https://api.tessie.com',
        // API key is per-user, stored in users table
    ],
];
