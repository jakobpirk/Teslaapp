<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChargingRecommendation;
use App\Models\Vehicle;
use App\Services\SmartChargingService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ChargingRecommendationController extends Controller
{
    private SmartChargingService $smartChargingService;

    public function __construct(SmartChargingService $smartChargingService)
    {
        $this->smartChargingService = $smartChargingService;
    }

    /**
     * Generate a new charging recommendation for a vehicle
     */
    public function generate(Request $request, string $vehicleId): JsonResponse
    {
        $validated = $request->validate([
            'required_by' => 'nullable|date',
            'energy_needed' => 'nullable|numeric|min:0',
        ]);

        // Load vehicle with user and electricity provider for regional pricing
        $vehicle = Vehicle::with('user.electricityProvider')->find($vehicleId);

        if (!$vehicle) {
            return response()->json(['message' => 'Vehicle not found'], 404);
        }

        // Pass user to the service for regional pricing support
        $options = array_merge($validated, [
            'user' => $vehicle->user,
        ]);

        $recommendation = $this->smartChargingService->generateRecommendation(
            $vehicleId,
            $options
        );

        return response()->json($recommendation, 201);
    }

    /**
     * Get the latest recommendation for a vehicle
     */
    public function latest(string $vehicleId): JsonResponse
    {
        $recommendation = ChargingRecommendation::getLatestForVehicle($vehicleId);

        if (!$recommendation) {
            return response()->json(['message' => 'No recommendations found'], 404);
        }

        // Check if recommendation is still valid
        $isValid = $this->smartChargingService->isRecommendationValid($recommendation);

        return response()->json([
            'recommendation' => $recommendation,
            'is_valid' => $isValid,
        ]);
    }

    /**
     * Get all recommendations for a vehicle
     */
    public function index(string $vehicleId): JsonResponse
    {
        $recommendations = ChargingRecommendation::where('vehicle_id', $vehicleId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($recommendations);
    }

    /**
     * Get a specific recommendation
     */
    public function show(string $id): JsonResponse
    {
        $recommendation = ChargingRecommendation::find($id);

        if (!$recommendation) {
            return response()->json(['message' => 'Recommendation not found'], 404);
        }

        return response()->json($recommendation);
    }

    /**
     * Mark a recommendation as executed
     */
    public function markExecuted(string $id): JsonResponse
    {
        $recommendation = ChargingRecommendation::find($id);

        if (!$recommendation) {
            return response()->json(['message' => 'Recommendation not found'], 404);
        }

        $recommendation->markAsExecuted();

        return response()->json($recommendation);
    }

    /**
     * Update recommendation status
     */
    public function updateStatus(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|in:pending,accepted,rejected,executed',
        ]);

        $recommendation = ChargingRecommendation::find($id);

        if (!$recommendation) {
            return response()->json(['message' => 'Recommendation not found'], 404);
        }

        $recommendation->update(['status' => $validated['status']]);

        return response()->json($recommendation);
    }
}
