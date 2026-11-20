import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/r_button.dart';
import 'calendar_widgets.dart';
import 'visit.dart';
import 'visit_repository.dart';

/// Keeps only digits and puts [separator] between the groups, so typing
/// `1000` gives `10:00` and `20261125` gives `2026-11-25`.
class _DigitsFormatter extends TextInputFormatter {
  const _DigitsFormatter(this.groups, this.separator);
  final List<int> groups;
  final String separator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final out = StringBuffer();
    var index = 0;
    for (final size in groups) {
      if (index >= digits.length) break;
      if (out.isNotEmpty) out.write(separator);
      final end = index + size > digits.length ? digits.length : index + size;
      out.write(digits.substring(index, end));
      index = end;
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

Future<Visit?> showProposeVisitSheet(
  BuildContext context, {
  DateTime? initialDate,
}) => showModalBottomSheet<Visit>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: context.c.bg,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(RRadius.x3xl)),
  ),
  builder: (_) => ProposeVisitSheet(initialDate: initialDate),
);

class ProposeVisitSheet extends ConsumerStatefulWidget {
  const ProposeVisitSheet({super.key, this.initialDate});
  final DateTime? initialDate;
  @override
  ConsumerState<ProposeVisitSheet> createState() => _ProposeVisitSheetState();
}

class _ProposeVisitSheetState extends ConsumerState<ProposeVisitSheet> {
  static const _noteLimit = 300;
  final _form = GlobalKey<FormState>();
  late final TextEditingController _date;
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _date = TextEditingController(
      text: widget.initialDate == null ? '' : visitDayKey(widget.initialDate!),
    );
  }

  @override
  void dispose() {
    for (final controller in [_date, _from, _to, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime? get _parsedDate {
    final value = _date.text.trim();
    final date = DateTime.tryParse(value);
    return date != null && visitDayKey(date) == value ? date : null;
  }

  int? _minutes(String value) {
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) return null;
    final parts = value.split(':').map(int.parse).toList();
    return parts.first * Duration.minutesPerHour + parts.last;
  }

  Future<void> _submit() async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final visit = await ref
          .read(visitRepositoryProvider)
          .propose(
            date: _date.text.trim(),
            from: _from.text.trim(),
            to: _to.text.trim(),
            note: _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(visit);
    } catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = error is ApiError
              ? {
                  error.message,
                  ...error.fields.values.expand((v) => v),
                }.join('\n')
              : ApiError.offlineMessage;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _parsedDate?.isBefore(now) == false ? _parsedDate : now,
      firstDate: now,
      lastDate: DateTime(now.year + 100, now.month, now.day),
    );
    if (picked != null && mounted) {
      setState(() => _date.text = visitDayKey(picked));
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final minutes = _minutes(controller.text.trim());
    final picked = await showTimePicker(
      context: context,
      initialTime: minutes == null
          ? TimeOfDay.now()
          : TimeOfDay(
              hour: minutes ~/ Duration.minutesPerHour,
              minute: minutes % Duration.minutesPerHour,
            ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _field({
    required String name,
    required String label,
    required TextEditingController controller,
    FormFieldValidator<String>? validator,
    Widget? suffix,
    bool note = false,
  }) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: RSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: RType.label),
        const SizedBox(height: RSpace.s1_5),
        TextFormField(
          key: ValueKey(name),
          controller: controller,
          validator: validator,
          enabled: !_sending,
          textDirection: note ? TextDirection.rtl : TextDirection.ltr,
          keyboardType: note ? TextInputType.multiline : TextInputType.datetime,
          inputFormatters: name == 'visit-date'
              ? [_DigitsFormatter(const [4, 2, 2], '-')]
              : note
              ? null
              : [_DigitsFormatter(const [2, 2], ':')],
          maxLength: note ? _noteLimit : null,
          minLines: note ? 3 : 1,
          maxLines: note ? null : 1,
          style: RType.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.c.surface,
            hintText: note
                ? 'مثال: مكان التسليم.'
                : name == 'visit-date'
                ? 'YYYY-MM-DD'
                : 'HH:mm',
            hintStyle: RType.body.copyWith(color: context.c.textTertiary),
            suffixIcon: suffix,
            errorMaxLines: null,
            contentPadding: const EdgeInsetsDirectional.all(RSpace.s4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RRadius.xl),
              borderSide: BorderSide(
                color: context.c.borderStrong,
                width: RBorderWidth.thin,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RRadius.xl),
              borderSide: BorderSide(
                color: context.c.borderStrong,
                width: RBorderWidth.thin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RRadius.xl),
              borderSide: BorderSide(
                color: context.c.borderFocus,
                width: RBorderWidth.medium,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          RSpace.s6,
          RSpace.s4,
          RSpace.s6,
          MediaQuery.viewInsetsOf(context).bottom + RSpace.s6,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'اقتراح زيارة',
                      style: RType.heading3.copyWith(
                        fontFamily: RType.display.fontFamily,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: _sending
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: RSpace.s4),
              _field(
                name: 'visit-date',
                label: 'التاريخ',
                controller: _date,
                suffix: IconButton(
                  tooltip: 'اختيار التاريخ',
                  onPressed: _sending ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
                validator: (_) {
                  final date = _parsedDate;
                  if (date == null) return 'أدخل التاريخ بصيغة YYYY-MM-DD.';
                  final minutes = _minutes(_from.text.trim()) ?? 0;
                  if (!date
                      .add(Duration(minutes: minutes))
                      .isAfter(DateTime.now())) {
                    return 'اختر موعدًا في المستقبل.';
                  }
                  return null;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      name: 'visit-from',
                      label: 'من',
                      controller: _from,
                      suffix: IconButton(
                        tooltip: 'وقت البداية',
                        onPressed: _sending ? null : () => _pickTime(_from),
                        icon: const Icon(Icons.schedule),
                      ),
                      validator: (v) => _minutes(v!.trim()) == null
                          ? 'أدخل وقتًا بصيغة HH:mm.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: RSpace.s3),
                  Expanded(
                    child: _field(
                      name: 'visit-to',
                      label: 'إلى',
                      controller: _to,
                      suffix: IconButton(
                        tooltip: 'وقت النهاية',
                        onPressed: _sending ? null : () => _pickTime(_to),
                        icon: const Icon(Icons.schedule),
                      ),
                      validator: (v) {
                        final end = _minutes(v!.trim());
                        if (end == null) return 'أدخل وقتًا بصيغة HH:mm.';
                        final start = _minutes(_from.text.trim());
                        return start != null && end <= start
                            ? 'يجب أن يكون وقت النهاية بعد البداية.'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              _field(
                name: 'visit-note',
                label: 'ملاحظة (اختياري)',
                controller: _note,
                note: true,
                validator: (v) => (v?.characters.length ?? 0) > _noteLimit
                    ? 'الملاحظة لا تتجاوز 300 حرف.'
                    : null,
              ),
              Container(
                padding: const EdgeInsetsDirectional.all(RSpace.s3),
                decoration: BoxDecoration(
                  color: context.c.feedbackInfoBg,
                  borderRadius: BorderRadius.circular(RRadius.xl),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: context.c.feedbackInfoIcon),
                    const SizedBox(width: RSpace.s2),
                    Expanded(
                      child: Text(
                        'سيصل الاقتراح إلى الطرف الآخر ليقبله أو يرفضه، وستصلك نتيجة ردّه.',
                        style: RType.caption.copyWith(
                          color: context.c.feedbackInfoText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: RSpace.s4),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      key: const ValueKey('proposal-error'),
                      style: RType.caption.copyWith(
                        color: context.c.feedbackErrorText,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: RSpace.s6),
              RButton(
                label: 'إرسال الاقتراح',
                loading: _sending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
