<?php

namespace Database\Seeders;

use App\Enums\ContentType;
use App\Enums\Role;
use App\Models\Content;
use App\Models\User;
use Illuminate\Database\Seeder;

/** Opt-in demonstration content only. Never called by DatabaseSeeder. */
class ContentPlaceholderSeeder extends Seeder
{
    public function run(): void
    {
        $adminId = User::where('role', Role::Admin)->value('id');
        if ($adminId === null) {
            $this->command?->warn('أنشئ حساب مسؤول أولاً؛ لم تتم إضافة أي محتويات.');

            return;
        }

        foreach ([ContentType::Article, ContentType::Law, ContentType::Ruling, ContentType::Guide, ContentType::Article, ContentType::Guide] as $index => $type) {
            Content::firstOrCreate(['slug' => 'placeholder-content-'.($index + 1)], [
                'type' => $type, 'title' => 'نص تجريبي — '.$type->label().' '.($index + 1),
                'category' => 'نص تجريبي',
                'summary' => 'نص تجريبي لا يمثل مرجعاً قانونياً.',
                'body' => '<p>نص تجريبي لعرض مكتبة المحتوى فقط. هذا ليس نصاً قانونياً ولا إرشاداً قانونياً.</p>',
                'is_published' => false, 'created_by' => $adminId,
            ]);
        }
    }
}
