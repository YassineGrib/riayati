<?php

namespace App\Filament\Resources\Contents\Schemas;

use App\Enums\ContentType;
use Filament\Forms\Components\RichEditor;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Validation\Rule;

class ContentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make('تفاصيل المحتوى')->columns(2)->columnSpanFull()->schema([
                TextInput::make('title')->label('العنوان')->required()->maxLength(255)->columnSpanFull(),
                Select::make('type')->label('النوع')->options(ContentType::options())
                    ->required()->rules([Rule::enum(ContentType::class)]),
                TextInput::make('slug')->label('المعرّف الفريد')->required()->maxLength(255)
                    ->unique(ignoreRecord: true)->extraInputAttributes(['dir' => 'ltr'])
                    ->helperText('معرّف فريد للمحتوى، مثل article-1.'),
                TextInput::make('category')->label('التصنيف')->maxLength(255),
                TextInput::make('reference')->label('المرجع')->maxLength(255),
                Textarea::make('summary')->label('الملخص')->rows(3)->columnSpanFull(),
                RichEditor::make('body')->label('النص')->required()->columnSpanFull()
                    ->toolbarButtons([
                        ['bold', 'italic', 'underline', 'link'],
                        ['h2', 'h3', 'bulletList', 'orderedList', 'blockquote'],
                        ['undo', 'redo'],
                    ]),
                Toggle::make('use_in_assistant')->label('يستعمله المساعد القانوني')->default(false)
                    ->helperText('النص المنشور والمفعّل يصير مصدرًا لإجابات المساعد؛ التعديل يعيد الفهرسة تلقائيًا'),
                Toggle::make('is_published')->label('منشور')->default(false)
                    ->helperText('يُسجّل تاريخ النشر عند التفعيل.'),
            ]),
        ]);
    }
}
