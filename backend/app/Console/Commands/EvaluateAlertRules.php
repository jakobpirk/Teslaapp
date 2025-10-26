<?php

namespace App\Console\Commands;

use App\Services\AlertRuleService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class EvaluateAlertRules extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'alerts:evaluate
                            {--rule-id= : Specific rule ID to evaluate}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Evaluate all alert rules and send notifications (runs every 10 minutes)';

    protected AlertRuleService $service;

    /**
     * Create a new command instance.
     */
    public function __construct(AlertRuleService $service)
    {
        parent::__construct();
        $this->service = $service;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $ruleId = $this->option('rule-id');

        if ($ruleId) {
            return $this->evaluateSpecificRule($ruleId);
        }

        $this->info('Evaluating all alert rules...');

        try {
            $results = $this->service->evaluateAllRules();

            $triggeredCount = count($results);
            $this->info("Evaluated alert rules. {$triggeredCount} rule(s) triggered.");

            foreach ($results as $result) {
                $ruleId = $result['rule_id'];
                $triggered = $result['result']['triggered'] ?? false;

                if ($triggered) {
                    $context = $result['result']['context'] ?? [];
                    $vehicleName = $context['vehicle_name'] ?? 'Unknown';
                    $message = $result['result']['message'] ?? 'No message';

                    $this->info("✓ Rule {$ruleId} triggered for {$vehicleName}");
                    $this->info("  Message: {$message}");
                }
            }

            Log::info('Alert rules evaluated', [
                'triggered_count' => $triggeredCount,
                'results' => $results,
            ]);

            return Command::SUCCESS;

        } catch (\Exception $e) {
            $this->error('Error evaluating alert rules: ' . $e->getMessage());

            Log::error('Error evaluating alert rules', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return Command::FAILURE;
        }
    }

    /**
     * Evaluate a specific rule.
     */
    private function evaluateSpecificRule(string $ruleId): int
    {
        $this->info("Evaluating rule {$ruleId}...");

        try {
            $rule = \App\Models\AlertRule::findOrFail($ruleId);
            $result = $this->service->evaluateRule($rule);

            if ($result['triggered']) {
                $context = $result['context'] ?? [];
                $vehicleName = $context['vehicle_name'] ?? 'Unknown';
                $message = $result['message'] ?? 'No message';

                $this->info("✓ Rule triggered for {$vehicleName}");
                $this->info("  Message: {$message}");
                $this->info("  Context: " . json_encode($context, JSON_PRETTY_PRINT));
            } else {
                $this->info('Rule conditions not met');
            }

            return Command::SUCCESS;

        } catch (\Exception $e) {
            $this->error('Error evaluating rule: ' . $e->getMessage());
            return Command::FAILURE;
        }
    }
}
