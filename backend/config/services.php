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

    'tessie' => [
        'base_url' => 'https://api.tessie.com',
        // API key is per-user, stored in users table
    ],
];
