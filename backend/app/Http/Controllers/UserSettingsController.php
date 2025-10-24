<?php

namespace App\Http\Controllers;

use App\Models\ElectricityProvider;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UserSettingsController extends Controller
{
    /**
     * Get user settings.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->load('electricityProvider');

        return response()->json([
            'success' => true,
            'data' => [
                'has_tessie_api_key' => $user->hasTessieApiKey(),
                'electricity_provider' => $user->electricityProvider,
                'location' => $user->location,
            ],
        ]);
    }

    /**
     * Update Tessie API key.
     */
    public function updateTessieApiKey(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'tessie_api_key' => 'required|string|min:10',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->update([
            'tessie_api_key' => $request->tessie_api_key,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Tessie API key updated successfully',
        ]);
    }

    /**
     * Remove Tessie API key.
     */
    public function removeTessieApiKey(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->update([
            'tessie_api_key' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Tessie API key removed successfully',
        ]);
    }

    /**
     * Update electricity provider.
     */
    public function updateElectricityProvider(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'electricity_provider_id' => 'required|uuid|exists:electricity_providers,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $provider = ElectricityProvider::findOrFail($request->electricity_provider_id);

        if (!$provider->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Selected provider is not active',
            ], 400);
        }

        $user = $request->user();
        $user->update([
            'electricity_provider_id' => $request->electricity_provider_id,
        ]);

        $user->load('electricityProvider');

        return response()->json([
            'success' => true,
            'message' => 'Electricity provider updated successfully',
            'data' => $user->electricityProvider,
        ]);
    }

    /**
     * Update user location.
     */
    public function updateLocation(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'location' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->update([
            'location' => $request->location,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Location updated successfully',
        ]);
    }

    /**
     * Get complete user profile with settings.
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->load(['electricityProvider', 'vehicles']);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'has_tessie_api_key' => $user->hasTessieApiKey(),
                'electricity_provider' => $user->electricityProvider,
                'location' => $user->location,
                'vehicles_count' => $user->vehicles->count(),
                'active_vehicles_count' => $user->activeVehicles->count(),
            ],
        ]);
    }
}
