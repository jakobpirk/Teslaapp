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
        Schema::table('charging_recommendations', function (Blueprint $table) {
            // Change vehicle_id to uuid if it isn't already
            $table->uuid('vehicle_id')->change();

            // Add foreign key constraint
            $table->foreign('vehicle_id')
                  ->references('id')
                  ->on('vehicles')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('charging_recommendations', function (Blueprint $table) {
            $table->dropForeign(['vehicle_id']);
        });
    }
};
