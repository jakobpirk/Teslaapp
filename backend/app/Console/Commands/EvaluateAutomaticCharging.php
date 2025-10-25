<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Models\Vehicle;
use App\Services\ChargingEvaluationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class EvaluateAutomaticCharging extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'charging:evaluate
                            {--vehicle-id= : Specific vehicle ID to evaluate}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Evaluate automatic charging for all vehicles (runs every 10 minutes)';

    protected ChargingEvaluationService $chargingEvaluationService;

    /**
     * Create a new command instance.
     */
    public function __construct(ChargingEvaluationService $chargingEvaluationService)
    {
        parent::__construct();
        $this->chargingEvaluationService = $chargingEvaluationService;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $vehicleId = $this->option('vehicle-id');

        if ($vehicleId) {
            // Evaluate specific vehicle
            return $this->evaluateVehicle($vehicleId);
        }

        // Evaluate all active vehicles with automatic charging enabled
        $this->info('Starting automatic charging evaluation for all vehicles...');

        $users = User::whereHas('vehicles', function ($query) {
            $query->where('is_active', true);
        })
        ->where('auto_charging_enabled', true)
        ->with(['vehicles' => function ($query) {
            $query->where('is_active', true);
        }])
        ->get();

        $totalVehicles = 0;
        $successCount = 0;
        $failureCount = 0;

        foreach ($users as $user) {
            foreach ($user->vehicles as $vehicle) {
                $totalVehicles++;

                try {
                    $result = $this->chargingEvaluationService->evaluateAndExecute($vehicle, $user);

                    if ($result['success']) {
                        $successCount++;

                        if ($result['action_taken']) {
                            $this->info("✓ Vehicle {$vehicle->display_name}: {$result['action']}");
                        }
                    } else {
                        $failureCount++;
                        $this->warn("✗ Vehicle {$vehicle->display_name}: {$result['message']}");
                    }
                } catch (\Exception $e) {
                    $failureCount++;
                    $this->error("✗ Vehicle {$vehicle->display_name}: {$e->getMessage()}");
                    Log::error('Error evaluating vehicle charging', [
                        'vehicle_id' => $vehicle->id,
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        }

        $this->newLine();
        $this->info("=== Evaluation Summary ===");
        $this->info("Total vehicles: {$totalVehicles}");
        $this->info("Successful: {$successCount}");
        $this->info("Failed: {$failureCount}");

        return $failureCount > 0 ? Command::FAILURE : Command::SUCCESS;
    }

    /**
     * Evaluate a specific vehicle.
     */
    protected function evaluateVehicle(string $vehicleId): int
    {
        $vehicle = Vehicle::with('user')->find($vehicleId);

        if (!$vehicle) {
            $this->error("Vehicle not found: {$vehicleId}");
            return Command::FAILURE;
        }

        if (!$vehicle->is_active) {
            $this->warn("Vehicle {$vehicle->display_name} is not active");
            return Command::FAILURE;
        }

        if (!$vehicle->user->auto_charging_enabled) {
            $this->warn("Automatic charging is not enabled for this user");
            return Command::FAILURE;
        }

        $this->info("Evaluating charging for vehicle: {$vehicle->display_name}");

        try {
            $result = $this->chargingEvaluationService->evaluateAndExecute($vehicle, $vehicle->user);

            if ($result['success']) {
                $this->info("✓ {$result['message']}");
                if ($result['action_taken']) {
                    $this->info("  Action: {$result['action']}");
                }
                return Command::SUCCESS;
            } else {
                $this->error("✗ {$result['message']}");
                return Command::FAILURE;
            }
        } catch (\Exception $e) {
            $this->error("Error: {$e->getMessage()}");
            return Command::FAILURE;
        }
    }
}
