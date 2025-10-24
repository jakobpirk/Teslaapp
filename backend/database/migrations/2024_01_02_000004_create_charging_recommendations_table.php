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
        Schema::create('charging_recommendations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('vehicle_id')->index();
            $table->timestamp('recommended_start_time')->index();
            $table->timestamp('recommended_end_time')->nullable();
            $table->decimal('estimated_cost', 10, 2)->nullable();
            $table->decimal('cost_savings', 10, 2)->nullable(); // vs charging now
            $table->integer('confidence_score')->default(0); // 0-100
            $table->boolean('should_charge_now')->default(false);
            $table->json('factor_scores')->nullable(); // Breakdown by factor
            $table->text('reasoning')->nullable(); // Human-readable explanation
            $table->string('status')->default('pending'); // 'pending', 'accepted', 'rejected', 'executed'
            $table->timestamp('executed_at')->nullable();
            $table->timestamps();

            $table->index(['vehicle_id', 'recommended_start_time']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('charging_recommendations');
    }
};
