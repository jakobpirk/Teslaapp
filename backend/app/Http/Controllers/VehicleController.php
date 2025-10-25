<?php

namespace App\Http\Controllers;

use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class VehicleController extends Controller
{
    /**
     * Get all vehicles for the authenticated user.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $vehicles = $user->vehicles()->with(['chargingSessions' => function ($query) {
            $query->latest()->limit(1);
        }])->get();

        return response()->json([
            'success' => true,
            'data' => $vehicles,
        ]);
    }

    /**
     * Get active vehicles only.
     */
    public function active(Request $request): JsonResponse
    {
        $user = $request->user();
        $vehicles = $user->activeVehicles()->with(['chargingSessions' => function ($query) {
            $query->latest()->limit(1);
        }])->get();

        return response()->json([
            'success' => true,
            'data' => $vehicles,
        ]);
    }

    /**
     * Get a specific vehicle.
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $vehicle = $user->vehicles()->with(['chargingSessions', 'chargingRecommendations'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $vehicle,
        ]);
    }

    /**
     * Create a new vehicle.
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'api_provider' => 'required|string|in:tessie,tesla',
            'provider_vehicle_id' => 'required|string',
            'display_name' => 'required|string|max:255',
            'vin' => 'nullable|string|max:17',
            'model' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:50',
            'year' => 'nullable|integer|min:2000|max:' . (date('Y') + 1),
            'battery_capacity' => 'nullable|numeric|min:0',
            'vehicle_config' => 'nullable|array',
            'charge_limit' => 'nullable|integer|min:50|max:100',
            'auto_charging_enabled' => 'nullable|boolean',
            'low_battery_protection_enabled' => 'nullable|boolean',
            'low_battery_threshold' => 'nullable|integer|min:5|max:95',
            'low_battery_stop_limit' => 'nullable|integer|min:10|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $data = $validator->validated();

        // Check for duplicate provider_vehicle_id for the same provider
        $existingVehicle = Vehicle::where('provider_vehicle_id', $data['provider_vehicle_id'])
            ->where('api_provider', $data['api_provider'])
            ->first();

        if ($existingVehicle) {
            return response()->json([
                'success' => false,
                'message' => 'This vehicle is already registered with the specified provider',
            ], 422);
        }

        // Check if user has the appropriate API key configured
        $apiProvider = $data['api_provider'];
        $apiKeyMethod = 'has' . ucfirst($apiProvider) . 'ApiKey';

        if (method_exists($user, $apiKeyMethod) && !$user->$apiKeyMethod()) {
            return response()->json([
                'success' => false,
                'message' => "Please configure your {$apiProvider} API key first",
            ], 400);
        }

        $vehicle = $user->vehicles()->create($data);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle added successfully',
            'data' => $vehicle,
        ], 201);
    }

    /**
     * Update a vehicle.
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'display_name' => 'sometimes|string|max:255',
            'vin' => 'nullable|string|max:17',
            'model' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:50',
            'year' => 'nullable|integer|min:2000|max:' . (date('Y') + 1),
            'battery_capacity' => 'nullable|numeric|min:0',
            'is_active' => 'sometimes|boolean',
            'vehicle_config' => 'nullable|array',
            'charge_limit' => 'nullable|integer|min:50|max:100',
            'auto_charging_enabled' => 'nullable|boolean',
            'low_battery_protection_enabled' => 'nullable|boolean',
            'low_battery_threshold' => 'nullable|integer|min:5|max:95',
            'low_battery_stop_limit' => 'nullable|integer|min:10|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $vehicle = $user->vehicles()->findOrFail($id);
        $vehicle->update($validator->validated());

        return response()->json([
            'success' => true,
            'message' => 'Vehicle updated successfully',
            'data' => $vehicle,
        ]);
    }

    /**
     * Delete a vehicle (soft delete by setting is_active to false).
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $vehicle = $user->vehicles()->findOrFail($id);

        // Soft delete by deactivating
        $vehicle->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Vehicle deactivated successfully',
        ]);
    }

    /**
     * Permanently delete a vehicle.
     */
    public function forceDestroy(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $vehicle = $user->vehicles()->findOrFail($id);
        $vehicle->delete();

        return response()->json([
            'success' => true,
            'message' => 'Vehicle deleted permanently',
        ]);
    }

    /**
     * Get vehicle statistics.
     */
    public function statistics(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $vehicle = $user->vehicles()->findOrFail($id);

        $totalSessions = $vehicle->chargingSessions()->count();
        $totalEnergy = $vehicle->chargingSessions()->sum('energy_added');
        $totalCost = $vehicle->chargingSessions()->sum('cost');
        $averageCost = $totalSessions > 0 ? $totalCost / $totalSessions : 0;

        $recentSession = $vehicle->latestChargingSession();
        $latestRecommendation = $vehicle->latestChargingRecommendation();

        return response()->json([
            'success' => true,
            'data' => [
                'vehicle_id' => $vehicle->id,
                'display_name' => $vehicle->display_name,
                'statistics' => [
                    'total_charging_sessions' => $totalSessions,
                    'total_energy_kwh' => round($totalEnergy, 2),
                    'total_cost' => round($totalCost, 2),
                    'average_cost_per_session' => round($averageCost, 2),
                ],
                'recent_session' => $recentSession,
                'latest_recommendation' => $latestRecommendation,
            ],
        ]);
    }

    /**
     * Update charging settings for a specific vehicle.
     */
    public function updateChargingSettings(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'charge_limit' => 'nullable|integer|min:50|max:100',
            'auto_charging_enabled' => 'nullable|boolean',
            'low_battery_protection_enabled' => 'nullable|boolean',
            'low_battery_threshold' => 'nullable|integer|min:5|max:95',
            'low_battery_stop_limit' => 'nullable|integer|min:10|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $vehicle = $user->vehicles()->findOrFail($id);

        // Validate that low_battery_stop_limit is greater than low_battery_threshold if both provided
        $data = $validator->validated();
        $threshold = $data['low_battery_threshold'] ?? $vehicle->low_battery_threshold;
        $stopLimit = $data['low_battery_stop_limit'] ?? $vehicle->low_battery_stop_limit;

        if ($threshold && $stopLimit && $stopLimit <= $threshold) {
            return response()->json([
                'success' => false,
                'message' => 'Low battery stop limit must be greater than low battery threshold',
            ], 422);
        }

        $vehicle->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Charging settings updated successfully',
            'data' => $vehicle,
        ]);
    }

    /**
     * Get charging settings for a specific vehicle.
     */
    public function getChargingSettings(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $vehicle = $user->vehicles()->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => [
                'vehicle_id' => $vehicle->id,
                'display_name' => $vehicle->display_name,
                'charge_limit' => $vehicle->charge_limit,
                'auto_charging_enabled' => $vehicle->auto_charging_enabled,
                'low_battery_protection_enabled' => $vehicle->low_battery_protection_enabled,
                'low_battery_threshold' => $vehicle->low_battery_threshold,
                'low_battery_stop_limit' => $vehicle->low_battery_stop_limit,
            ],
        ]);
    }
}
