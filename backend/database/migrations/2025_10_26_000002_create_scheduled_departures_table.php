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
        Schema::create('scheduled_departures', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->uuid('user_id');

            // Schedule settings
            $table->time('departure_time')->comment('Target departure time (HH:MM:SS)');
            $table->json('days_of_week')->comment('Array of days: 0=Sun, 1=Mon, ..., 6=Sat');
            $table->string('timezone', 50)->default('UTC')->comment('User timezone');
            $table->boolean('is_enabled')->default(true);

            // Preconditioning settings
            $table->boolean('precondition_climate')->default(true)->comment('Start climate control before departure');
            $table->boolean('precondition_battery')->default(false)->comment('Precondition battery (for range)');
            $table->decimal('target_temperature', 4, 1)->nullable()->comment('Target cabin temperature in Celsius');
            $table->integer('preconditioning_minutes')->default(30)->comment('Minutes before departure to start');

            // Charging settings
            $table->boolean('charge_before_departure')->default(true)->comment('Ensure charging completes before departure');
            $table->integer('target_battery_level')->nullable()->comment('Target charge level %');
            $table->boolean('off_peak_only')->default(false)->comment('Only charge during off-peak hours');

            // Execution tracking
            $table->timestamp('last_executed_at')->nullable();
            $table->json('execution_log')->nullable()->comment('Recent execution history');

            $table->timestamps();

            // Foreign keys
            $table->foreign('vehicle_id')->references('id')->on('vehicles')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');

            // Indexes
            $table->index(['vehicle_id', 'is_enabled']);
            $table->index(['user_id', 'is_enabled']);
            $table->index('departure_time');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('scheduled_departures');
    }
};
