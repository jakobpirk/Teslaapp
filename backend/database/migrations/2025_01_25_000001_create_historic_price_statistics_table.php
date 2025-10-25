<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('historic_price_statistics', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('region')->index(); // 'east' or 'west'
            $table->integer('hour_of_day')->comment('0-23'); // Hour of day
            $table->integer('day_of_week')->nullable()->comment('0-6, 0=Monday'); // Day of week
            $table->integer('month')->nullable()->comment('1-12'); // Month of year

            // Statistical metrics
            $table->decimal('avg_price', 10, 4)->comment('Average price per kWh');
            $table->decimal('median_price', 10, 4)->comment('Median price per kWh');
            $table->decimal('min_price', 10, 4)->comment('Minimum observed price');
            $table->decimal('max_price', 10, 4)->comment('Maximum observed price');

            // Percentiles for distribution analysis
            $table->decimal('percentile_10', 10, 4)->comment('10th percentile');
            $table->decimal('percentile_25', 10, 4)->comment('25th percentile (Q1)');
            $table->decimal('percentile_75', 10, 4)->comment('75th percentile (Q3)');
            $table->decimal('percentile_90', 10, 4)->comment('90th percentile');

            // Variability metrics
            $table->decimal('std_deviation', 10, 4)->comment('Standard deviation');
            $table->decimal('variance', 10, 4)->comment('Price variance');

            // Metadata
            $table->integer('sample_count')->comment('Number of data points in calculation');
            $table->date('data_start_date')->comment('Earliest date in sample');
            $table->date('data_end_date')->comment('Latest date in sample');
            $table->timestamp('last_updated')->useCurrent();

            $table->timestamps();

            // Composite indexes for fast querying
            $table->index(['region', 'hour_of_day', 'day_of_week'], 'idx_region_hour_dow');
            $table->index(['region', 'month', 'hour_of_day'], 'idx_region_month_hour');
            $table->index(['region', 'hour_of_day'], 'idx_region_hour');

            // Ensure unique statistical records
            $table->unique(['region', 'hour_of_day', 'day_of_week', 'month'], 'unique_stat_pattern');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('historic_price_statistics');
    }
};
