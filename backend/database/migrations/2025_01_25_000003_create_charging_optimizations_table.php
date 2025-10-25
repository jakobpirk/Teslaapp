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
        Schema::create('charging_optimizations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('vehicle_id')->constrained('vehicles')->onDelete('cascade');
            $table->foreignUuid('charging_recommendation_id')->nullable()->constrained('charging_recommendations')->onDelete('set null');

            // Decision context
            $table->timestamp('decision_timestamp')->index()->comment('When optimization decision was made');
            $table->string('optimization_version')->default('v2_multi_factor')->comment('Algorithm version for A/B testing');

            // Recommended window
            $table->timestamp('recommended_window_start');
            $table->timestamp('recommended_window_end');
            $table->boolean('was_executed')->default(false);

            // Cost predictions
            $table->decimal('predicted_cost', 10, 2)->comment('Predicted total cost');
            $table->decimal('predicted_savings', 10, 2)->comment('Predicted savings vs charging now');
            $table->decimal('actual_cost', 10, 2)->nullable()->comment('Actual cost (filled after charging)');
            $table->decimal('cost_variance', 10, 2)->nullable()->comment('Difference between predicted and actual');

            // Factors used in decision
            $table->json('factors_used')->comment('Array of factor names used');
            $table->json('factors_breakdown')->comment('Detailed score breakdown per factor');
            $table->json('factor_weights')->comment('Weights used for each factor');

            // External data snapshots (for analysis)
            $table->json('weather_data')->nullable()->comment('Weather forecast at decision time');
            $table->json('carbon_data')->nullable()->comment('Carbon intensity forecast');
            $table->json('price_data')->nullable()->comment('Price data/predictions used');

            // Performance metrics
            $table->decimal('composite_score', 5, 2)->comment('Final optimization score 0-100');
            $table->decimal('prediction_accuracy', 5, 2)->nullable()->comment('How accurate was prediction');

            $table->timestamps();

            // Indexes for analysis
            $table->index(['vehicle_id', 'decision_timestamp'], 'idx_vehicle_decision');
            $table->index(['optimization_version', 'decision_timestamp'], 'idx_version_decision');
            $table->index('was_executed');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('charging_optimizations');
    }
};
