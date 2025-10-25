<?php

namespace App\Http\Controllers;

use App\Models\ElectricityProvider;
use App\Services\ElectricityProviderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ElectricityProviderController extends Controller
{
    protected ElectricityProviderService $providerService;

    public function __construct(ElectricityProviderService $providerService)
    {
        $this->providerService = $providerService;
    }

    /**
     * Get all active electricity providers.
     */
    public function index(): JsonResponse
    {
        $providers = $this->providerService->getActiveProviders();

        return response()->json([
            'success' => true,
            'data' => $providers,
        ]);
    }

    /**
     * Get a specific provider.
     */
    public function show(string $id): JsonResponse
    {
        $provider = ElectricityProvider::findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $provider,
        ]);
    }

    /**
     * Get current pricing for a provider.
     */
    public function getCurrentPricing(Request $request, string $id): JsonResponse
    {
        $provider = ElectricityProvider::findOrFail($id);

        try {
            $pricing = $this->providerService->fetchCurrentPricing($provider);

            return response()->json([
                'success' => true,
                'data' => $pricing,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pricing data',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get pricing forecast for a provider.
     */
    public function getPricingForecast(Request $request, string $id): JsonResponse
    {
        $provider = ElectricityProvider::findOrFail($id);
        $hours = $request->query('hours', 48);

        try {
            $forecast = $this->providerService->fetchPricingForecast($provider, (int) $hours);

            return response()->json([
                'success' => true,
                'data' => $forecast,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pricing forecast',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update and store current pricing for a provider.
     */
    public function updatePricing(Request $request, string $id): JsonResponse
    {
        $provider = ElectricityProvider::findOrFail($id);

        try {
            $pricingHistory = $this->providerService->updateCurrentPricing($provider);

            return response()->json([
                'success' => true,
                'message' => 'Pricing data updated successfully',
                'data' => $pricingHistory,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update pricing data',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update and store pricing forecast.
     */
    public function updateForecast(Request $request, string $id): JsonResponse
    {
        $provider = ElectricityProvider::findOrFail($id);
        $hours = $request->input('hours', 48);

        try {
            $stored = $this->providerService->updatePricingForecast($provider, $hours);

            return response()->json([
                'success' => true,
                'message' => 'Pricing forecast updated successfully',
                'data' => [
                    'records_stored' => count($stored),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update pricing forecast',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
