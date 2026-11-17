<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role', 16)->default('father')->after('email')->index();
            $table->foreignId('family_id')->nullable()->after('role')->constrained()->nullOnDelete();
            // Consent to the terms and privacy policy, recorded at registration.
            $table->timestamp('terms_accepted_at')->nullable()->after('family_id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('family_id');
            $table->dropColumn(['role', 'terms_accepted_at']);
        });
    }
};
