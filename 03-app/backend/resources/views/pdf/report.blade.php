@php
    use App\Support\ArabicDate;
    $roleLabel = ['father' => 'أب', 'mother' => 'أم', 'admin' => 'مسؤول'][$report->user->role->value] ?? '';
    $sizeLabel = fn ($bytes) => $bytes >= 1048576 ? number_format($bytes / 1048576, 1).' ميغابايت' : max(1, (int) round($bytes / 1024)).' كيلوبايت';
    $kindLabel = ['image' => 'صورة', 'video' => 'فيديو', 'file' => 'ملف'];
@endphp
<style>
  body { font-family: plexar; font-size: 11pt; color: #2f332d; line-height: 1.7; }
  h1 { font-size: 20pt; margin: 0 0 2mm 0; color: #2f332d; }
  h2 { font-size: 13pt; margin: 7mm 0 2mm 0; color: #406a05; border-bottom: 0.4mm solid #406a05; padding-bottom: 1mm; }
  .bar { background: #406a05; color: #ffffff; padding: 4mm 5mm; margin-bottom: 6mm; }
  .bar b { font-size: 15pt; }
  table.kv { width: 100%; border-collapse: collapse; }
  table.kv td { padding: 2mm 0; border-bottom: 0.2mm solid #d9ded6; }
  table.kv td.k { width: 32%; color: #5a5e57; }
  table.files { width: 100%; border-collapse: collapse; font-size: 9.5pt; }
  table.files th { background: #eef2ea; text-align: right; padding: 2mm; }
  table.files td { padding: 2mm; border-bottom: 0.2mm solid #d9ded6; vertical-align: top; }
  .hash { font-size: 7.5pt; color: #5a5e57; direction: ltr; text-align: left; }
  .desc { padding: 4mm; background: #f4f9f0; border: 0.2mm solid #d9ded6; }
  .note { margin-top: 8mm; font-size: 9pt; color: #5a5e57; }
</style>

<div class="bar"><b>رعايتي</b> · تقرير بلاغ</div>

<h1>تقرير البلاغ</h1>
<table class="kv">
  <tr><td class="k">رقم البلاغ</td><td><span dir="ltr">{{ $report->reference }}</span></td></tr>
  <tr><td class="k">الحالة</td><td>{{ $report->status->label() }}</td></tr>
  <tr><td class="k">تاريخ الحادثة</td><td>{{ ArabicDate::format($report->incident_at) }}</td></tr>
  <tr><td class="k">أُرسل في</td><td>{{ ArabicDate::format($report->created_at) }}</td></tr>
  <tr><td class="k">مقدّم البلاغ</td><td>{{ $report->user->name }} ({{ $roleLabel }})</td></tr>
</table>

<h2>الوصف</h2>
<div class="desc">{!! nl2br(e($report->description)) !!}</div>

<h2>المرفقات ({{ $report->attachments->count() }})</h2>
@if ($report->attachments->isEmpty())
  <p>لا توجد مرفقات.</p>
@else
  <table class="files">
    <tr><th>النوع</th><th>الاسم</th><th>الحجم</th><th>بصمة الملف (SHA-256)</th></tr>
    @foreach ($report->attachments as $a)
      <tr>
        <td>{{ $kindLabel[$a->kind] ?? 'ملف' }}</td>
        <td dir="ltr" style="text-align:right">{{ $a->original_name }}</td>
        <td>{{ $sizeLabel($a->size) }}</td>
        <td class="hash">{{ $a->sha256 }}</td>
      </tr>
    @endforeach
  </table>

  @foreach ($report->attachments->where('kind', 'image') as $a)
    @if (isset($images[$a->id]))
      <div style="page-break-inside:avoid;margin-top:5mm">
        <p dir="ltr" style="text-align:right;margin:0 0 1mm 0;font-size:9pt;color:#5a5e57">{{ $a->original_name }}</p>
        <img src="{{ $images[$a->id] }}" style="max-width:100%;max-height:120mm">
      </div>
    @endif
  @endforeach
@endif

<p class="note">وُلّد هذا التقرير من تطبيق رعايتي بتاريخ {{ ArabicDate::format(now()) }}. يعرض المعلومات كما أدخلها مقدّم البلاغ وقت الإرسال، ولا يُغني عن الاستشارة القانونية. بصمة الملف تتيح التحقق من أن المرفق لم يتغيّر بعد رفعه.</p>
