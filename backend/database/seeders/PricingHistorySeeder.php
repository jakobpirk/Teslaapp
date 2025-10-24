<?php

namespace Database\Seeders;

use App\Models\PricingHistory;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class PricingHistorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Creates mock pricing data for today and tomorrow with realistic time-of-use patterns
     */
    public function run(): void
    {
        // Clear existing data
        PricingHistory::truncate();

        $startDate = Carbon::now()->startOfDay();
        $endDate = Carbon::now()->addDays(2)->endOfDay(); // Today + Tomorrow + a bit

        $location = 'default';
        $currency = 'USD';

        $current = $startDate->copy();

        while ($current <= $endDate) {
            $hour = $current->hour;

            // Time-of-use pricing pattern
            // Off-peak: 11pm - 7am (low prices)
            // Mid-peak: 7am - 4pm, 9pm - 11pm (medium prices)
            // Peak: 4pm - 9pm (high prices)

            $rateType = $this->getRateType($hour);
            $pricePerKwh = $this->getPriceForRateType($rateType);

            PricingHistory::create([
                'id' => Str::uuid(),
                'timestamp' => $current->copy(),
                'price_per_kwh' => $pricePerKwh,
                'currency' => $currency,
                'location' => $location,
                'utility_provider' => 'Mock Utility Company',
                'rate_type' => $rateType,
                'metadata' => [
                    'source' => 'mock_data',
                    'generated_at' => now()->toIso8601String(),
                ],
            ]);

            $current->addHour();
        }

        $this->command->info('Created pricing history for today and tomorrow');
        $this->command->info('Total records: ' . PricingHistory::count());
    }

    /**
     * Determine rate type based on hour
     */
    private function getRateType(int $hour): string
    {
        if ($hour >= 23 || $hour < 7) {
            return 'off-peak';
        } elseif ($hour >= 16 && $hour < 21) {
            return 'peak';
        } else {
            return 'mid-peak';
        }
    }

    /**
     * Get price based on rate type with some randomization
     */
    private function getPriceForRateType(string $rateType): float
    {
        $basePrice = match ($rateType) {
            'off-peak' => 0.10,
            'mid-peak' => 0.175,
            'peak' => 0.30,
            default => 0.15,
        };

        // Add 10% variance
        $variance = $basePrice * 0.10;
        $randomVariance = (rand(-100, 100) / 100) * $variance;

        return round($basePrice + $randomVariance, 4);
    }
}
