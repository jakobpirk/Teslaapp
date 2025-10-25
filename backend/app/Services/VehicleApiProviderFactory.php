<?php

namespace App\Services;

use App\Contracts\VehicleApiProviderContract;
use App\Services\Providers\TessieApiProvider;
use App\Services\Providers\TeslaApiProvider;
use Illuminate\Support\Facades\Log;

/**
 * Factory for creating vehicle API provider instances
 *
 * This factory is responsible for instantiating the correct vehicle API provider
 * based on the provider name. It supports multiple providers like Tessie, Tesla, etc.
 */
class VehicleApiProviderFactory
{
    /**
     * Supported API providers
     */
    public const PROVIDER_TESSIE = 'tessie';
    public const PROVIDER_TESLA = 'tesla';
    // Add more providers here as needed
    // public const PROVIDER_NIO = 'nio';
    // public const PROVIDER_XPENG = 'xpeng';

    /**
     * Map of provider names to their implementation classes
     *
     * @var array<string, string>
     */
    private static array $providers = [
        self::PROVIDER_TESSIE => TessieApiProvider::class,
        self::PROVIDER_TESLA => TeslaApiProvider::class,
        // Add more provider mappings here
        // self::PROVIDER_NIO => NioApiProvider::class,
    ];

    /**
     * Cached provider instances
     *
     * @var array<string, VehicleApiProviderContract>
     */
    private static array $instances = [];

    /**
     * Create or retrieve a vehicle API provider instance
     *
     * @param string $providerName The name of the provider (e.g., 'tessie', 'tesla')
     * @return VehicleApiProviderContract
     * @throws \InvalidArgumentException If the provider is not supported
     */
    public static function make(string $providerName): VehicleApiProviderContract
    {
        $providerName = strtolower($providerName);

        // Return cached instance if available
        if (isset(self::$instances[$providerName])) {
            return self::$instances[$providerName];
        }

        // Check if provider is supported
        if (!self::isSupported($providerName)) {
            Log::error('Unsupported vehicle API provider requested', [
                'provider' => $providerName,
                'supported_providers' => array_keys(self::$providers),
            ]);
            throw new \InvalidArgumentException(
                "Unsupported vehicle API provider: {$providerName}. " .
                "Supported providers: " . implode(', ', array_keys(self::$providers))
            );
        }

        // Instantiate the provider
        $providerClass = self::$providers[$providerName];
        $instance = new $providerClass();

        // Cache the instance
        self::$instances[$providerName] = $instance;

        Log::info('Created vehicle API provider instance', [
            'provider' => $providerName,
            'class' => $providerClass,
        ]);

        return $instance;
    }

    /**
     * Check if a provider is supported
     *
     * @param string $providerName The provider name to check
     * @return bool True if the provider is supported
     */
    public static function isSupported(string $providerName): bool
    {
        return isset(self::$providers[strtolower($providerName)]);
    }

    /**
     * Get all supported provider names
     *
     * @return array<string>
     */
    public static function getSupportedProviders(): array
    {
        return array_keys(self::$providers);
    }

    /**
     * Get the default provider name
     *
     * @return string The default provider name (Tessie)
     */
    public static function getDefaultProvider(): string
    {
        return self::PROVIDER_TESSIE;
    }

    /**
     * Register a new provider dynamically
     *
     * This allows for runtime registration of custom providers
     *
     * @param string $providerName The unique name for the provider
     * @param string $providerClass The fully qualified class name
     * @return void
     * @throws \InvalidArgumentException If the class doesn't implement VehicleApiProviderContract
     */
    public static function registerProvider(string $providerName, string $providerClass): void
    {
        if (!class_exists($providerClass)) {
            throw new \InvalidArgumentException("Provider class does not exist: {$providerClass}");
        }

        $interfaces = class_implements($providerClass);
        if (!in_array(VehicleApiProviderContract::class, $interfaces)) {
            throw new \InvalidArgumentException(
                "Provider class must implement VehicleApiProviderContract: {$providerClass}"
            );
        }

        self::$providers[strtolower($providerName)] = $providerClass;

        Log::info('Registered new vehicle API provider', [
            'provider' => $providerName,
            'class' => $providerClass,
        ]);
    }

    /**
     * Clear cached provider instances
     *
     * Useful for testing or when you need to force recreation of providers
     *
     * @return void
     */
    public static function clearCache(): void
    {
        self::$instances = [];
    }
}
