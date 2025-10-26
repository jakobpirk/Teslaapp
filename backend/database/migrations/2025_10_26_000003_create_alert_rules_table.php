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
        Schema::create('alert_rules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->uuid('vehicle_id')->nullable()->comment('NULL applies to all user vehicles');

            // Rule definition
            $table->string('name', 100);
            $table->text('description')->nullable();
            $table->enum('rule_type', [
                'not_plugged_in',
                'battery_low',
                'charge_complete',
                'left_unlocked',
                'sentry_triggered',
                'unusual_energy_consumption',
                'climate_on',
                'software_update_available',
                'custom'
            ])->index();

            // Rule conditions (JSON structure varies by rule_type)
            // Examples:
            // not_plugged_in: {"time_after": "21:00", "location": "home", "days": [1,2,3,4,5]}
            // battery_low: {"threshold": 20, "when_unplugged": true}
            // charge_complete: {"notify_at_percentage": 80}
            // left_unlocked: {"duration_minutes": 10, "location": "away_from_home"}
            $table->json('conditions');

            // Notification settings
            $table->json('notification_channels')->default('["push"]')->comment('push, email, sms');
            $table->string('notification_title', 100)->nullable();
            $table->text('notification_message')->nullable();

            // Control
            $table->boolean('is_enabled')->default(true);
            $table->integer('cooldown_minutes')->default(60)->comment('Minimum time between alerts');
            $table->integer('priority')->default(1)->comment('1=low, 2=medium, 3=high');

            // Tracking
            $table->timestamp('last_triggered_at')->nullable();
            $table->timestamp('last_evaluated_at')->nullable();
            $table->integer('trigger_count')->default(0);

            $table->timestamps();

            // Foreign keys
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('vehicle_id')->references('id')->on('vehicles')->onDelete('cascade');

            // Indexes
            $table->index(['user_id', 'is_enabled']);
            $table->index(['vehicle_id', 'is_enabled']);
            $table->index(['rule_type', 'is_enabled']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('alert_rules');
    }
};
