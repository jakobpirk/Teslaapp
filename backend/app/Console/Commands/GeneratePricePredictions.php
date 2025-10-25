<?php

namespace App\Console\Commands;

use App\Services\Charging\PricePredictionService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class GeneratePricePredictions extends Command
{
    protected $signature = 'charging:generate-predictions
                            {--region=* : Regions to generate predictions for}
                            {--hours=48 : Hours ahead to predict}
                            {--model=ensemble : Prediction model to use}';

    protected $description = 'Generate price predictions for future hours';

    public function handle(): int
    {
        $service = new PricePredictionService();

        $regions = $this->option('region');
        if (empty($regions)) {
            $regions = ['east', 'west'];
        }

        $hoursAhead = (int)$this->option('hours');
        $model = $this->option('model');

        $this->info("Generating {$hoursAhead}h price predictions using {$model} model...");

        $startTime = now();
        $endTime = now()->addHours($hoursAhead);

        foreach ($regions as $region) {
            $this->info("Generating predictions for region: {$region}");

            try {
                $predictions = $service->predictPrices($startTime, $endTime, $region, $model);

                $this->info("✓ Generated {$predictions->count()} predictions for {$region}");

                // Show sample
                $sample = $predictions->take(5);
                $this->line("Sample predictions:");
                foreach ($sample as $prediction) {
                    $this->line(sprintf(
                        "  %s: $%.4f (confidence: %.1f%%)",
                        $prediction['timestamp']->format('Y-m-d H:i'),
                        $prediction['price'],
                        $prediction['confidence_score']
                    ));
                }
            } catch (\Exception $e) {
                $this->error("Failed to generate predictions for {$region}: " . $e->getMessage());
                return 1;
            }
        }

        $this->info("\n✅ Price predictions generated successfully!");

        return 0;
    }
}
