# Multi-Provider Vehicle API Architecture

This document describes the multi-provider vehicle API architecture that allows the application to support multiple vehicle data providers (Tessie, Tesla official API, and potentially others).

## Overview

The application now supports multiple vehicle API providers through a pluggable architecture. This allows users to choose their preferred provider when adding a vehicle to the system.

### Supported Providers

- **Tessie** (`tessie`) - Fully implemented and tested
- **Tesla** (`tesla`) - Stub implementation (requires OAuth implementation)
- **Future providers** - Easy to add (NIO, XPeng, etc.)

## Architecture

### Core Components

#### 1. VehicleApiProviderContract Interface

Location: `app/Contracts/VehicleApiProviderContract.php`

Defines the standard interface that all vehicle API providers must implement:

```php
interface VehicleApiProviderContract
{
    public function getVehicleState(string $vehicleId, string $apiKey): array;
    public function startCharging(string $vehicleId, string $apiKey): array;
    public function stopCharging(string $vehicleId, string $apiKey): array;
    public function setChargeLimit(string $vehicleId, string $apiKey, int $limit): array;
    public function getProviderName(): string;
    public function validateApiKey(string $apiKey): bool;
}
```

#### 2. Provider Implementations

Location: `app/Services/Providers/`

Each provider implements the `VehicleApiProviderContract`:

- `TessieApiProvider.php` - Fully functional Tessie API implementation
- `TeslaApiProvider.php` - Stub implementation for Tesla official API

#### 3. VehicleApiProviderFactory

Location: `app/Services/VehicleApiProviderFactory.php`

Factory class that creates and manages provider instances:

```php
// Get a provider instance
$provider = VehicleApiProviderFactory::make('tessie');

// Check if a provider is supported
if (VehicleApiProviderFactory::isSupported('tesla')) {
    // ...
}

// Get all supported providers
$providers = VehicleApiProviderFactory::getSupportedProviders();
```

#### 4. Database Schema

The `vehicles` table has been updated with:

- `api_provider` - The provider name (e.g., 'tessie', 'tesla')
- `provider_vehicle_id` - The provider-specific vehicle identifier
- Unique constraint on `(provider_vehicle_id, api_provider)` combination

Migration: `database/migrations/2025_10_25_000001_add_multi_provider_support_to_vehicles_table.php`

#### 5. Vehicle Model Updates

Location: `app/Models/Vehicle.php`

New helper methods:

```php
$vehicle->usesProvider('tessie');  // Check provider
$vehicle->usesTessie();            // Convenience method
$vehicle->usesTesla();             // Convenience method
$vehicle->getProviderApiKey();     // Get API key from user
```

New scope:

```php
Vehicle::byProvider('tessie')->get();  // Filter by provider
```

## Usage

### Adding a Vehicle with a Specific Provider

**API Endpoint**: `POST /api/vehicles`

**Request Body**:
```json
{
  "api_provider": "tessie",
  "provider_vehicle_id": "1234567890",
  "display_name": "My Tesla Model 3",
  "vin": "5YJ3E1EA1JF000001",
  "model": "Model 3",
  "battery_capacity": 75.0
}
```

**Required Fields**:
- `api_provider` - Must be one of the supported providers ('tessie', 'tesla')
- `provider_vehicle_id` - The vehicle ID from the provider's system

### Service Layer Usage

The `ChargingEvaluationService` automatically uses the correct provider:

```php
// The service automatically detects the vehicle's provider
$result = $chargingEvaluationService->evaluateAndExecute($vehicle, $user);
```

Internally, it:
1. Gets the provider from `$vehicle->api_provider`
2. Creates the appropriate provider instance using the factory
3. Calls provider methods with the correct credentials

## Adding a New Provider

To add support for a new vehicle API provider:

### 1. Create Provider Implementation

Create a new class in `app/Services/Providers/`:

```php
<?php

namespace App\Services\Providers;

use App\Contracts\VehicleApiProviderContract;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NioApiProvider implements VehicleApiProviderContract
{
    private const BASE_URL = 'https://api.nio.com';
    private const TIMEOUT = 30;
    private const PROVIDER_NAME = 'nio';

    public function getVehicleState(string $vehicleId, string $apiKey): array
    {
        // Implement NIO API vehicle state retrieval
        $response = Http::timeout(self::TIMEOUT)
            ->withHeaders(['Authorization' => 'Bearer ' . $apiKey])
            ->get(self::BASE_URL . '/vehicles/' . $vehicleId . '/state');

        // Parse and return normalized data
        return [
            'battery_level' => ...,
            'battery_range' => ...,
            'charging_state' => ...,
            // ... etc
        ];
    }

    public function startCharging(string $vehicleId, string $apiKey): array
    {
        // Implement start charging
    }

    public function stopCharging(string $vehicleId, string $apiKey): array
    {
        // Implement stop charging
    }

    public function setChargeLimit(string $vehicleId, string $apiKey, int $limit): array
    {
        // Implement set charge limit
    }

    public function getProviderName(): string
    {
        return self::PROVIDER_NAME;
    }

    public function validateApiKey(string $apiKey): bool
    {
        // Implement API key validation
    }
}
```

### 2. Register Provider in Factory

Update `app/Services/VehicleApiProviderFactory.php`:

```php
use App\Services\Providers\NioApiProvider;

class VehicleApiProviderFactory
{
    public const PROVIDER_NIO = 'nio';

    private static array $providers = [
        self::PROVIDER_TESSIE => TessieApiProvider::class,
        self::PROVIDER_TESLA => TeslaApiProvider::class,
        self::PROVIDER_NIO => NioApiProvider::class,  // Add this line
    ];
}
```

### 3. Update Configuration

Add provider config in `config/services.php`:

```php
'vehicle_api' => [
    'providers' => [
        'nio' => [
            'base_url' => env('NIO_API_BASE_URL', 'https://api.nio.com'),
            'timeout' => 30,
        ],
    ],
],
```

### 4. Update User Model (if needed)

If the provider requires a specific API key field in the users table:

```php
// Add migration for nio_api_key field
Schema::table('users', function (Blueprint $table) {
    $table->string('nio_api_key')->nullable();
});

// Add to User model
protected $fillable = [
    // ...
    'nio_api_key',
];

protected $hidden = [
    // ...
    'nio_api_key',
];

public function hasNioApiKey(): bool
{
    return !empty($this->nio_api_key);
}
```

### 5. Update Vehicle Model

Add provider key mapping in `Vehicle::getProviderApiKey()`:

```php
$keyMap = [
    'tessie' => 'tessie_api_key',
    'tesla' => 'tesla_api_key',
    'nio' => 'nio_api_key',  // Add this line
];
```

### 6. Update Controller Validation

Update the validation rule in `VehicleController::store()`:

```php
'api_provider' => 'required|string|in:tessie,tesla,nio',  // Add 'nio'
```

## Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Default provider for new vehicles (if not specified)
DEFAULT_VEHICLE_API_PROVIDER=tessie

# Provider-specific configurations
TESSIE_API_BASE_URL=https://api.tessie.com
TESLA_API_BASE_URL=https://owner-api.teslamotors.com
# NIO_API_BASE_URL=https://api.nio.com
```

### Provider Configuration

Edit `config/services.php` to customize provider settings:

```php
'vehicle_api' => [
    'default_provider' => env('DEFAULT_VEHICLE_API_PROVIDER', 'tessie'),

    'providers' => [
        'tessie' => [
            'base_url' => env('TESSIE_API_BASE_URL', 'https://api.tessie.com'),
            'timeout' => 30,
        ],
        // Add more providers...
    ],
],
```

## Migration Guide

### Migrating Existing Vehicles

If you have existing vehicles in the database with `tessie_vehicle_id`, run the migration:

```bash
php artisan migrate
```

This will:
1. Add the `api_provider` field (defaulting to 'tessie' for existing records)
2. Rename `tessie_vehicle_id` to `provider_vehicle_id`
3. Update the unique constraint

### Backwards Compatibility

The migration is designed to be backwards compatible:
- Existing vehicles will automatically be set to use the 'tessie' provider
- The `TessieService` class is still available for legacy code
- Vehicle IDs are preserved during the rename

## Testing

### Testing a Provider Implementation

```php
use App\Services\VehicleApiProviderFactory;

// Get provider instance
$provider = VehicleApiProviderFactory::make('tessie');

// Test vehicle state retrieval
$state = $provider->getVehicleState('vehicle_id_123', 'api_key_here');

// Test charging commands
$provider->startCharging('vehicle_id_123', 'api_key_here');
$provider->stopCharging('vehicle_id_123', 'api_key_here');
$provider->setChargeLimit('vehicle_id_123', 'api_key_here', 80);
```

### Unit Testing

Create provider-specific tests in `tests/Unit/Services/Providers/`:

```php
class TessieApiProviderTest extends TestCase
{
    public function test_get_vehicle_state()
    {
        $provider = new TessieApiProvider();

        // Mock HTTP responses
        Http::fake([
            'api.tessie.com/*' => Http::response([...], 200),
        ]);

        $state = $provider->getVehicleState('test_id', 'test_key');

        $this->assertArrayHasKey('battery_level', $state);
        // ... more assertions
    }
}
```

## Error Handling

All provider methods throw exceptions on failure:

```php
try {
    $provider = VehicleApiProviderFactory::make($vehicle->api_provider);
    $state = $provider->getVehicleState($vehicleId, $apiKey);
} catch (\InvalidArgumentException $e) {
    // Unsupported provider
    Log::error('Unsupported provider: ' . $e->getMessage());
} catch (\Exception $e) {
    // API call failed
    Log::error('Provider API error: ' . $e->getMessage());
}
```

## Best Practices

1. **Normalize Response Data**: All providers should return data in the same format
2. **Handle Rate Limits**: Implement appropriate rate limiting for each provider
3. **Secure API Keys**: Never log or expose API keys in error messages
4. **Validate Input**: Always validate vehicle IDs and charge limits
5. **Graceful Degradation**: Handle provider unavailability gracefully
6. **Logging**: Log all provider interactions for debugging and monitoring

## Troubleshooting

### Provider Not Found

```
Unsupported vehicle API provider: xyz
```

**Solution**: Check that the provider is registered in `VehicleApiProviderFactory::$providers`

### API Key Not Configured

```
API key not configured for vehicle provider
```

**Solution**: Ensure the user has the appropriate API key field set in the database

### Migration Issues

If the migration fails on the column rename:

```bash
# Rollback the migration
php artisan migrate:rollback

# Check your database schema
php artisan db:show

# Re-run the migration
php artisan migrate
```

## Future Enhancements

Potential improvements to the multi-provider architecture:

1. **Provider Auto-Discovery**: Automatically detect available providers
2. **Provider Health Checks**: Monitor provider availability and performance
3. **Fallback Providers**: Use alternative providers if primary fails
4. **Provider Metrics**: Track usage statistics per provider
5. **Rate Limit Management**: Global rate limiting across all providers
6. **OAuth Integration**: Built-in OAuth flow for providers like Tesla

## Resources

- [Tessie API Documentation](https://developer.tessie.com/)
- [Tesla Unofficial API Documentation](https://tesla-api.timdorr.com/)
- [Tesla Official Developer Portal](https://developer.tesla.com/)

## Support

For issues or questions about the multi-provider architecture, please:
1. Check this documentation
2. Review the code examples in `app/Services/Providers/`
3. Check the migration files for database schema changes
4. Open an issue in the project repository
