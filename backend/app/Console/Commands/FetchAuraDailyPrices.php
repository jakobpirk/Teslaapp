<?php

namespace App\Console\Commands;

use App\Services\AuraElectricityService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class FetchAuraDailyPrices extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'aura:fetch-daily-prices
                            {--date= : Specific date to fetch (Y-m-d format)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Fetch tomorrow\'s Aura electricity prices (runs daily after 17:00)';

    protected AuraElectricityService $auraService;

    /**
     * Create a new command instance.
     */
    public function __construct(AuraElectricityService $auraService)
    {
        parent::__construct();
        $this->auraService = $auraService;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $date = $this->option('date')
            ? Carbon::parse($this->option('date'))
            : Carbon::tomorrow();

        $this->info("Fetching Aura prices for {$date->toDateString()}...");

        try {
            // Check if data already exists
            if (\App\Models\AuraPricingData::existsForDate($date)) {
                $this->warn("Pricing data for {$date->toDateString()} already exists. Skipping...");
                return Command::SUCCESS;
            }

            // Fetch and store pricing data
            $result = $this->auraService->updatePricingForDate($date);

            if (!$result) {
                $this->error("Failed to fetch pricing data from Aura API for {$date->toDateString()}");
                Log::error('Failed to fetch Aura daily prices', [
                    'date' => $date->toDateString(),
                ]);
                return Command::FAILURE;
            }

            // Get hourly counts for both regions
            $eastPrices = $result->getHourlyPricesForRegion('east');
            $westPrices = $result->getHourlyPricesForRegion('west');

            $this->info("✓ Successfully fetched Aura prices for {$date->toDateString()}");
            $this->info("  East region: " . count($eastPrices) . " hourly prices");
            $this->info("  West region: " . count($westPrices) . " hourly prices");

            Log::info('Successfully fetched Aura daily prices', [
                'date' => $date->toDateString(),
                'east_hours' => count($eastPrices),
                'west_hours' => count($westPrices),
            ]);

            return Command::SUCCESS;
        } catch (\Exception $e) {
            $this->error("Error fetching Aura prices: {$e->getMessage()}");
            Log::error('Exception while fetching Aura daily prices', [
                'date' => $date->toDateString(),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return Command::FAILURE;
        }
    }
}
