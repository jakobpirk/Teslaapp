<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\ChargingSession;
use App\Models\ChargingRecommendation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

class ProtectedRoutesAuthTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
        ]);

        $this->token = $this->user->createToken('test_token')->plainTextToken;
    }

    /** @test */
    public function unauthenticated_users_cannot_access_auth_me()
    {
        $response = $this->getJson('/api/v1/auth/me');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_logout()
    {
        $response = $this->postJson('/api/v1/auth/logout');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_list_vehicles()
    {
        $response = $this->getJson('/api/v1/vehicles');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_get_active_vehicles()
    {
        $response = $this->getJson('/api/v1/vehicles/active');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_create_vehicle()
    {
        $response = $this->postJson('/api/v1/vehicles', [
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_view_vehicle()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->getJson("/api/v1/vehicles/{$vehicle->id}");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_vehicle()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->putJson("/api/v1/vehicles/{$vehicle->id}", [
            'display_name' => 'Updated Name',
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_delete_vehicle()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->deleteJson("/api/v1/vehicles/{$vehicle->id}");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_get_vehicle_statistics()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->getJson("/api/v1/vehicles/{$vehicle->id}/statistics");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_list_charging_sessions()
    {
        $response = $this->getJson('/api/v1/charging-sessions');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_create_charging_session()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->postJson('/api/v1/charging-sessions', [
            'vehicle_id' => $vehicle->id,
            'start_time' => now()->toDateTimeString(),
            'energy_added' => 50.5,
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_view_charging_session()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $session = ChargingSession::create([
            'vehicle_id' => $vehicle->id,
            'start_time' => now(),
            'energy_added' => 50.5,
            'cost' => 10.5,
        ]);

        $response = $this->getJson("/api/v1/charging-sessions/{$session->id}");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_charging_session()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $session = ChargingSession::create([
            'vehicle_id' => $vehicle->id,
            'start_time' => now(),
            'energy_added' => 50.5,
            'cost' => 10.5,
        ]);

        $response = $this->putJson("/api/v1/charging-sessions/{$session->id}", [
            'energy_added' => 60.0,
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_delete_charging_session()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $session = ChargingSession::create([
            'vehicle_id' => $vehicle->id,
            'start_time' => now(),
            'energy_added' => 50.5,
            'cost' => 10.5,
        ]);

        $response = $this->deleteJson("/api/v1/charging-sessions/{$session->id}");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_get_vehicle_charging_sessions()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->getJson("/api/v1/charging-sessions/vehicle/{$vehicle->id}");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_generate_charging_recommendation()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->postJson("/api/v1/charging-recommendations/vehicle/{$vehicle->id}/generate");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_get_latest_charging_recommendation()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $response = $this->getJson("/api/v1/charging-recommendations/vehicle/{$vehicle->id}/latest");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_view_charging_recommendation()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $recommendation = ChargingRecommendation::create([
            'vehicle_id' => $vehicle->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        $response = $this->getJson("/api/v1/charging-recommendations/{$recommendation->id}");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_mark_recommendation_as_executed()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $recommendation = ChargingRecommendation::create([
            'vehicle_id' => $vehicle->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        $response = $this->postJson("/api/v1/charging-recommendations/{$recommendation->id}/executed");
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_recommendation_status()
    {
        $vehicle = Vehicle::create([
            'user_id' => $this->user->id,
            'tessie_vehicle_id' => 'test-123',
            'display_name' => 'My Tesla',
            'model' => 'Model 3',
        ]);

        $recommendation = ChargingRecommendation::create([
            'vehicle_id' => $vehicle->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        $response = $this->patchJson("/api/v1/charging-recommendations/{$recommendation->id}/status", [
            'status' => 'expired',
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_get_user_settings()
    {
        $response = $this->getJson('/api/v1/user/settings');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_get_user_profile()
    {
        $response = $this->getJson('/api/v1/user/profile');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_tessie_api_key()
    {
        $response = $this->postJson('/api/v1/user/settings/tessie-api-key', [
            'tessie_api_key' => 'test-key-123',
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_delete_tessie_api_key()
    {
        $response = $this->deleteJson('/api/v1/user/settings/tessie-api-key');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_electricity_provider()
    {
        $response = $this->postJson('/api/v1/user/settings/electricity-provider', [
            'electricity_provider_id' => 1,
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_pricing_region()
    {
        $response = $this->postJson('/api/v1/user/settings/pricing-region', [
            'pricing_region' => 'east',
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_delete_pricing_region()
    {
        $response = $this->deleteJson('/api/v1/user/settings/pricing-region');
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_auto_charging()
    {
        $response = $this->postJson('/api/v1/user/settings/auto-charging', [
            'enabled' => true,
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function unauthenticated_users_cannot_update_low_battery_protection()
    {
        $response = $this->postJson('/api/v1/user/settings/low-battery-protection', [
            'enabled' => true,
            'threshold' => 20,
            'stop_limit' => 15,
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function authenticated_users_can_access_protected_routes()
    {
        // Test a few key routes to verify authentication works
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/auth/me');
        $response->assertStatus(200);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/vehicles');
        $response->assertStatus(200);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token)
            ->getJson('/api/v1/user/settings');
        $response->assertStatus(200);
    }

    /** @test */
    public function invalid_token_cannot_access_protected_routes()
    {
        $response = $this->withHeader('Authorization', 'Bearer invalid-token-123')
            ->getJson('/api/v1/auth/me');
        $response->assertStatus(401);
    }

    /** @test */
    public function malformed_authorization_header_is_rejected()
    {
        $response = $this->withHeader('Authorization', 'InvalidFormat')
            ->getJson('/api/v1/auth/me');
        $response->assertStatus(401);
    }

    /** @test */
    public function expired_or_revoked_token_cannot_access_protected_routes()
    {
        // Create a token and revoke it
        $token = $this->user->createToken('test_token')->plainTextToken;
        $this->user->tokens()->delete();

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/auth/me');
        $response->assertStatus(401);
    }
}
