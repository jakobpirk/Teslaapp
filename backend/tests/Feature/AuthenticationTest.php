<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

class AuthenticationTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_register_with_valid_data()
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user' => ['id', 'name', 'email'],
                    'token',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
            'name' => 'John Doe',
        ]);
    }

    /** @test */
    public function user_cannot_register_with_existing_email()
    {
        User::create([
            'name' => 'Existing User',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonStructure(['success', 'message', 'errors']);
    }

    /** @test */
    public function user_cannot_register_with_short_password()
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'short',
            'password_confirmation' => 'short',
        ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function user_cannot_register_with_mismatched_passwords()
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'different123',
        ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function user_can_login_with_valid_credentials()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'john@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user' => ['id', 'name', 'email'],
                    'token',
                ],
            ]);
    }

    /** @test */
    public function user_cannot_login_with_invalid_credentials()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'john@example.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid credentials',
            ]);
    }

    /** @test */
    public function authenticated_user_can_get_their_profile()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $token = $user->createToken('test_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => 'John Doe',
                        'email' => 'john@example.com',
                    ],
                ],
            ]);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_profile()
    {
        $response = $this->getJson('/api/v1/auth/me');

        $response->assertStatus(401);
    }

    /** @test */
    public function authenticated_user_can_logout()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $token = $user->createToken('test_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Logged out successfully',
            ]);

        // Verify token is revoked
        $this->assertEquals(0, $user->tokens()->count());
    }

    /** @test */
    public function user_can_request_password_reset()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'john@example.com',
        ]);
    }

    /** @test */
    public function user_can_reset_password_with_valid_code()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('oldpassword123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Reset password
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Password reset successfully',
            ]);

        // Verify password was changed
        $user->refresh();
        $this->assertTrue(Hash::check('newpassword123', $user->password));
    }

    /** @test */
    public function user_cannot_reset_password_with_invalid_code()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => '000000',
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid reset code',
            ]);
    }

    /** @test */
    public function user_can_verify_valid_reset_code()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Verify reset code
        $response = $this->postJson('/api/v1/auth/verify-reset-code', [
            'email' => 'john@example.com',
            'code' => $resetCode,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Reset code is valid',
            ]);
    }

    /** @test */
    public function user_cannot_verify_invalid_reset_code()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-reset-code', [
            'email' => 'john@example.com',
            'code' => '000000',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid reset code',
            ]);
    }

    /** @test */
    public function reset_code_expires_after_15_minutes()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Manually update the created_at timestamp to simulate expiration
        \DB::table('password_reset_tokens')
            ->where('email', 'john@example.com')
            ->update(['created_at' => now()->subMinutes(16)]);

        // Try to verify expired code
        $response = $this->postJson('/api/v1/auth/verify-reset-code', [
            'email' => 'john@example.com',
            'code' => $resetCode,
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Reset code has expired',
            ]);

        // Verify the expired token was deleted
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'john@example.com',
        ]);
    }

    /** @test */
    public function user_cannot_reset_password_with_expired_code()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('oldpassword123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Manually update the created_at timestamp to simulate expiration
        \DB::table('password_reset_tokens')
            ->where('email', 'john@example.com')
            ->update(['created_at' => now()->subMinutes(16)]);

        // Try to reset with expired code
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Reset code has expired',
            ]);

        // Verify password was not changed
        $user->refresh();
        $this->assertTrue(Hash::check('oldpassword123', $user->password));
    }

    /** @test */
    public function reset_code_is_deleted_after_successful_password_reset()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('oldpassword123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Reset password
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(200);

        // Verify reset token was deleted
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'john@example.com',
        ]);
    }

    /** @test */
    public function reset_code_cannot_be_reused()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('oldpassword123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Reset password first time
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(200);

        // Try to use same code again
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'anotherpassword123',
            'password_confirmation' => 'anotherpassword123',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Invalid reset code',
            ]);

        // Verify password wasn't changed to the second attempt
        $user->refresh();
        $this->assertTrue(Hash::check('newpassword123', $user->password));
    }

    /** @test */
    public function all_user_tokens_are_revoked_after_password_reset()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('oldpassword123'),
        ]);

        // Create multiple tokens (simulate logged in on multiple devices)
        $token1 = $user->createToken('device1')->plainTextToken;
        $token2 = $user->createToken('device2')->plainTextToken;
        $token3 = $user->createToken('device3')->plainTextToken;

        $this->assertEquals(3, $user->tokens()->count());

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Reset password
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(200);

        // Verify all tokens were revoked
        $user->refresh();
        $this->assertEquals(0, $user->tokens()->count());

        // Verify old tokens cannot access protected routes
        $response = $this->withHeader('Authorization', 'Bearer ' . $token1)
            ->getJson('/api/v1/auth/me');
        $response->assertStatus(401);
    }

    /** @test */
    public function forgot_password_returns_success_even_for_non_existent_email()
    {
        // This is a security best practice to prevent email enumeration
        $response = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'nonexistent@example.com',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        // Verify no token was actually created
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'nonexistent@example.com',
        ]);
    }

    /** @test */
    public function new_reset_code_replaces_old_one_for_same_email()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('password123'),
        ]);

        // Request first reset code
        $firstResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);
        $firstCode = $firstResponse->json('reset_code');

        // Request second reset code
        $secondResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);
        $secondCode = $secondResponse->json('reset_code');

        // Verify only one reset token exists
        $this->assertEquals(1, \DB::table('password_reset_tokens')
            ->where('email', 'john@example.com')
            ->count());

        // Verify first code no longer works
        $response = $this->postJson('/api/v1/auth/verify-reset-code', [
            'email' => 'john@example.com',
            'code' => $firstCode,
        ]);
        $response->assertStatus(400);

        // Verify second code works
        $response = $this->postJson('/api/v1/auth/verify-reset-code', [
            'email' => 'john@example.com',
            'code' => $secondCode,
        ]);
        $response->assertStatus(200);
    }

    /** @test */
    public function reset_password_requires_matching_password_confirmation()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('oldpassword123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Try to reset with mismatched passwords
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'newpassword123',
            'password_confirmation' => 'differentpassword123',
        ]);

        $response->assertStatus(422);

        // Verify password was not changed
        $user->refresh();
        $this->assertTrue(Hash::check('oldpassword123', $user->password));
    }

    /** @test */
    public function reset_password_requires_minimum_password_length()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => Hash::make('oldpassword123'),
        ]);

        // Request reset code
        $resetResponse = $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'john@example.com',
        ]);

        $resetCode = $resetResponse->json('reset_code');

        // Try to reset with short password
        $response = $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'john@example.com',
            'code' => $resetCode,
            'password' => 'short',
            'password_confirmation' => 'short',
        ]);

        $response->assertStatus(422);

        // Verify password was not changed
        $user->refresh();
        $this->assertTrue(Hash::check('oldpassword123', $user->password));
    }
}
