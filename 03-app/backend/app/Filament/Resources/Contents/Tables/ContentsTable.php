<?php

namespace App\Filament\Resources\Contents\Tables;

use App\Enums\ContentType;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class ContentsTable
{
    public static function configure(Table $table): Table
    {
        return $table->defaultSort('created_at', 'desc')->columns([
            TextColumn::make('title')->label('العنوان')->searchable()->wrap()->limit(100),
            TextColumn::make('type')->label('النوع')->badge()
                ->formatStateUsing(fn (ContentType $state): string => $state->label())
                ->color(fn (ContentType $state): string => $state->color()),
            TextColumn::make('category')->label('التصنيف')->searchable()->placeholder('—'),
            TextColumn::make('reference')->label('المرجع')->searchable()->placeholder('—'),
            TextColumn::make('chunks_count')->counts('chunks')->label('فهرسة المساعد')->badge()
                ->formatStateUsing(fn ($state): string => $state > 0 ? 'مفهرس' : 'غير مفهرس')
                ->color(fn ($state): string => $state > 0 ? 'success' : 'gray'),
            IconColumn::make('is_published')->label('منشور')->boolean(),
            TextColumn::make('published_at')->label('تاريخ النشر')->dateTime('Y-m-d H:i')->sortable()->placeholder('—'),
        ])->filters([
            TernaryFilter::make('is_published')->label('حالة النشر')->placeholder('الكل')
                ->trueLabel('منشور')->falseLabel('غير منشور'),
        ])->recordActions([
            ViewAction::make()->label('عرض'),
            EditAction::make()->label('تعديل'),
            DeleteAction::make()->label('حذف')->requiresConfirmation()
                ->modalHeading('حذف المحتوى؟')->modalDescription('سيتم حذف هذا المحتوى فقط ولا يمكن التراجع عن الحذف.')
                ->modalSubmitActionLabel('تأكيد الحذف'),
        ]);
    }
}
