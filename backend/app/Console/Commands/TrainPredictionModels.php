<?php

namespace App\Console\Commands;

use App\Services\Charging\PricePredictionService;
use Illuminate\Console\Command;

class TrainPredictionModels extends Command
{
    protected $signature = 'charging:train-prediction-models
                            {--region=* : Regions to train models for}
                            {--lookback=180 : Days of data to use for training}';

    protected $description = 'Train ML prediction models for price forecasting';

    public function handle(): int
    {
        $service = new PricePredictionService();

        $regions = $this->option('region');
        if (empty($regions)) {
            $regions = ['east', 'west'];
        }

        $lookbackDays = (int)$this->option('lookback');

        $this->info("Training prediction models...");

        foreach ($regions as $region) {
            $this->info("Training models for region: {$region}");

            try {
                $results = $service->trainModels($region, $lookbackDays);

                $this->line("Results:");
                foreach ($results as $model => $status) {
                    $icon = $status === 'success' ? '✓' : '✗';
                    $this->line("  {$icon} {$model}: {$status}");
                }
            } catch (\Exception $e) {
                $this->error("Failed to train models for {$region}: " . $e->getMessage());
                return 1;
            }
        }

        $this->info("\n✅ Prediction models trained successfully!");

        return 0;
    }
}
