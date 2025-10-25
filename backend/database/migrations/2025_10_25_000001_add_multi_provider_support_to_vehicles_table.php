<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * This migration adds support for multiple vehicle API providers
     * by adding an api_provider field and making the vehicle_id field generic.
     */
    public function up(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            // Add api_provider field with default 'tessie' for existing records
            $table->string('api_provider')->default('tessie')->after('user_id');

            // Add index for api_provider
            $table->index('api_provider');
        });

        // Rename tessie_vehicle_id to provider_vehicle_id for generic use
        // Note: We keep the unique constraint but it should be combined with api_provider
        Schema::table('vehicles', function (Blueprint $table) {
            // Drop the old unique constraint on tessie_vehicle_id
            $table->dropUnique(['tessie_vehicle_id']);

            // Rename the column
            $table->renameColumn('tessie_vehicle_id', 'provider_vehicle_id');
        });

        // Add a composite unique constraint on provider_vehicle_id and api_provider
        // This ensures that a vehicle ID is unique within each provider
        Schema::table('vehicles', function (Blueprint $table) {
            $table->unique(['provider_vehicle_id', 'api_provider'], 'vehicles_provider_id_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop the composite unique constraint
        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropUnique('vehicles_provider_id_unique');
        });

        // Rename back to tessie_vehicle_id
        Schema::table('vehicles', function (Blueprint $table) {
            $table->renameColumn('provider_vehicle_id', 'tessie_vehicle_id');

            // Restore the original unique constraint
            $table->unique('tessie_vehicle_id');
        });

        // Drop the api_provider field and its index
        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropIndex(['api_provider']);
            $table->dropColumn('api_provider');
        });
    }
};
