<?php

namespace App\Services;

use App\Models\ChargingSession;
use App\Models\CarbonIntensityData;
use App\Models\Vehicle;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class CO2StatisticsService
{
    /**
     * Get CO2 statistics for a vehicle.
     */
    public function getVehicleStatistics(string $vehicleId, ?string $startDate = null, ?string $endDate = null): array
    {
        $query = ChargingSession::where('vehicle_id', $vehicleId)
            ->whereNotNull('co2_emitted');

        if ($startDate) {
            $query->where('start_time', '>=', $startDate);
        }

        if ($endDate) {
            $query->where('start_time', '<=', $endDate);
        }

        $sessions = $query->get();

        return $this->calculateStatistics($sessions);
    }

    /**
     * Get CO2 statistics for a user across all vehicles.
     */
    public function getUserStatistics(string $userId, ?string $startDate = null, ?string $endDate = null): array
    {
        $query = ChargingSession::whereHas('vehicle', function ($q) use ($userId) {
            $q->where('user_id', $userId);
        })->whereNotNull('co2_emitted');

        if ($startDate) {
            $query->where('start_time', '>=', $startDate);
        }

        if ($endDate) {
            $query->where('start_time', '<=', $endDate);
        }

        $sessions = $query->with('vehicle')->get();

        return $this->calculateStatistics($sessions);
    }

    /**
     * Calculate statistics from charging sessions.
     */
    private function calculateStatistics($sessions): array
    {
        if ($sessions->isEmpty()) {
            return $this->getEmptyStatistics();
        }

        $totalCO2 = $sessions->sum('co2_emitted'); // grams
        $totalEnergy = $sessions->sum('energy_added'); // kWh
        $avgCO2PerKwh = $totalEnergy > 0 ? $totalCO2 / $totalEnergy : 0;
        $avgRenewable = $sessions->avg('renewable_percentage') ?? 0;

        // Calculate what emissions would have been with grid average
        $gridAverageCO2PerKwh = 400; // Global average ~400g CO2/kWh
        $gridAverageCO2 = $totalEnergy * $gridAverageCO2PerKwh;
        $co2Saved = $gridAverageCO2 - $totalCO2;

        // Calculate equivalent car emissions
        // Average ICE car: ~200g CO2/km, average efficiency ~15 kWh/100km for EV
        $kmDriven = ($totalEnergy / 15) * 100; // Approximate km driven
        $iceCarEmissions = $kmDriven * 200; // grams
        $totalSavingsVsICE = $iceCarEmissions - $totalCO2;

        // Monthly breakdown
        $monthlyData = $this->calculateMonthlyBreakdown($sessions);

        // Renewable vs non-renewable breakdown
        $renewableBreakdown = $this->calculateRenewableBreakdown($sessions);

        return [
            'summary' => [
                'total_co2_emitted' => round($totalCO2, 2), // grams
                'total_co2_kg' => round($totalCO2 / 1000, 2), // kg
                'total_energy_kwh' => round($totalEnergy, 2),
                'avg_co2_per_kwh' => round($avgCO2PerKwh, 2),
                'avg_renewable_percentage' => round($avgRenewable, 2),
                'total_sessions' => $sessions->count(),
            ],
            'savings' => [
                'co2_saved_vs_grid_average' => round($co2Saved, 2), // grams
                'co2_saved_vs_grid_kg' => round($co2Saved / 1000, 2), // kg
                'co2_saved_vs_ice_car' => round($totalSavingsVsICE, 2), // grams
                'co2_saved_vs_ice_kg' => round($totalSavingsVsICE / 1000, 2), // kg
                'equivalent_km_driven' => round($kmDriven, 2),
            ],
            'monthly_breakdown' => $monthlyData,
            'renewable_breakdown' => $renewableBreakdown,
            'comparison' => [
                'grid_average_intensity' => $gridAverageCO2PerKwh,
                'your_average_intensity' => round($avgCO2PerKwh, 2),
                'improvement_percentage' => $gridAverageCO2PerKwh > 0
                    ? round((($gridAverageCO2PerKwh - $avgCO2PerKwh) / $gridAverageCO2PerKwh) * 100, 2)
                    : 0,
            ],
        ];
    }

    /**
     * Calculate monthly breakdown of CO2 emissions.
     */
    private function calculateMonthlyBreakdown($sessions): array
    {
        $monthlyData = $sessions->groupBy(function ($session) {
            return Carbon::parse($session->start_time)->format('Y-m');
        })->map(function ($monthlySessions) {
            $totalCO2 = $monthlySessions->sum('co2_emitted');
            $totalEnergy = $monthlySessions->sum('energy_added');

            return [
                'co2_emitted' => round($totalCO2, 2),
                'co2_kg' => round($totalCO2 / 1000, 2),
                'energy_kwh' => round($totalEnergy, 2),
                'avg_co2_per_kwh' => $totalEnergy > 0 ? round($totalCO2 / $totalEnergy, 2) : 0,
                'session_count' => $monthlySessions->count(),
                'avg_renewable_percentage' => round($monthlySessions->avg('renewable_percentage') ?? 0, 2),
            ];
        })->toArray();

        // Sort by month
        ksort($monthlyData);

        return $monthlyData;
    }

    /**
     * Calculate renewable vs non-renewable energy breakdown.
     */
    private function calculateRenewableBreakdown($sessions): array
    {
        $totalEnergy = $sessions->sum('energy_added');

        // Calculate weighted renewable energy
        $renewableEnergy = $sessions->reduce(function ($carry, $session) {
            $renewable = $session->renewable_percentage ?? 0;
            return $carry + ($session->energy_added * ($renewable / 100));
        }, 0);

        $nonRenewableEnergy = $totalEnergy - $renewableEnergy;

        return [
            'renewable_kwh' => round($renewableEnergy, 2),
            'non_renewable_kwh' => round($nonRenewableEnergy, 2),
            'renewable_percentage' => $totalEnergy > 0
                ? round(($renewableEnergy / $totalEnergy) * 100, 2)
                : 0,
        ];
    }

    /**
     * Get empty statistics structure.
     */
    private function getEmptyStatistics(): array
    {
        return [
            'summary' => [
                'total_co2_emitted' => 0,
                'total_co2_kg' => 0,
                'total_energy_kwh' => 0,
                'avg_co2_per_kwh' => 0,
                'avg_renewable_percentage' => 0,
                'total_sessions' => 0,
            ],
            'savings' => [
                'co2_saved_vs_grid_average' => 0,
                'co2_saved_vs_grid_kg' => 0,
                'co2_saved_vs_ice_car' => 0,
                'co2_saved_vs_ice_kg' => 0,
                'equivalent_km_driven' => 0,
            ],
            'monthly_breakdown' => [],
            'renewable_breakdown' => [
                'renewable_kwh' => 0,
                'non_renewable_kwh' => 0,
                'renewable_percentage' => 0,
            ],
            'comparison' => [
                'grid_average_intensity' => 400,
                'your_average_intensity' => 0,
                'improvement_percentage' => 0,
            ],
        ];
    }

    /**
     * Get CO2 intensity data for a specific time and zone.
     */
    public function getCO2IntensityForChargingSession(Carbon $timestamp, string $zone = 'DK1'): ?array
    {
        $carbonData = CarbonIntensityData::where('zone', $zone)
            ->where('timestamp', '<=', $timestamp)
            ->where('is_forecast', false)
            ->orderBy('timestamp', 'desc')
            ->first();

        if (!$carbonData) {
            // Fall back to forecast data if no actual data available
            $carbonData = CarbonIntensityData::where('zone', $zone)
                ->where('timestamp', '<=', $timestamp)
                ->where('is_forecast', true)
                ->orderBy('timestamp', 'desc')
                ->first();
        }

        if (!$carbonData) {
            return null;
        }

        return [
            'co2_per_kwh' => $carbonData->co2_per_kwh,
            'renewable_percentage' => $carbonData->renewable_percentage,
            'zone' => $carbonData->zone,
        ];
    }

    /**
     * Update CO2 data for existing charging sessions that don't have it.
     */
    public function backfillCO2Data(string $zone = 'DK1'): array
    {
        $sessionsWithoutCO2 = ChargingSession::whereNull('co2_emitted')
            ->whereNotNull('end_time')
            ->get();

        $updated = 0;
        $failed = 0;

        foreach ($sessionsWithoutCO2 as $session) {
            try {
                $co2Data = $this->getCO2IntensityForChargingSession(
                    Carbon::parse($session->start_time),
                    $zone
                );

                if ($co2Data) {
                    $co2Emitted = $session->energy_added * $co2Data['co2_per_kwh'];

                    $session->update([
                        'co2_emitted' => $co2Emitted,
                        'co2_per_kwh' => $co2Data['co2_per_kwh'],
                        'renewable_percentage' => $co2Data['renewable_percentage'],
                        'grid_zone' => $zone,
                    ]);

                    $updated++;
                } else {
                    $failed++;
                }
            } catch (\Exception $e) {
                Log::error('Failed to backfill CO2 data for session', [
                    'session_id' => $session->id,
                    'error' => $e->getMessage(),
                ]);
                $failed++;
            }
        }

        return [
            'updated' => $updated,
            'failed' => $failed,
            'total' => $sessionsWithoutCO2->count(),
        ];
    }

    /**
     * Get top CO2 saving tips for a user.
     */
    public function getSavingTips(string $userId): array
    {
        $stats = $this->getUserStatistics($userId);
        $tips = [];

        // Analyze patterns and provide tips
        $avgRenewable = $stats['summary']['avg_renewable_percentage'] ?? 0;
        $avgCO2 = $stats['summary']['avg_co2_per_kwh'] ?? 0;

        if ($avgRenewable < 50) {
            $tips[] = [
                'title' => 'Charge during high renewable times',
                'description' => 'Your charging sessions average only ' . round($avgRenewable, 0) . '% renewable energy. Try charging when solar and wind production are higher.',
                'priority' => 'high',
            ];
        }

        if ($avgCO2 > 300) {
            $tips[] = [
                'title' => 'Optimize charging schedule',
                'description' => 'Your average CO2 intensity is ' . round($avgCO2, 0) . 'g/kWh. Charging at off-peak times often has lower emissions.',
                'priority' => 'medium',
            ];
        }

        $tips[] = [
            'title' => 'Keep up the good work!',
            'description' => 'You\'ve saved ' . round($stats['savings']['co2_saved_vs_ice_kg'], 2) . ' kg of CO2 compared to driving a gas car.',
            'priority' => 'info',
        ];

        return $tips;
    }
}
