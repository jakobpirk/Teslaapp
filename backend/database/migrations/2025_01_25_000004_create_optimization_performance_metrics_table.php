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
        Schema::create('optimization_performance_metrics', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->date('date')->index()->comment('Metrics aggregated for this date');
            $table->string('optimization_version')->index()->comment('Algorithm version');
            $table->string('region')->nullable()->index()->comment('Pricing region if applicable');

            // Volume metrics
            $table->integer('total_decisions')->default(0)->comment('Total optimization decisions made');
            $table->integer('successful_executions')->default(0)->comment('Successfully executed charging sessions');
            $table->integer('failed_executions')->default(0)->comment('Failed charging attempts');
            $table->integer('skipped_decisions')->default(0)->comment('Times user overrode recommendation');

            // Financial performance
            $table->decimal('total_cost', 10, 2)->default(0)->comment('Total charging cost');
            $table->decimal('total_savings', 10, 2)->default(0)->comment('Total savings achieved');
            $table->decimal('avg_cost_savings', 10, 2)->default(0)->comment('Average savings per session');
            $table->decimal('avg_cost_per_session', 10, 2)->default(0)->comment('Average cost per session');

            // Prediction accuracy
            $table->decimal('avg_prediction_accuracy', 5, 2)->default(0)->comment('Average prediction accuracy %');
            $table->decimal('avg_price_prediction_error', 10, 4)->default(0)->comment('Average price prediction error');

            // Factor performance (how well each factor performed)
            $table->json('factor_performance')->nullable()->comment('Performance breakdown by factor');

            // Detailed metrics
            $table->json('metrics_json')->nullable()->comment('Additional detailed metrics');

            $table->timestamps();

            // Composite unique index
            $table->unique(['date', 'optimization_version', 'region'], 'unique_daily_metrics');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('optimization_performance_metrics');
    }
};
