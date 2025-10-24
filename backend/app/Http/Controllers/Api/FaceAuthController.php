<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FaceEnrollment;
use App\Models\FaceAuthSession;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use Illuminate\Support\Str;

class FaceAuthController extends Controller
{
    /**
     * Register a new face enrollment
     */
    public function registerEnrollment(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => 'required|string',
            'device_id' => 'nullable|string',
        ]);

        // Delete any existing active enrollments for this user
        FaceEnrollment::where('user_id', $validated['user_id'])
            ->where('is_active', true)
            ->delete();

        // Create new enrollment
        $enrollment = FaceEnrollment::create([
            'user_id' => $validated['user_id'],
            'enrolled_at' => now(),
            'is_active' => true,
            'device_id' => $validated['device_id'] ?? null,
            'biometric_type' => 'face',
        ]);

        return response()->json([
            'id' => $enrollment->id,
            'user_id' => $enrollment->user_id,
            'enrolled_at' => $enrollment->enrolled_at->toIso8601String(),
            'is_active' => $enrollment->is_active,
            'device_id' => $enrollment->device_id,
            'biometric_type' => $enrollment->biometric_type,
        ], 201);
    }

    /**
     * Get enrollment for a user
     */
    public function getEnrollment(string $userId): JsonResponse
    {
        $enrollment = FaceEnrollment::where('user_id', $userId)
            ->where('is_active', true)
            ->first();

        if (!$enrollment) {
            return response()->json([
                'message' => 'No active enrollment found for user'
            ], 404);
        }

        return response()->json([
            'id' => $enrollment->id,
            'user_id' => $enrollment->user_id,
            'enrolled_at' => $enrollment->enrolled_at->toIso8601String(),
            'is_active' => $enrollment->is_active,
            'device_id' => $enrollment->device_id,
            'biometric_type' => $enrollment->biometric_type,
        ]);
    }

    /**
     * Delete enrollment for a user
     */
    public function deleteEnrollment(string $userId): JsonResponse
    {
        $deleted = FaceEnrollment::where('user_id', $userId)->delete();

        if ($deleted === 0) {
            return response()->json([
                'message' => 'No enrollment found for user'
            ], 404);
        }

        return response()->json([
            'message' => 'Enrollment deleted successfully'
        ]);
    }

    /**
     * Verify face authentication
     */
    public function verifyAuthentication(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => 'required|string',
            'enrollment_id' => 'required|string',
        ]);

        // Verify enrollment exists and is active
        $enrollment = FaceEnrollment::where('id', $validated['enrollment_id'])
            ->where('user_id', $validated['user_id'])
            ->where('is_active', true)
            ->first();

        if (!$enrollment) {
            return response()->json([
                'message' => 'Invalid or inactive enrollment'
            ], 404);
        }

        // Create authentication session
        $session = FaceAuthSession::create([
            'user_id' => $validated['user_id'],
            'enrollment_id' => $validated['enrollment_id'],
            'authenticated_at' => now(),
            'expires_at' => now()->addHours(24),
            'is_authenticated' => true,
            'confidence_score' => 0.95,
            'method' => 'faceBiometric',
        ]);

        return response()->json([
            'session_token' => $session->id,
            'user_id' => $session->user_id,
            'enrollment_id' => $session->enrollment_id,
            'authenticated_at' => $session->authenticated_at->toIso8601String(),
            'expires_at' => $session->expires_at->toIso8601String(),
            'is_authenticated' => $session->is_authenticated,
            'confidence_score' => $session->confidence_score,
            'method' => $session->method,
        ], 201);
    }

    /**
     * Verify a session token
     */
    public function verifySessionToken(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'session_token' => 'required|string',
        ]);

        $session = FaceAuthSession::find($validated['session_token']);

        if (!$session) {
            return response()->json([
                'valid' => false,
                'message' => 'Session not found'
            ]);
        }

        // Check if session is expired
        if (now()->isAfter($session->expires_at)) {
            return response()->json([
                'valid' => false,
                'message' => 'Session expired'
            ]);
        }

        return response()->json([
            'valid' => $session->is_authenticated,
            'user_id' => $session->user_id,
            'expires_at' => $session->expires_at->toIso8601String(),
        ]);
    }

    /**
     * Invalidate a session
     */
    public function invalidateSession(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'session_token' => 'required|string',
        ]);

        $session = FaceAuthSession::find($validated['session_token']);

        if (!$session) {
            return response()->json([
                'message' => 'Session not found'
            ], 404);
        }

        $session->update([
            'is_authenticated' => false,
            'expires_at' => now(),
        ]);

        return response()->json([
            'message' => 'Session invalidated successfully'
        ]);
    }
}
