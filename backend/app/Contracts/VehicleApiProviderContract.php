<?php

namespace App\Contracts;

/**
 * Interface for vehicle API provider implementations
 *
 * This contract defines the standard methods that all vehicle API providers
 * (Tessie, Tesla, etc.) must implement to ensure consistent behavior across
 * different vehicle data sources.
 */
interface VehicleApiProviderContract
{
    /**
     * Get the current state of a vehicle
     *
     * @param string $vehicleId The provider-specific vehicle identifier
     * @param string $apiKey The user's API key for this provider
     * @return array Vehicle state data
     * @throws \Exception If the API request fails
     */
    public function getVehicleState(string $vehicleId, string $apiKey): array;

    /**
     * Start charging the vehicle
     *
     * @param string $vehicleId The provider-specific vehicle identifier
     * @param string $apiKey The user's API key for this provider
     * @return array Response data from the provider
     * @throws \Exception If the API request fails
     */
    public function startCharging(string $vehicleId, string $apiKey): array;

    /**
     * Stop charging the vehicle
     *
     * @param string $vehicleId The provider-specific vehicle identifier
     * @param string $apiKey The user's API key for this provider
     * @return array Response data from the provider
     * @throws \Exception If the API request fails
     */
    public function stopCharging(string $vehicleId, string $apiKey): array;

    /**
     * Set the charge limit for the vehicle
     *
     * @param string $vehicleId The provider-specific vehicle identifier
     * @param string $apiKey The user's API key for this provider
     * @param int $limit The charge limit percentage (0-100)
     * @return array Response data from the provider
     * @throws \Exception If the API request fails
     */
    public function setChargeLimit(string $vehicleId, string $apiKey, int $limit): array;

    /**
     * Get the provider name identifier
     *
     * @return string The provider name (e.g., 'tessie', 'tesla', 'nio')
     */
    public function getProviderName(): string;

    /**
     * Validate if the API key is valid for this provider
     *
     * @param string $apiKey The API key to validate
     * @return bool True if the API key is valid
     */
    public function validateApiKey(string $apiKey): bool;
}
