<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Charging Optimization Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for advanced charging strategy optimization including
    | historic price analysis, ML predictions, and multi-factor optimization.
    |
    */

    'historic_analysis' => [
        // How many days of historic data to analyze (6 months = 180 days)
        'lookback_days' => env('OPTIMIZATION_LOOKBACK_DAYS', 180),

        // Minimum number of data points required to build a pattern
        'min_sample_size' => 30,

        // How often to rebuild historic models
        'rebuild_frequency' => 'daily', // daily, weekly, monthly

        // Cache TTL for historic statistics (in seconds)
        'cache_ttl' => 86400, // 24 hours
    ],

    'prediction' => [
        // Prediction models configuration
        'models' => [
            'holt_winters' => [
                'enabled' => true,
                'alpha' => 0.3,  // Level smoothing parameter
                'beta' => 0.1,   // Trend smoothing parameter
                'gamma' => 0.2,  // Seasonal smoothing parameter
                'season_period' => 168, // Weekly seasonality (168 hours)
            ],
            'pattern_based' => [
                'enabled' => true,
                'similar_days_count' => 4,  // Number of similar days to analyze
                'recency_weight' => 0.7,    // Weight decay for older data
            ],
            'ensemble' => [
                'enabled' => true,
                'auto_select_best' => true, // Automatically use best performing model
            ],
        ],

        // Minimum confidence threshold for using predictions
        'confidence_threshold' => 0.6,

        // How often to update predictions (in hours)
        'update_frequency' => 6,

        // Cache TTL for predictions (in seconds)
        'cache_ttl' => 21600, // 6 hours

        // How long to keep old predictions in database (days)
        'cleanup_after_days' => 90,
    ],

    'factors' => [
        // Base weights for each optimization factor (must sum to 1.0)
        'base_weights' => [
            'price' => 0.40,              // 40% weight on electricity price
            'historic_pattern' => 0.20,   // 20% weight on historic patterns
            'weather' => 0.20,            // 20% weight on weather conditions
            'carbon_intensity' => 0.20,   // 20% weight on grid carbon intensity
        ],

        // Automatically adjust weights based on factor performance
        'auto_adjust_weights' => true,

        // Days of performance data to analyze for weight adjustment
        'performance_lookback_days' => 30,

        // Minimum confidence required for a factor to be used
        'min_factor_confidence' => 0.3,
    ],

    'weather' => [
        // Weather API provider
        'provider' => 'weatherapi',

        // API key (set in .env as WEATHERAPI_KEY)
        'api_key' => env('WEATHERAPI_KEY'),

        // Base URL for WeatherAPI.com
        'base_url' => 'https://api.weatherapi.com/v1',

        // Cache TTL for weather forecasts (in seconds)
        'cache_ttl' => 3600, // 1 hour

        // How many hours ahead to fetch forecasts
        'forecast_hours' => 72,

        // Default location (Copenhagen, Denmark)
        'default_location' => [
            'latitude' => 55.6761,
            'longitude' => 12.5683,
        ],

        // Temperature ranges for scoring
        'optimal_temp_c' => 17.5,    // Optimal temperature (low HVAC demand)
        'temp_score_decay' => 3.0,   // Score reduction per degree from optimal

        // Wind scoring
        'wind_score_multiplier' => 2.5, // Converts km/h to score (0-100)
    ],

    'carbon_intensity' => [
        // Carbon intensity provider for Denmark
        'provider' => 'energinet',

        // Base URL for Energinet API
        'base_url' => 'https://api.energidataservice.dk',

        // No API key needed for Energinet (public API)

        // Cache TTL for carbon data (in seconds)
        'cache_ttl' => 1800, // 30 minutes

        // Danish grid zone (DK1 = West Denmark, DK2 = East Denmark)
        'default_zone' => env('CARBON_ZONE', 'DK1'),

        // CO2 ranges for scoring (gCO2/kWh)
        'min_co2' => 50,   // Very clean (high renewables)
        'max_co2' => 400,  // Very dirty (coal/gas heavy)

        // Renewable percentage threshold for "clean" classification
        'clean_threshold' => 70, // 70% or more renewables
    ],

    'optimization' => [
        // Current optimization algorithm version
        'version' => 'v2_multi_factor',

        // Typical charging duration (hours)
        'typical_charging_hours' => 4,

        // How far ahead to look for optimal windows (hours)
        'look_ahead_hours' => 48,

        // Decision thresholds
        'charge_now_if_optimal_within_hours' => 2,   // Start charging if optimal window is within 2h
        'charge_now_if_score_within_percent' => 10,  // Start if current score within 10% of optimal
        'min_time_buffer_hours' => 2,                // Minimum time buffer before required_by

        // Risk assessment
        'battery_risk_threshold' => 30,  // Battery % below which risk increases
        'high_risk_score_threshold' => 50,

        // Performance tracking
        'track_optimization_decisions' => true,
        'track_performance_metrics' => true,
    ],

    'api' => [
        // Rate limiting for external APIs
        'rate_limit' => [
            'weather' => 100,   // Requests per hour
            'carbon' => 100,     // Requests per hour
        ],

        // Timeouts (seconds)
        'timeout' => [
            'weather' => 10,
            'carbon' => 15,
        ],

        // Retry configuration
        'retry' => [
            'max_attempts' => 3,
            'delay_ms' => 1000,  // Initial delay
            'multiplier' => 2,   // Exponential backoff multiplier
        ],
    ],

    'caching' => [
        // Cache driver to use (redis, memcached, file)
        'driver' => env('CACHE_DRIVER', 'file'),

        // Cache key prefix
        'prefix' => 'charging_opt_',

        // Enable aggressive caching for performance
        'aggressive_caching' => true,
    ],

    'logging' => [
        // Log level for optimization events
        'level' => env('OPTIMIZATION_LOG_LEVEL', 'info'),

        // Log channel
        'channel' => env('LOG_CHANNEL', 'stack'),

        // Log optimization decisions
        'log_decisions' => true,

        // Log factor scores
        'log_factor_scores' => false, // Set to true for debugging

        // Log performance metrics
        'log_performance' => true,
    ],

    'features' => [
        // Feature flags for gradual rollout
        'enable_historic_analysis' => true,
        'enable_ml_predictions' => true,
        'enable_weather_factor' => true,
        'enable_carbon_factor' => true,
        'enable_automatic_weight_adjustment' => true,
        'enable_performance_tracking' => true,

        // A/B testing (future use)
        'ab_test_percentage' => 0, // % of users to use new algorithm
    ],
];
