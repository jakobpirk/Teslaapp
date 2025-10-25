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
                'pricing_region' => $user->getPricingRegion(),
                'auto_charging_enabled' => $user->isAutoChargingEnabled(),
                'low_battery_protection_enabled' => $user->isLowBatteryProtectionEnabled(),
                'low_battery_threshold' => $user->getLowBatteryThreshold(),
                'low_battery_stop_limit' => $user->getLowBatteryStopLimit(),
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
     * Update pricing region.
     */
    public function updatePricingRegion(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pricing_region' => 'required|string|in:east,west',
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
            'pricing_region' => $request->pricing_region,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pricing region updated successfully',
            'data' => [
                'pricing_region' => $user->pricing_region,
            ],
        ]);
    }

    /**
     * Remove pricing region.
     */
    public function removePricingRegion(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->update([
            'pricing_region' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pricing region removed successfully',
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
                'pricing_region' => $user->getPricingRegion(),
                'auto_charging_enabled' => $user->isAutoChargingEnabled(),
                'low_battery_protection_enabled' => $user->isLowBatteryProtectionEnabled(),
                'low_battery_threshold' => $user->getLowBatteryThreshold(),
                'low_battery_stop_limit' => $user->getLowBatteryStopLimit(),
                'vehicles_count' => $user->vehicles->count(),
                'active_vehicles_count' => $user->activeVehicles->count(),
            ],
        ]);
    }

    /**
     * Update automatic charging setting.
     */
    public function updateAutoCharging(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'enabled' => 'required|boolean',
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
            'auto_charging_enabled' => $request->enabled,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Automatic charging ' . ($request->enabled ? 'enabled' : 'disabled'),
            'data' => [
                'auto_charging_enabled' => $user->auto_charging_enabled,
            ],
        ]);
    }

    /**
     * Update low battery protection settings.
     */
    public function updateLowBatteryProtection(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'enabled' => 'required|boolean',
            'threshold' => 'nullable|integer|min:5|max:95',
            'stop_limit' => 'nullable|integer|min:10|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Validate that stop_limit is greater than threshold
        if ($request->has('threshold') && $request->has('stop_limit')) {
            if ($request->stop_limit <= $request->threshold) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stop limit must be greater than threshold',
                ], 422);
            }
        }

        $user = $request->user();
        $updateData = [
            'low_battery_protection_enabled' => $request->enabled,
        ];

        if ($request->has('threshold')) {
            $updateData['low_battery_threshold'] = $request->threshold;
        }

        if ($request->has('stop_limit')) {
            $updateData['low_battery_stop_limit'] = $request->stop_limit;
        }

        $user->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'Low battery protection updated successfully',
            'data' => [
                'low_battery_protection_enabled' => $user->low_battery_protection_enabled,
                'low_battery_threshold' => $user->low_battery_threshold,
                'low_battery_stop_limit' => $user->low_battery_stop_limit,
            ],
        ]);
    }
}
