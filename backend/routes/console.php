<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

// Fetch tomorrow's Aura electricity prices daily at 17:05 CET
// Tomorrow's prices are typically released after 17:00
Schedule::command('aura:fetch-daily-prices')
    ->dailyAt('17:05')
    ->timezone('Europe/Copenhagen')
    ->description('Fetch tomorrow\'s Aura electricity prices');

// Evaluate automatic charging for all vehicles every 10 minutes
// This checks user preferences, battery levels, and pricing to determine
// if charging should start or stop
Schedule::command('charging:evaluate')
    ->everyTenMinutes()
    ->description('Evaluate automatic charging for all vehicles');
