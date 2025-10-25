<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChargingSession;
use App\Models\Vehicle;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class ChargingSessionController extends Controller
{
    /**
     * Get all charging sessions for the authenticated user's vehicles
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $vehicleIds = $user->vehicles()->pluck('id');

        $sessions = ChargingSession::whereIn('vehicle_id', $vehicleIds)
            ->orderBy('start_time', 'desc')
            ->get();

        return response()->json($sessions);
    }

    /**
     * Get charging sessions for a specific vehicle
     */
    public function getByVehicle(Request $request, string $vehicleId): JsonResponse
    {
        // Verify vehicle ownership
        $vehicle = Vehicle::find($vehicleId);
        if (!$vehicle || $vehicle->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Vehicle not found or unauthorized'], 403);
        }

        $sessions = ChargingSession::where('vehicle_id', $vehicleId)
            ->orderBy('start_time', 'desc')
            ->get();

        return response()->json($sessions);
    }

    /**
     * Get charging sessions within a date range
     */
    public function getByDateRange(Request $request, string $vehicleId): JsonResponse
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        // Verify vehicle ownership
        $vehicle = Vehicle::find($vehicleId);
        if (!$vehicle || $vehicle->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Vehicle not found or unauthorized'], 403);
        }

        $startDate = Carbon::parse($request->start_date);
        $endDate = Carbon::parse($request->end_date);

        $sessions = ChargingSession::where('vehicle_id', $vehicleId)
            ->whereBetween('start_time', [$startDate, $endDate])
            ->orderBy('start_time', 'desc')
            ->get();

        return response()->json($sessions);
    }

    /**
     * Get the most recent charging session for a vehicle
     */
    public function getMostRecent(Request $request, string $vehicleId): JsonResponse
    {
        // Verify vehicle ownership
        $vehicle = Vehicle::find($vehicleId);
        if (!$vehicle || $vehicle->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Vehicle not found or unauthorized'], 403);
        }

        $session = ChargingSession::where('vehicle_id', $vehicleId)
            ->orderBy('start_time', 'desc')
            ->first();

        if (!$session) {
            return response()->json(['message' => 'No sessions found'], 404);
        }

        return response()->json($session);
    }

    /**
     * Get a specific charging session
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $session = ChargingSession::with('vehicle')->find($id);

        if (!$session) {
            return response()->json(['message' => 'Session not found'], 404);
        }

        // Verify ownership through vehicle
        if ($session->vehicle->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json($session);
    }

    /**
     * Store a new charging session
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'vehicle_id' => 'required|string|exists:vehicles,id',
            'start_time' => 'required|date',
            'end_time' => 'nullable|date|after:start_time',
            'energy_added' => 'required|numeric|min:0',
            'cost' => 'required|numeric|min:0',
            'charge_rate' => 'nullable|numeric|min:0',
            'start_battery_level' => 'nullable|integer|min:0|max:100',
            'end_battery_level' => 'nullable|integer|min:0|max:100',
        ]);

        // Verify vehicle ownership
        $vehicle = Vehicle::find($validated['vehicle_id']);
        if (!$vehicle || $vehicle->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $session = ChargingSession::create($validated);

        return response()->json($session, 201);
    }

    /**
     * Update an existing charging session
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $session = ChargingSession::with('vehicle')->find($id);

        if (!$session) {
            return response()->json(['message' => 'Session not found'], 404);
        }

        // Verify ownership through vehicle
        if ($session->vehicle->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'vehicle_id' => 'sometimes|string|exists:vehicles,id',
            'start_time' => 'sometimes|date',
            'end_time' => 'nullable|date|after:start_time',
            'energy_added' => 'sometimes|numeric|min:0',
            'cost' => 'sometimes|numeric|min:0',
            'charge_rate' => 'nullable|numeric|min:0',
            'start_battery_level' => 'nullable|integer|min:0|max:100',
            'end_battery_level' => 'nullable|integer|min:0|max:100',
        ]);

        $session->update($validated);

        return response()->json($session);
    }

    /**
     * Delete a charging session
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $session = ChargingSession::with('vehicle')->find($id);

        if (!$session) {
            return response()->json(['message' => 'Session not found'], 404);
        }

        // Verify ownership through vehicle
        if ($session->vehicle->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $session->delete();

        return response()->json(['message' => 'Session deleted successfully']);
    }
}
