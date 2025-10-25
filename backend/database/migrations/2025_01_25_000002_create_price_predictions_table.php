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
        Schema::create('price_predictions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('region')->index(); // 'east' or 'west'
            $table->string('prediction_model')->index()->comment('holt_winters, pattern_based, ensemble, etc.');

            // Prediction details
            $table->timestamp('predicted_for_timestamp')->index()->comment('The timestamp this prediction is for');
            $table->decimal('predicted_price', 10, 4)->comment('Predicted price per kWh');

            // Confidence intervals
            $table->decimal('confidence_interval_low', 10, 4)->comment('Lower bound of 95% CI');
            $table->decimal('confidence_interval_high', 10, 4)->comment('Upper bound of 95% CI');
            $table->decimal('confidence_score', 5, 2)->comment('Confidence 0-100');

            // Model metadata
            $table->json('prediction_metadata')->nullable()->comment('Model-specific parameters and inputs');

            // Actual values (filled in later for evaluation)
            $table->decimal('actual_price', 10, 4)->nullable()->comment('Actual observed price');
            $table->decimal('prediction_error', 10, 4)->nullable()->comment('Absolute error');
            $table->decimal('prediction_error_percent', 10, 4)->nullable()->comment('Percentage error');

            // When prediction was made (for tracking staleness)
            $table->timestamp('predicted_at')->useCurrent()->comment('When this prediction was generated');

            $table->timestamps();

            // Indexes for querying and evaluation
            $table->index(['predicted_for_timestamp', 'prediction_model'], 'idx_timestamp_model');
            $table->index(['region', 'predicted_for_timestamp'], 'idx_region_timestamp');
            $table->index(['prediction_model', 'predicted_at'], 'idx_model_created');
            $table->index('actual_price'); // For finding predictions to evaluate
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('price_predictions');
    }
};
