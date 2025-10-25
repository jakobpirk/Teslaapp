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
        Schema::table('pricing_history', function (Blueprint $table) {
            $table->string('region')->nullable()->after('utility_provider');
            $table->integer('hour')->nullable()->after('timestamp');
            $table->date('date')->nullable()->after('timestamp');

            // Add indices for common queries
            $table->index(['date', 'hour', 'region']);
            $table->index(['utility_provider', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pricing_history', function (Blueprint $table) {
            $table->dropIndex(['date', 'hour', 'region']);
            $table->dropIndex(['utility_provider', 'date']);
            $table->dropColumn(['region', 'hour', 'date']);
        });
    }
};
