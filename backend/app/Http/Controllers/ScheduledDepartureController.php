<?php

namespace App\Http\Controllers;

use App\Models\ScheduledDeparture;
use App\Services\ScheduledDepartureService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ScheduledDepartureController extends Controller
{
    private ScheduledDepartureService $service;

    public function __construct(ScheduledDepartureService $service)
    {
        $this->service = $service;
    }

    /**
     * Get all scheduled departures for the authenticated user.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $schedules = $this->service->getUserSchedules($user->id);

        return response()->json([
            'success' => true,
            'data' => $schedules,
        ]);
    }

    /**
     * Get scheduled departures for a specific vehicle.
     */
    public function byVehicle(Request $request, string $vehicleId): JsonResponse
    {
        $user = $request->user();

        // Verify vehicle belongs to user
        $vehicle = $user->vehicles()->findOrFail($vehicleId);

        $schedules = $this->service->getVehicleSchedules($vehicleId);

        return response()->json([
            'success' => true,
            'data' => $schedules,
        ]);
    }

    /**
     * Get a specific scheduled departure.
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $schedule = ScheduledDeparture::where('user_id', $user->id)
            ->with('vehicle')
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $schedule,
        ]);
    }

    /**
     * Create a new scheduled departure.
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'vehicle_id' => 'required|uuid|exists:vehicles,id',
            'departure_time' => 'required|date_format:H:i',
            'days_of_week' => 'required|array',
            'days_of_week.*' => 'integer|min:0|max:6',
            'timezone' => 'required|string|timezone',
            'is_enabled' => 'boolean',
            'precondition_climate' => 'boolean',
            'precondition_battery' => 'boolean',
            'target_temperature' => 'nullable|numeric|min:15|max:30',
            'preconditioning_minutes' => 'integer|min:5|max:60',
            'charge_before_departure' => 'boolean',
            'target_battery_level' => 'nullable|integer|min:50|max:100',
            'off_peak_only' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        // Verify vehicle belongs to user
        $vehicle = $user->vehicles()->findOrFail($request->vehicle_id);

        $data = $validator->validated();
        $data['user_id'] = $user->id;

        // Convert HH:mm to HH:mm:ss
        $data['departure_time'] = $data['departure_time'] . ':00';

        $schedule = $this->service->createSchedule($data);

        return response()->json([
            'success' => true,
            'message' => 'Scheduled departure created successfully',
            'data' => $schedule->load('vehicle'),
        ], 201);
    }

    /**
     * Update a scheduled departure.
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'departure_time' => 'sometimes|date_format:H:i',
            'days_of_week' => 'sometimes|array',
            'days_of_week.*' => 'integer|min:0|max:6',
            'timezone' => 'sometimes|string|timezone',
            'is_enabled' => 'sometimes|boolean',
            'precondition_climate' => 'sometimes|boolean',
            'precondition_battery' => 'sometimes|boolean',
            'target_temperature' => 'nullable|numeric|min:15|max:30',
            'preconditioning_minutes' => 'sometimes|integer|min:5|max:60',
            'charge_before_departure' => 'sometimes|boolean',
            'target_battery_level' => 'nullable|integer|min:50|max:100',
            'off_peak_only' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $schedule = ScheduledDeparture::where('user_id', $user->id)->findOrFail($id);

        $data = $validator->validated();

        // Convert HH:mm to HH:mm:ss if present
        if (isset($data['departure_time'])) {
            $data['departure_time'] = $data['departure_time'] . ':00';
        }

        $schedule = $this->service->updateSchedule($schedule, $data);

        return response()->json([
            'success' => true,
            'message' => 'Scheduled departure updated successfully',
            'data' => $schedule->load('vehicle'),
        ]);
    }

    /**
     * Delete a scheduled departure.
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $schedule = ScheduledDeparture::where('user_id', $user->id)->findOrFail($id);

        $this->service->deleteSchedule($schedule);

        return response()->json([
            'success' => true,
            'message' => 'Scheduled departure deleted successfully',
        ]);
    }

    /**
     * Toggle enable/disable a scheduled departure.
     */
    public function toggle(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $schedule = ScheduledDeparture::where('user_id', $user->id)->findOrFail($id);

        $schedule->is_enabled = !$schedule->is_enabled;
        $schedule->save();

        return response()->json([
            'success' => true,
            'message' => 'Scheduled departure ' . ($schedule->is_enabled ? 'enabled' : 'disabled'),
            'data' => $schedule->load('vehicle'),
        ]);
    }
}
