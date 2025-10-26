<?php

namespace App\Http\Controllers;

use App\Services\CO2StatisticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CO2StatisticsController extends Controller
{
    private CO2StatisticsService $service;

    public function __construct(CO2StatisticsService $service)
    {
        $this->service = $service;
    }

    /**
     * Get CO2 statistics for the authenticated user.
     */
    public function user(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        $statistics = $this->service->getUserStatistics($user->id, $startDate, $endDate);

        return response()->json([
            'success' => true,
            'data' => $statistics,
        ]);
    }

    /**
     * Get CO2 statistics for a specific vehicle.
     */
    public function vehicle(Request $request, string $vehicleId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
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
        $vehicle = $user->vehicles()->findOrFail($vehicleId);

        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        $statistics = $this->service->getVehicleStatistics($vehicleId, $startDate, $endDate);

        return response()->json([
            'success' => true,
            'data' => $statistics,
        ]);
    }

    /**
     * Get CO2 saving tips for the user.
     */
    public function tips(Request $request): JsonResponse
    {
        $user = $request->user();
        $tips = $this->service->getSavingTips($user->id);

        return response()->json([
            'success' => true,
            'data' => $tips,
        ]);
    }

    /**
     * Backfill CO2 data for existing charging sessions.
     */
    public function backfill(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'zone' => 'sometimes|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $zone = $request->input('zone', 'DK1');
        $result = $this->service->backfillCO2Data($zone);

        return response()->json([
            'success' => true,
            'message' => 'CO2 data backfill completed',
            'data' => $result,
        ]);
    }

    /**
     * Get dashboard data with overview statistics.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $user = $request->user();

        // Get last 30 days statistics
        $endDate = now()->toDateString();
        $startDate = now()->subDays(30)->toDateString();

        $monthlyStats = $this->service->getUserStatistics($user->id, $startDate, $endDate);

        // Get all-time statistics
        $allTimeStats = $this->service->getUserStatistics($user->id);

        // Get tips
        $tips = $this->service->getSavingTips($user->id);

        return response()->json([
            'success' => true,
            'data' => [
                'last_30_days' => $monthlyStats,
                'all_time' => $allTimeStats,
                'tips' => $tips,
            ],
        ]);
    }
}
