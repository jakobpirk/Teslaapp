<?php

namespace App\Console\Commands;

use App\Services\AuraElectricityService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SeedAuraHistoricalPrices extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'aura:seed-historical-prices
                            {--months=6 : Number of months to go back}
                            {--delay=1 : Delay in seconds between API calls}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Seed historical electricity prices from Aura API for the last N months';

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
        $months = (int) $this->option('months');
        $delay = (int) $this->option('delay');

        $this->info("Starting to seed Aura historical prices for the last {$months} months...");
        $this->info("Delay between requests: {$delay} second(s)");

        $startDate = Carbon::now()->subMonths($months)->startOfDay();
        $endDate = Carbon::yesterday()->endOfDay();

        $totalDays = $startDate->diffInDays($endDate) + 1;
        $this->info("Will fetch prices for {$totalDays} days from {$startDate->toDateString()} to {$endDate->toDateString()}");

        $progressBar = $this->output->createProgressBar($totalDays);
        $progressBar->start();

        $currentDate = $startDate->copy();
        $successCount = 0;
        $failureCount = 0;
        $skippedCount = 0;

        while ($currentDate->lte($endDate)) {
            try {
                // Check if data already exists for this date
                if (\App\Models\AuraPricingData::existsForDate($currentDate)) {
                    $this->newLine();
                    $this->warn("Skipping {$currentDate->toDateString()} - data already exists");
                    $skippedCount++;
                } else {
                    // Fetch and store pricing data
                    $result = $this->auraService->updatePricingForDate($currentDate);

                    if ($result) {
                        $successCount++;
                    } else {
                        $this->newLine();
                        $this->error("Failed to fetch data for {$currentDate->toDateString()}");
                        $failureCount++;
                    }

                    // Delay to avoid spamming the API
                    if ($delay > 0 && $currentDate->lt($endDate)) {
                        sleep($delay);
                    }
                }
            } catch (\Exception $e) {
                $this->newLine();
                $this->error("Exception for {$currentDate->toDateString()}: {$e->getMessage()}");
                $failureCount++;
            }

            $progressBar->advance();
            $currentDate->addDay();
        }

        $progressBar->finish();
        $this->newLine(2);

        // Summary
        $this->info('=== Summary ===');
        $this->info("Total days processed: {$totalDays}");
        $this->info("Successfully fetched: {$successCount}");
        $this->info("Skipped (already exists): {$skippedCount}");
        $this->info("Failed: {$failureCount}");

        if ($failureCount > 0) {
            $this->warn('Some dates failed to fetch. Check the logs for more details.');
            return Command::FAILURE;
        }

        $this->info('Historical price seeding completed successfully!');
        return Command::SUCCESS;
    }
}
