<?php

namespace App\Console\Commands;

use App\Services\Charging\HistoricPriceAnalysisService;
use Illuminate\Console\Command;

class BuildHistoricPriceModels extends Command
{
    protected $signature = 'charging:build-historic-models
                            {--region=* : Pricing regions to build models for (east, west)}
                            {--lookback=180 : Days of historic data to analyze}';

    protected $description = 'Build statistical models from historic pricing data';

    public function handle(): int
    {
        $service = new HistoricPriceAnalysisService();

        $regions = $this->option('region');
        if (empty($regions)) {
            $regions = ['east', 'west']; // Default Danish regions
        }

        $lookbackDays = (int)$this->option('lookback');

        $this->info("Building historic price statistical models...");
        $this->info("Lookback period: {$lookbackDays} days");

        foreach ($regions as $region) {
            $this->info("Processing region: {$region}");

            try {
                $stats = $service->buildStatisticalModels($region, $lookbackDays);

                $total = array_sum($stats);
                $this->info("✓ Built {$total} statistical patterns for {$region}");
                $this->line("  - Hourly: {$stats['hourly']} patterns");
                $this->line("  - Hourly by day: {$stats['hourly_by_day']} patterns");
                $this->line("  - Hourly by month: {$stats['hourly_by_month']} patterns");
            } catch (\Exception $e) {
                $this->error("Failed to build models for {$region}: " . $e->getMessage());
                return 1;
            }
        }

        $this->info("\n✅ Historic price models built successfully!");

        return 0;
    }
}
