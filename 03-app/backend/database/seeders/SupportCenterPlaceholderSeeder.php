<?php

namespace Database\Seeders;

use App\Enums\CenterKind;
use App\Models\SupportCenter;
use Illuminate\Database\Seeder;

class SupportCenterPlaceholderSeeder extends Seeder
{
    public function run(): void
    {
        foreach (CenterKind::cases() as $kind) {
            SupportCenter::firstOrCreate(['name' => 'بيانات تجريبية - '.$kind->label()], ['kind' => $kind, 'wilaya' => '16', 'phone' => '0000000000', 'notes' => 'بيانات تجريبية، رقم وهمي غير صالح للاتصال.', 'is_published' => false]);
        }
    }
}
