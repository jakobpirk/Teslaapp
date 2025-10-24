<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChargingSession;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class ChargingSessionController extends Controller
{
    /**
     * Get all charging sessions
     */
    public function index(): JsonResponse
    {
        $sessions = ChargingSession::orderBy('start_time', 'desc')->get();
        return response()->json($sessions);
    }

    /**
     * Get charging sessions for a specific vehicle
     */
    public function getByVehicle(string $vehicleId): JsonResponse
    {
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
    public function getMostRecent(string $vehicleId): JsonResponse
    {
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
    public function show(string $id): JsonResponse
    {
        $session = ChargingSession::find($id);

        if (!$session) {
            return response()->json(['message' => 'Session not found'], 404);
        }

        return response()->json($session);
    }

    /**
     * Store a new charging session
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'vehicle_id' => 'required|string',
            'start_time' => 'required|date',
            'end_time' => 'nullable|date|after:start_time',
            'energy_added' => 'required|numeric|min:0',
            'cost' => 'required|numeric|min:0',
            'location' => 'nullable|string',
            'charge_rate' => 'nullable|numeric|min:0',
            'start_battery_level' => 'nullable|integer|min:0|max:100',
            'end_battery_level' => 'nullable|integer|min:0|max:100',
        ]);

        $session = ChargingSession::create($validated);

        return response()->json($session, 201);
    }

    /**
     * Update an existing charging session
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $session = ChargingSession::find($id);

        if (!$session) {
            return response()->json(['message' => 'Session not found'], 404);
        }

        $validated = $request->validate([
            'vehicle_id' => 'sometimes|string',
            'start_time' => 'sometimes|date',
            'end_time' => 'nullable|date|after:start_time',
            'energy_added' => 'sometimes|numeric|min:0',
            'cost' => 'sometimes|numeric|min:0',
            'location' => 'nullable|string',
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
    public function destroy(string $id): JsonResponse
    {
        $session = ChargingSession::find($id);

        if (!$session) {
            return response()->json(['message' => 'Session not found'], 404);
        }

        $session->delete();

        return response()->json(['message' => 'Session deleted successfully']);
    }
}
