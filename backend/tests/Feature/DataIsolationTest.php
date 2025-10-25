<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\ChargingSession;
use App\Models\ChargingRecommendation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

class DataIsolationTest extends TestCase
{
    use RefreshDatabase;

    private User $user1;
    private User $user2;
    private string $token1;
    private string $token2;
    private Vehicle $vehicle1;
    private Vehicle $vehicle2;

    protected function setUp(): void
    {
        parent::setUp();

        // Create two users
        $this->user1 = User::create([
            'name' => 'User One',
            'email' => 'user1@example.com',
            'password' => Hash::make('password123'),
        ]);

        $this->user2 = User::create([
            'name' => 'User Two',
            'email' => 'user2@example.com',
            'password' => Hash::make('password123'),
        ]);

        $this->token1 = $this->user1->createToken('test_token')->plainTextToken;
        $this->token2 = $this->user2->createToken('test_token')->plainTextToken;

        // Create vehicles for each user
        $this->vehicle1 = Vehicle::create([
            'user_id' => $this->user1->id,
            'tessie_vehicle_id' => 'user1-vehicle-123',
            'display_name' => 'User 1 Tesla',
            'model' => 'Model 3',
        ]);

        $this->vehicle2 = Vehicle::create([
            'user_id' => $this->user2->id,
            'tessie_vehicle_id' => 'user2-vehicle-456',
            'display_name' => 'User 2 Tesla',
            'model' => 'Model S',
        ]);
    }

    /** @test */
    public function user_can_only_see_their_own_vehicles()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson('/api/v1/vehicles');

        $response->assertStatus(200);
        $vehicles = $response->json('data');

        $this->assertCount(1, $vehicles);
        $this->assertEquals($this->vehicle1->id, $vehicles[0]['id']);
        $this->assertEquals('User 1 Tesla', $vehicles[0]['display_name']);
    }

    /** @test */
    public function user_cannot_view_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/vehicles/{$this->vehicle2->id}");

        // VehicleController uses findOrFail which returns 404 for non-owned vehicles
        $response->assertStatus(404);
    }

    /** @test */
    public function user_cannot_update_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->putJson("/api/v1/vehicles/{$this->vehicle2->id}", [
                'display_name' => 'Hacked Name',
            ]);

        // VehicleController uses findOrFail which returns 404 for non-owned vehicles
        $response->assertStatus(404);

        // Verify vehicle was not updated
        $this->vehicle2->refresh();
        $this->assertEquals('User 2 Tesla', $this->vehicle2->display_name);
    }

    /** @test */
    public function user_cannot_delete_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->deleteJson("/api/v1/vehicles/{$this->vehicle2->id}");

        // VehicleController uses findOrFail which returns 404 for non-owned vehicles
        $response->assertStatus(404);

        // Verify vehicle still exists and is active
        $this->assertDatabaseHas('vehicles', [
            'id' => $this->vehicle2->id,
            'is_active' => true,
        ]);
    }

    /** @test */
    public function user_cannot_get_statistics_for_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/vehicles/{$this->vehicle2->id}/statistics");

        // VehicleController uses findOrFail which returns 404 for non-owned vehicles
        $response->assertStatus(404);
    }

    /** @test */
    public function user_can_only_see_their_own_charging_sessions()
    {
        // Create charging sessions for both users
        ChargingSession::create([
            'vehicle_id' => $this->vehicle1->id,
            'start_time' => now(),
            'energy_added' => 50.5,
            'cost' => 10.5,
        ]);

        ChargingSession::create([
            'vehicle_id' => $this->vehicle2->id,
            'start_time' => now(),
            'energy_added' => 60.0,
            'cost' => 12.0,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson('/api/v1/charging-sessions');

        $response->assertStatus(200);
        $sessions = $response->json();

        $this->assertCount(1, $sessions);
        $this->assertEquals($this->vehicle1->id, $sessions[0]['vehicle_id']);
    }

    /** @test */
    public function user_cannot_view_another_users_charging_session()
    {
        $session = ChargingSession::create([
            'vehicle_id' => $this->vehicle2->id,
            'start_time' => now(),
            'energy_added' => 60.0,
            'cost' => 12.0,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-sessions/{$session->id}");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_update_another_users_charging_session()
    {
        $session = ChargingSession::create([
            'vehicle_id' => $this->vehicle2->id,
            'start_time' => now(),
            'energy_added' => 60.0,
            'cost' => 12.0,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->putJson("/api/v1/charging-sessions/{$session->id}", [
                'energy_added' => 100.0,
            ]);

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);

        // Verify session was not updated
        $session->refresh();
        $this->assertEquals(60.0, $session->energy_added);
    }

    /** @test */
    public function user_cannot_delete_another_users_charging_session()
    {
        $session = ChargingSession::create([
            'vehicle_id' => $this->vehicle2->id,
            'start_time' => now(),
            'energy_added' => 60.0,
            'cost' => 12.0,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->deleteJson("/api/v1/charging-sessions/{$session->id}");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);

        // Verify session still exists
        $this->assertDatabaseHas('charging_sessions', [
            'id' => $session->id,
        ]);
    }

    /** @test */
    public function user_cannot_get_charging_sessions_for_another_users_vehicle()
    {
        ChargingSession::create([
            'vehicle_id' => $this->vehicle2->id,
            'start_time' => now(),
            'energy_added' => 60.0,
            'cost' => 12.0,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-sessions/vehicle/{$this->vehicle2->id}");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_get_recent_sessions_for_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-sessions/vehicle/{$this->vehicle2->id}/recent");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_create_charging_session_for_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->postJson('/api/v1/charging-sessions', [
                'vehicle_id' => $this->vehicle2->id,
                'start_time' => now()->toDateTimeString(),
                'energy_added' => 50.0,
                'cost' => 10.0,
            ]);

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_generate_recommendation_for_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->postJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle2->id}/generate");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_get_latest_recommendation_for_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle2->id}/latest");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_list_recommendations_for_another_users_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-recommendations/vehicle/{$this->vehicle2->id}");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_view_another_users_charging_recommendation()
    {
        $recommendation = ChargingRecommendation::create([
            'vehicle_id' => $this->vehicle2->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-recommendations/{$recommendation->id}");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);
    }

    /** @test */
    public function user_cannot_mark_another_users_recommendation_as_executed()
    {
        $recommendation = ChargingRecommendation::create([
            'vehicle_id' => $this->vehicle2->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->postJson("/api/v1/charging-recommendations/{$recommendation->id}/executed");

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);

        // Verify status was not changed
        $recommendation->refresh();
        $this->assertEquals('pending', $recommendation->status);
    }

    /** @test */
    public function user_cannot_update_status_of_another_users_recommendation()
    {
        $recommendation = ChargingRecommendation::create([
            'vehicle_id' => $this->vehicle2->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->patchJson("/api/v1/charging-recommendations/{$recommendation->id}/status", [
                'status' => 'rejected',
            ]);

        $response->assertStatus(403)
            ->assertJson(['message' => 'Unauthorized']);

        // Verify status was not changed
        $recommendation->refresh();
        $this->assertEquals('pending', $recommendation->status);
    }

    /** @test */
    public function user_can_access_their_own_vehicle_data()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/vehicles/{$this->vehicle1->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $this->vehicle1->id,
                    'display_name' => 'User 1 Tesla',
                ],
            ]);
    }

    /** @test */
    public function user_can_update_their_own_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->putJson("/api/v1/vehicles/{$this->vehicle1->id}", [
                'display_name' => 'My Updated Tesla',
            ]);

        $response->assertStatus(200);

        $this->vehicle1->refresh();
        $this->assertEquals('My Updated Tesla', $this->vehicle1->display_name);
    }

    /** @test */
    public function user_can_delete_their_own_vehicle()
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->deleteJson("/api/v1/vehicles/{$this->vehicle1->id}");

        $response->assertStatus(200);

        // Verify vehicle is soft deleted or marked inactive
        $this->vehicle1->refresh();
        $this->assertFalse($this->vehicle1->is_active);
    }

    /** @test */
    public function user_can_access_their_own_charging_sessions()
    {
        $session = ChargingSession::create([
            'vehicle_id' => $this->vehicle1->id,
            'start_time' => now(),
            'energy_added' => 50.5,
            'cost' => 10.5,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-sessions/{$session->id}");

        $response->assertStatus(200)
            ->assertJson([
                'id' => $session->id,
                'vehicle_id' => $this->vehicle1->id,
            ]);
    }

    /** @test */
    public function user_can_access_their_own_charging_recommendations()
    {
        $recommendation = ChargingRecommendation::create([
            'vehicle_id' => $this->vehicle1->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson("/api/v1/charging-recommendations/{$recommendation->id}");

        $response->assertStatus(200)
            ->assertJson([
                'id' => $recommendation->id,
                'vehicle_id' => $this->vehicle1->id,
            ]);
    }

    /** @test */
    public function user_list_endpoints_do_not_leak_other_users_data()
    {
        // Create multiple resources for both users
        ChargingSession::create([
            'vehicle_id' => $this->vehicle1->id,
            'start_time' => now(),
            'energy_added' => 50.5,
            'cost' => 10.5,
        ]);

        ChargingSession::create([
            'vehicle_id' => $this->vehicle2->id,
            'start_time' => now(),
            'energy_added' => 60.0,
            'cost' => 12.0,
        ]);

        ChargingRecommendation::create([
            'vehicle_id' => $this->vehicle1->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 15.5,
            'cost_savings' => 5.0,
            'confidence_score' => 85,
            'should_charge_now' => true,
            'status' => 'pending',
        ]);

        ChargingRecommendation::create([
            'vehicle_id' => $this->vehicle2->id,
            'recommended_start_time' => now(),
            'recommended_end_time' => now()->addHours(4),
            'estimated_cost' => 18.0,
            'cost_savings' => 6.0,
            'confidence_score' => 90,
            'should_charge_now' => false,
            'status' => 'pending',
        ]);

        // Check vehicles list
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson('/api/v1/vehicles');
        $vehicles = $response->json('data');
        $this->assertCount(1, $vehicles);

        // Check charging sessions list
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->token1)
            ->getJson('/api/v1/charging-sessions');
        $sessions = $response->json();
        $this->assertCount(1, $sessions);

        // Verify none of the data belongs to user2
        foreach ($vehicles as $vehicle) {
            $this->assertEquals($this->user1->id, $vehicle['user_id']);
        }

        foreach ($sessions as $session) {
            $this->assertEquals($this->vehicle1->id, $session['vehicle_id']);
        }
    }
}
