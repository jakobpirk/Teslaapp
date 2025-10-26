<?php

namespace App\Console\Commands;

use App\Services\ScheduledDepartureService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class ProcessScheduledDepartures extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'departures:process';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Process scheduled departures and execute preconditioning (runs every 5 minutes)';

    protected ScheduledDepartureService $service;

    /**
     * Create a new command instance.
     */
    public function __construct(ScheduledDepartureService $service)
    {
        parent::__construct();
        $this->service = $service;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Processing scheduled departures...');

        try {
            $results = $this->service->processScheduledDepartures();

            $this->info('Processed ' . count($results) . ' scheduled departure(s)');

            foreach ($results as $result) {
                $scheduleId = $result['schedule_id'];
                $vehicleId = $result['vehicle_id'];
                $success = $result['result']['success'] ?? false;

                if ($success) {
                    $actionCount = count($result['result']['actions'] ?? []);
                    $this->info("✓ Schedule {$scheduleId} (Vehicle: {$vehicleId}): {$actionCount} action(s) completed");

                    // Show each action
                    foreach ($result['result']['actions'] ?? [] as $action) {
                        $actionType = $action['action'];
                        $actionSuccess = $action['result']['success'] ?? false;
                        $message = $action['result']['message'] ?? 'No message';

                        if ($actionSuccess) {
                            $this->info("  ✓ {$actionType}: {$message}");
                        } else {
                            $error = $action['result']['error'] ?? 'Unknown error';
                            $this->warn("  ✗ {$actionType}: {$error}");
                        }
                    }
                } else {
                    $error = $result['result']['error'] ?? 'Unknown error';
                    $this->error("✗ Schedule {$scheduleId} (Vehicle: {$vehicleId}): {$error}");
                }
            }

            Log::info('Scheduled departures processed', [
                'count' => count($results),
                'results' => $results,
            ]);

            return Command::SUCCESS;

        } catch (\Exception $e) {
            $this->error('Error processing scheduled departures: ' . $e->getMessage());

            Log::error('Error processing scheduled departures', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return Command::FAILURE;
        }
    }
}
