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
        Schema::table('users', function (Blueprint $table) {
            $table->text('tessie_api_key')->nullable()->after('password');
            $table->uuid('electricity_provider_id')->nullable()->after('tessie_api_key');

            $table->foreign('electricity_provider_id')
                  ->references('id')
                  ->on('electricity_providers')
                  ->onDelete('set null');

            $table->index('electricity_provider_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['electricity_provider_id']);
            $table->dropColumn(['tessie_api_key', 'electricity_provider_id']);
        });
    }
};
