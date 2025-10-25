<?php

namespace App\Services\Providers;

use App\Contracts\VehicleApiProviderContract;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Tessie API Provider Implementation
 *
 * This provider implements the VehicleApiProviderContract for the Tessie API,
 * which provides access to Tesla vehicle data and commands.
 *
 * @see https://developer.tessie.com/
 */
class TessieApiProvider implements VehicleApiProviderContract
{
    private const BASE_URL = 'https://api.tessie.com';
    private const TIMEOUT = 30; // seconds
    private const PROVIDER_NAME = 'tessie';

    /**
     * Get the current state of a vehicle from Tessie API
     *
     * @param string $vehicleId The Tessie vehicle identifier
     * @param string $apiKey The user's Tessie API key
     * @return array Normalized vehicle state data
     * @throws \Exception If the API request fails
     */
    public function getVehicleState(string $vehicleId, string $apiKey): array
    {
        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                ])
                ->get(self::BASE_URL . '/' . $vehicleId . '/state');

            if (!$response->successful()) {
                Log::error('Failed to fetch vehicle state from Tessie', [
                    'tessie_vehicle_id' => $vehicleId,
                    'status' => $response->status(),
                    'response' => $response->body(),
                ]);
                throw new \Exception('Failed to fetch vehicle state: ' . $response->status());
            }

            $data = $response->json();

            // Validate response structure
            if (!isset($data['charge_state'])) {
                Log::error('Invalid Tessie API response structure', [
                    'tessie_vehicle_id' => $vehicleId,
                    'response' => $data,
                ]);
                throw new \Exception('Invalid response structure from Tessie API');
            }

            $chargeState = $data['charge_state'];

            // Return normalized data structure
            return [
                'battery_level' => $chargeState['battery_level'] ?? 0,
                'battery_range' => $chargeState['battery_range'] ?? 0,
                'charging_state' => $chargeState['charging_state'] ?? 'Disconnected',
                'is_charging' => ($chargeState['charging_state'] ?? '') === 'Charging',
                'charge_rate' => $chargeState['charge_rate'] ?? 0,
                'charge_limit_soc' => $chargeState['charge_limit_soc'] ?? 80,
                'is_plugged_in' => in_array(
                    $chargeState['charging_state'] ?? '',
                    ['Charging', 'Stopped', 'Complete']
                ),
                'raw_data' => $data,
            ];
        } catch (\Exception $e) {
            Log::error('Exception while fetching vehicle state from Tessie', [
                'tessie_vehicle_id' => $vehicleId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            throw $e;
        }
    }

    /**
     * Start charging the vehicle via Tessie API
     *
     * @param string $vehicleId The Tessie vehicle identifier
     * @param string $apiKey The user's Tessie API key
     * @return array Response data from Tessie
     * @throws \Exception If the API request fails
     */
    public function startCharging(string $vehicleId, string $apiKey): array
    {
        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                ])
                ->post(self::BASE_URL . '/' . $vehicleId . '/command/start_charging');

            if (!$response->successful()) {
                Log::warning('Failed to start charging via Tessie', [
                    'tessie_vehicle_id' => $vehicleId,
                    'status' => $response->status(),
                    'response' => $response->body(),
                ]);
                throw new \Exception('Failed to start charging: ' . $response->status());
            }

            Log::info('Successfully started charging via Tessie', [
                'tessie_vehicle_id' => $vehicleId,
            ]);

            return $response->json();
        } catch (\Exception $e) {
            Log::error('Exception while starting charging via Tessie', [
                'tessie_vehicle_id' => $vehicleId,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Stop charging the vehicle via Tessie API
     *
     * @param string $vehicleId The Tessie vehicle identifier
     * @param string $apiKey The user's Tessie API key
     * @return array Response data from Tessie
     * @throws \Exception If the API request fails
     */
    public function stopCharging(string $vehicleId, string $apiKey): array
    {
        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                ])
                ->post(self::BASE_URL . '/' . $vehicleId . '/command/stop_charging');

            if (!$response->successful()) {
                Log::warning('Failed to stop charging via Tessie', [
                    'tessie_vehicle_id' => $vehicleId,
                    'status' => $response->status(),
                    'response' => $response->body(),
                ]);
                throw new \Exception('Failed to stop charging: ' . $response->status());
            }

            Log::info('Successfully stopped charging via Tessie', [
                'tessie_vehicle_id' => $vehicleId,
            ]);

            return $response->json();
        } catch (\Exception $e) {
            Log::error('Exception while stopping charging via Tessie', [
                'tessie_vehicle_id' => $vehicleId,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Set the charge limit for the vehicle via Tessie API
     *
     * @param string $vehicleId The Tessie vehicle identifier
     * @param string $apiKey The user's Tessie API key
     * @param int $limit The charge limit percentage (0-100)
     * @return array Response data from Tessie
     * @throws \Exception If the API request fails
     */
    public function setChargeLimit(string $vehicleId, string $apiKey, int $limit): array
    {
        // Validate limit range
        if ($limit < 0 || $limit > 100) {
            throw new \InvalidArgumentException('Charge limit must be between 0 and 100');
        }

        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                ])
                ->post(self::BASE_URL . '/' . $vehicleId . '/command/set_charge_limit', [
                    'percent' => $limit,
                ]);

            if (!$response->successful()) {
                Log::warning('Failed to set charge limit via Tessie', [
                    'tessie_vehicle_id' => $vehicleId,
                    'limit' => $limit,
                    'status' => $response->status(),
                    'response' => $response->body(),
                ]);
                throw new \Exception('Failed to set charge limit: ' . $response->status());
            }

            Log::info('Successfully set charge limit via Tessie', [
                'tessie_vehicle_id' => $vehicleId,
                'limit' => $limit,
            ]);

            return $response->json();
        } catch (\Exception $e) {
            Log::error('Exception while setting charge limit via Tessie', [
                'tessie_vehicle_id' => $vehicleId,
                'limit' => $limit,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Get the provider name identifier
     *
     * @return string The provider name 'tessie'
     */
    public function getProviderName(): string
    {
        return self::PROVIDER_NAME;
    }

    /**
     * Validate if the API key is valid for Tessie
     *
     * This performs a simple check by attempting to make a request to the Tessie API.
     * For a more thorough validation, consider implementing a dedicated endpoint check.
     *
     * @param string $apiKey The API key to validate
     * @return bool True if the API key appears to be valid
     */
    public function validateApiKey(string $apiKey): bool
    {
        if (empty($apiKey)) {
            return false;
        }

        try {
            // Try to make a simple request to validate the key
            // Note: This is a basic check. Tessie might have a dedicated validation endpoint
            $response = Http::timeout(5)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                ])
                ->get(self::BASE_URL);

            // If we get any 2xx response, the key is likely valid
            // 401 or 403 would indicate invalid credentials
            return $response->successful() || $response->status() !== 401;
        } catch (\Exception $e) {
            Log::warning('Failed to validate Tessie API key', [
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }
}
