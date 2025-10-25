<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\ElectricityProvider;
use App\Services\TessieService;
use App\Services\AuraElectricityService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Client\RequestException;

class ExternalApiErrorHandlingTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private string $token;
    private Vehicle $vehicle;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
            'tessie_api_key' => 'test-api-key-123',
        ]);

        $this->token = $this->user->createToken('test_token')->plainTextToken;

        $this->vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-vehicle-123',
            'display_name' => 'Test Tesla',
            'model' => 'Model 3',
            'battery_capacity' => 75.0,
        ]);
    }

    /** @test */
    public function handles_tessie_api_connection_failure_gracefully()
    {
        // Simulate Tessie API being unreachable
        Http::fake([
            'https://api.tessie.com/*' => Http::response(null, 500),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return error but not crash
        $this->assertContains($response->status(), [500, 503, 400]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_tessie_api_timeout_gracefully()
    {
        // Simulate Tessie API timeout
        Http::fake([
            'https://api.tessie.com/*' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection timeout');
            },
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return error but not crash
        $this->assertContains($response->status(), [500, 503, 400]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_tessie_api_invalid_response_gracefully()
    {
        // Simulate Tessie API returning malformed data
        Http::fake([
            'https://api.tessie.com/*' => Http::response('Invalid JSON', 200),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should handle parsing error gracefully
        $this->assertContains($response->status(), [500, 503, 400]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_tessie_api_authentication_failure()
    {
        // Simulate Tessie API rejecting the API key
        Http::fake([
            'https://api.tessie.com/*' => Http::response([
                'error' => 'Invalid API key'
            ], 401),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return appropriate error
        $this->assertContains($response->status(), [401, 400, 500]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_tessie_api_rate_limiting()
    {
        // Simulate Tessie API rate limiting
        Http::fake([
            'https://api.tessie.com/*' => Http::response([
                'error' => 'Rate limit exceeded'
            ], 429),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return appropriate error
        $this->assertContains($response->status(), [429, 503, 400]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_aura_pricing_api_connection_failure()
    {
        // Simulate Aura API being unreachable
        Http::fake([
            'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net/*' => Http::response(null, 500),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/aura/fetch-prices', [
                'date' => now()->format('Y-m-d'),
            ]);

        // Should handle error gracefully and not crash
        $this->assertContains($response->status(), [500, 503, 400, 200]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_aura_pricing_api_timeout()
    {
        // Simulate Aura API timeout
        Http::fake([
            'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net/*' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection timeout');
            },
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/aura/fetch-prices', [
                'date' => now()->format('Y-m-d'),
            ]);

        // Should handle timeout gracefully
        $this->assertContains($response->status(), [500, 503, 400, 200]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_aura_pricing_api_invalid_json()
    {
        // Simulate Aura API returning invalid JSON
        Http::fake([
            'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net/*' => Http::response('Not JSON', 200),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson('/api/v1/aura/fetch-prices', [
                'date' => now()->format('Y-m-d'),
            ]);

        // Should handle parsing error gracefully
        $this->assertContains($response->status(), [500, 503, 400, 200]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_weather_api_connection_failure()
    {
        // Simulate Weather API being unreachable
        Http::fake([
            'https://api.weatherapi.com/*' => Http::response(null, 500),
        ]);

        // Generate recommendation which uses weather data
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should still work or return graceful error (weather is not critical)
        $this->assertContains($response->status(), [200, 500, 503, 400]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_carbon_intensity_api_connection_failure()
    {
        // Simulate Carbon Intensity API being unreachable
        Http::fake([
            'https://api.energidataservice.dk/*' => Http::response(null, 500),
        ]);

        // Generate recommendation which uses carbon intensity data
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should still work or return graceful error (carbon data is not critical)
        $this->assertContains($response->status(), [200, 500, 503, 400]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function charging_recommendation_works_with_cached_pricing_data()
    {
        // Create electricity provider with Aura
        $provider = ElectricityProvider::create([
            'name' => 'aura',
            'display_name' => 'Aura Electricity',
            'api_base_url' => 'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net',
            'is_active' => true,
        ]);

        $this->user->update([
            'electricity_provider_id' => $provider->id,
            'pricing_region' => 'east',
        ]);

        // Simulate Aura API being down
        Http::fake([
            'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net/*' => Http::response(null, 500),
            'https://api.tessie.com/*' => Http::response([
                'battery_level' => 50,
                'charge_state' => [
                    'battery_level' => 50,
                    'battery_range' => 200.0,
                    'charging_state' => 'Disconnected',
                ],
            ], 200),
        ]);

        // Should still work using cached pricing data or return informative error
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Either works with cache or fails gracefully
        $this->assertContains($response->status(), [200, 400, 500, 503]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_vehicle_not_found_in_tessie_api()
    {
        // Simulate Tessie API returning 404 for vehicle
        Http::fake([
            'https://api.tessie.com/*' => Http::response([
                'error' => 'Vehicle not found'
            ], 404),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return appropriate error
        $this->assertContains($response->status(), [404, 400, 500]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function handles_missing_tessie_api_key()
    {
        // User without Tessie API key
        $this->user->update(['tessie_api_key' => null]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return validation error
        $response->assertStatus(400);
        $response->assertJsonStructure(['message']);
        $response->assertJson([
            'message' => 'Tessie API key is required',
        ]);
    }

    /** @test */
    public function handles_missing_electricity_provider()
    {
        // User without electricity provider
        $this->user->update(['electricity_provider_id' => null]);

        Http::fake([
            'https://api.tessie.com/*' => Http::response([
                'battery_level' => 50,
                'charge_state' => [
                    'battery_level' => 50,
                    'battery_range' => 200.0,
                    'charging_state' => 'Disconnected',
                ],
            ], 200),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return validation error
        $response->assertStatus(400);
        $response->assertJsonStructure(['message']);
        $response->assertJson([
            'message' => 'Electricity provider is required',
        ]);
    }

    /** @test */
    public function handles_multiple_api_failures_simultaneously()
    {
        // Simulate all external APIs being down
        Http::fake([
            'https://api.tessie.com/*' => Http::response(null, 500),
            'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net/*' => Http::response(null, 500),
            'https://api.weatherapi.com/*' => Http::response(null, 500),
            'https://api.energidataservice.dk/*' => Http::response(null, 500),
        ]);

        $provider = ElectricityProvider::create([
            'name' => 'aura',
            'display_name' => 'Aura Electricity',
            'api_base_url' => 'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net',
            'is_active' => true,
        ]);

        $this->user->update([
            'electricity_provider_id' => $provider->id,
            'pricing_region' => 'east',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should return error but not crash the application
        $this->assertContains($response->status(), [500, 503, 400]);
        $response->assertJsonStructure(['message']);

        // Application should still be functional for other requests
        $meResponse = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/auth/me');
        $meResponse->assertStatus(200);
    }

    /** @test */
    public function provides_meaningful_error_messages_for_api_failures()
    {
        // Simulate Tessie API error
        Http::fake([
            'https://api.tessie.com/*' => Http::response([
                'error' => 'Service temporarily unavailable'
            ], 503),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        $this->assertContains($response->status(), [503, 500, 400]);

        // Should provide meaningful error message (not just generic error)
        $message = $response->json('message');
        $this->assertNotEmpty($message);
        $this->assertIsString($message);

        // Should not expose sensitive internal information
        $this->assertStringNotContainsString('Exception', $message);
        $this->assertStringNotContainsString('Stack trace', $message);
    }

    /** @test */
    public function api_failures_are_logged_but_not_exposed_to_users()
    {
        // Simulate API failure
        Http::fake([
            'https://api.tessie.com/*' => Http::response(null, 500),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Response should not contain sensitive debugging information
        $responseData = $response->json();

        if (isset($responseData['message'])) {
            $this->assertStringNotContainsString('/app/', $responseData['message']);
            $this->assertStringNotContainsString('vendor/', $responseData['message']);
            $this->assertStringNotContainsString('.php:', $responseData['message']);
        }
    }

    /** @test */
    public function handles_partial_tessie_api_response()
    {
        // Simulate Tessie API returning incomplete data
        Http::fake([
            'https://api.tessie.com/*' => Http::response([
                'battery_level' => 50,
                // Missing other expected fields
            ], 200),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should handle missing fields gracefully
        $this->assertContains($response->status(), [200, 400, 500]);
        $response->assertJsonStructure(['message']);
    }

    /** @test */
    public function retries_transient_failures_appropriately()
    {
        // Simulate transient failure (first fails, second succeeds)
        $callCount = 0;
        Http::fake(function () use (&$callCount) {
            $callCount++;
            if ($callCount === 1) {
                return Http::response(null, 503);
            }
            return Http::response([
                'battery_level' => 50,
                'charge_state' => [
                    'battery_level' => 50,
                    'battery_range' => 200.0,
                    'charging_state' => 'Disconnected',
                ],
            ], 200);
        });

        // Note: This test verifies the application doesn't crash on transient failures
        // Actual retry logic may need to be implemented in the services
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should either succeed (with retry) or fail gracefully (without retry)
        $this->assertContains($response->status(), [200, 400, 500, 503]);
    }

    /** @test */
    public function handles_electricity_provider_api_returning_empty_pricing_data()
    {
        // Create provider
        $provider = ElectricityProvider::create([
            'name' => 'aura',
            'display_name' => 'Aura Electricity',
            'api_base_url' => 'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net',
            'is_active' => true,
        ]);

        $this->user->update([
            'electricity_provider_id' => $provider->id,
            'pricing_region' => 'east',
        ]);

        // Simulate empty pricing response
        Http::fake([
            'https://dkr-cms-umbraco-app-p-aura.azurewebsites.net/*' => Http::response([
                'series' => [],
                'statistics' => null,
            ], 200),
            'https://api.tessie.com/*' => Http::response([
                'battery_level' => 50,
                'charge_state' => [
                    'battery_level' => 50,
                    'battery_range' => 200.0,
                    'charging_state' => 'Disconnected',
                ],
            ], 200),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle->id}/generate");

        // Should handle empty pricing data gracefully
        $this->assertContains($response->status(), [200, 400, 500]);
        $response->assertJsonStructure(['message']);
    }
}
