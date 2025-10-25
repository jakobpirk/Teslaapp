<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PricingHistory;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class PricingHistoryController extends Controller
{
    /**
     * Get pricing history for a date range
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'start_time' => 'required|date',
            'end_time' => 'required|date|after_or_equal:start_time',
        ]);

        $startTime = Carbon::parse($request->start_time);
        $endTime = Carbon::parse($request->end_time);

        $pricing = PricingHistory::getForTimeRange($startTime, $endTime);

        return response()->json([
            'data' => $pricing,
            'meta' => [
                'start_time' => $startTime->toIso8601String(),
                'end_time' => $endTime->toIso8601String(),
                'count' => $pricing->count(),
            ],
        ]);
    }

    /**
     * Get current pricing (next hour)
     */
    public function current(Request $request): JsonResponse
    {
        $now = Carbon::now()->startOfHour();

        $currentPrice = PricingHistory::where('timestamp', $now)
            ->first();

        if (!$currentPrice) {
            return response()->json(['message' => 'No pricing data available'], 404);
        }

        return response()->json($currentPrice);
    }

    /**
     * Get pricing for today and tomorrow
     */
    public function todayAndTomorrow(Request $request): JsonResponse
    {
        $startTime = Carbon::now()->startOfDay();
        $endTime = Carbon::now()->addDay()->endOfDay();

        $pricing = PricingHistory::getForTimeRange($startTime, $endTime);

        return response()->json([
            'data' => $pricing,
            'meta' => [
                'start_time' => $startTime->toIso8601String(),
                'end_time' => $endTime->toIso8601String(),
                'count' => $pricing->count(),
                'average_price' => $pricing->avg('price_per_kwh'),
                'min_price' => $pricing->min('price_per_kwh'),
                'max_price' => $pricing->max('price_per_kwh'),
            ],
        ]);
    }

    /**
     * Get average pricing for a time range
     */
    public function average(Request $request): JsonResponse
    {
        $request->validate([
            'start_time' => 'required|date',
            'end_time' => 'required|date|after_or_equal:start_time',
        ]);

        $startTime = Carbon::parse($request->start_time);
        $endTime = Carbon::parse($request->end_time);

        $averagePrice = PricingHistory::getAveragePrice($startTime, $endTime);

        return response()->json([
            'average_price' => $averagePrice,
            'currency' => 'USD',
            'start_time' => $startTime->toIso8601String(),
            'end_time' => $endTime->toIso8601String(),
        ]);
    }
}
