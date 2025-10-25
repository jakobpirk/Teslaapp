<?php

namespace App\Services;

use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TessieService
{
    private const BASE_URL = 'https://api.tessie.com';
    private const TIMEOUT = 30; // seconds

    /**
     * Get vehicle state from Tessie API.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @return array|null
     */
    public function getVehicleState(Vehicle $vehicle, User $user): ?array
    {
        if (!$user->hasTessieApiKey()) {
            Log::warning('User does not have Tessie API key', [
                'user_id' => $user->id,
                'vehicle_id' => $vehicle->id,
            ]);
            return null;
        }

        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $user->tessie_api_key,
                ])
                ->get(self::BASE_URL . '/' . $vehicle->tessie_vehicle_id . '/state');

            if (!$response->successful()) {
                Log::error('Failed to fetch vehicle state from Tessie', [
                    'vehicle_id' => $vehicle->id,
                    'tessie_vehicle_id' => $vehicle->tessie_vehicle_id,
                    'status' => $response->status(),
                ]);
                return null;
            }

            $data = $response->json();

            return [
                'battery_level' => $data['charge_state']['battery_level'] ?? 0,
                'battery_range' => $data['charge_state']['battery_range'] ?? 0,
                'charging_state' => $data['charge_state']['charging_state'] ?? 'Disconnected',
                'is_charging' => ($data['charge_state']['charging_state'] ?? '') === 'Charging',
                'charge_rate' => $data['charge_state']['charge_rate'] ?? 0,
                'charge_limit_soc' => $data['charge_state']['charge_limit_soc'] ?? 80,
                'is_plugged_in' => in_array(
                    $data['charge_state']['charging_state'] ?? '',
                    ['Charging', 'Stopped', 'Complete']
                ),
                'raw_data' => $data,
            ];
        } catch (\Exception $e) {
            Log::error('Exception while fetching vehicle state from Tessie', [
                'vehicle_id' => $vehicle->id,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Start charging a vehicle.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @return bool
     */
    public function startCharging(Vehicle $vehicle, User $user): bool
    {
        if (!$user->hasTessieApiKey()) {
            return false;
        }

        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $user->tessie_api_key,
                ])
                ->post(self::BASE_URL . '/' . $vehicle->tessie_vehicle_id . '/command/start_charging');

            if ($response->successful()) {
                Log::info('Successfully started charging', [
                    'vehicle_id' => $vehicle->id,
                    'vehicle_name' => $vehicle->display_name,
                ]);
                return true;
            }

            Log::warning('Failed to start charging', [
                'vehicle_id' => $vehicle->id,
                'status' => $response->status(),
                'response' => $response->body(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('Exception while starting charging', [
                'vehicle_id' => $vehicle->id,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Stop charging a vehicle.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @return bool
     */
    public function stopCharging(Vehicle $vehicle, User $user): bool
    {
        if (!$user->hasTessieApiKey()) {
            return false;
        }

        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $user->tessie_api_key,
                ])
                ->post(self::BASE_URL . '/' . $vehicle->tessie_vehicle_id . '/command/stop_charging');

            if ($response->successful()) {
                Log::info('Successfully stopped charging', [
                    'vehicle_id' => $vehicle->id,
                    'vehicle_name' => $vehicle->display_name,
                ]);
                return true;
            }

            Log::warning('Failed to stop charging', [
                'vehicle_id' => $vehicle->id,
                'status' => $response->status(),
                'response' => $response->body(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('Exception while stopping charging', [
                'vehicle_id' => $vehicle->id,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Set charge limit for a vehicle.
     *
     * @param Vehicle $vehicle
     * @param User $user
     * @param int $percent
     * @return bool
     */
    public function setChargeLimit(Vehicle $vehicle, User $user, int $percent): bool
    {
        if (!$user->hasTessieApiKey()) {
            return false;
        }

        try {
            $response = Http::timeout(self::TIMEOUT)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $user->tessie_api_key,
                ])
                ->post(self::BASE_URL . '/' . $vehicle->tessie_vehicle_id . '/command/set_charge_limit', [
                    'percent' => $percent,
                ]);

            if ($response->successful()) {
                Log::info('Successfully set charge limit', [
                    'vehicle_id' => $vehicle->id,
                    'vehicle_name' => $vehicle->display_name,
                    'percent' => $percent,
                ]);
                return true;
            }

            Log::warning('Failed to set charge limit', [
                'vehicle_id' => $vehicle->id,
                'percent' => $percent,
                'status' => $response->status(),
                'response' => $response->body(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('Exception while setting charge limit', [
                'vehicle_id' => $vehicle->id,
                'percent' => $percent,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }
}
