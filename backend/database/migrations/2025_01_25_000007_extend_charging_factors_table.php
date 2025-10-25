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
        Schema::table('charging_factors', function (Blueprint $table) {
            // Add new columns for advanced optimization
            $table->boolean('requires_historic_data')->default(false)->after('is_enabled')
                ->comment('Whether this factor uses historic data');

            $table->string('prediction_model')->nullable()->after('requires_historic_data')
                ->comment('Prediction model used (if any)');

            $table->enum('data_source_type', ['api', 'historic', 'calculated', 'database'])
                ->default('database')->after('prediction_model')
                ->comment('Where factor data comes from');

            $table->integer('update_frequency')->default(60)->after('data_source_type')
                ->comment('Update frequency in minutes');

            $table->integer('historic_lookback_days')->default(90)->after('update_frequency')
                ->comment('Days of historic data to analyze');

            $table->decimal('performance_score', 5, 2)->nullable()->after('historic_lookback_days')
                ->comment('Recent performance score 0-100');

            $table->timestamp('last_performance_update')->nullable()->after('performance_score')
                ->comment('When performance was last calculated');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('charging_factors', function (Blueprint $table) {
            $table->dropColumn([
                'requires_historic_data',
                'prediction_model',
                'data_source_type',
                'update_frequency',
                'historic_lookback_days',
                'performance_score',
                'last_performance_update',
            ]);
        });
    }
};
