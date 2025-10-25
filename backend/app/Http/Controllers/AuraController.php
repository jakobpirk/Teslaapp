<?php

namespace App\Http\Controllers;

use App\Services\AuraElectricityService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AuraController extends Controller
{
    protected AuraElectricityService $auraService;

    public function __construct(AuraElectricityService $auraService)
    {
        $this->auraService = $auraService;
    }

    /**
     * Fetch and store Aura pricing data for a specific date.
     * Called by Firebase scheduled function or manually.
     */
    public function fetchPrices(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'date' => 'required|date_format:Y-m-d',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $date = Carbon::parse($request->date);

            Log::info('Fetching Aura prices', [
                'date' => $date->toDateString(),
                'is_scheduled' => $request->header('X-Scheduled-Task') === 'true',
                'is_manual' => $request->header('X-Manual-Trigger') === 'true',
            ]);

            $result = $this->auraService->updatePricingForDate($date);

            if (!$result) {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to fetch pricing data from Aura API',
                    'date' => $date->toDateString(),
                ], 500);
            }

            // Get hourly counts for both regions
            $eastPrices = $result->getHourlyPricesForRegion('east');
            $westPrices = $result->getHourlyPricesForRegion('west');

            return response()->json([
                'success' => true,
                'message' => 'Aura pricing data fetched and stored successfully',
                'date' => $date->toDateString(),
                'east_hours' => count($eastPrices),
                'west_hours' => count($westPrices),
                'data' => [
                    'id' => $result->id,
                    'date' => $result->date,
                    'statistics' => $result->statistics,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching Aura prices', [
                'date' => $request->date,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'An error occurred while fetching Aura prices',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get Aura pricing data for a specific date and region.
     */
    public function getPricing(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'date' => 'required|date_format:Y-m-d',
            'region' => 'required|string|in:east,west',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $date = $request->date;
            $region = $request->region;

            $prices = $this->auraService->getPricingForDate($date, $region);

            if (!$prices) {
                return response()->json([
                    'success' => false,
                    'message' => 'No pricing data available for the specified date',
                    'date' => $date,
                    'region' => $region,
                ], 404);
            }

            return response()->json([
                'success' => true,
                'date' => $date,
                'region' => $region,
                'prices' => $prices,
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting Aura prices', [
                'date' => $request->date,
                'region' => $request->region,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving Aura prices',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Check if tomorrow's prices are available.
     */
    public function checkTomorrowAvailability(): JsonResponse
    {
        try {
            $available = $this->auraService->areTomorrowPricesAvailable();
            $tomorrow = Carbon::tomorrow()->toDateString();

            return response()->json([
                'success' => true,
                'available' => $available,
                'date' => $tomorrow,
                'message' => $available
                    ? 'Tomorrow\'s prices are available'
                    : 'Tomorrow\'s prices are not yet available',
            ]);
        } catch (\Exception $e) {
            Log::error('Error checking tomorrow availability', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'An error occurred',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
