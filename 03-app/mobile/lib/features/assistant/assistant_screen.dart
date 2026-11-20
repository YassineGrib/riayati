import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import 'assistant_repository.dart';

const assistantNotice =
    'مساعد آلي يجيب من النصوص المدخلة فقط. لا تكتب أسماء أو تفاصيل قضية أو معلومات شخصية. لا يغني عن استشارة مختص.';

const _examples = [
  'ما الذي تتضمنه المكتبة التعريفية؟',
  'كيف أستعمل التقويم المشترك للزيارات؟',
  'أين أجد الجهات المختصة في ولايتي؟',
];

class _Message {
  _Message.user(this.text) : user = true, reply = null, failed = false;
  _Message.bot(this.reply) : user = false, text = reply!.answer, failed = false;
  _Message.error(this.text) : user = false, reply = null, failed = true;

  final bool user;
  final String text;
  final AssistantReply? reply;
  final bool failed;
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  static const _limit = 500;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[];
  bool _loading = false;
  String? _lastQuestion;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? text]) async {
    final question = (text ?? _input.text).trim();
    if (question.isEmpty || _loading) return;
    setState(() {
      _messages.add(_Message.user(question));
      _loading = true;
      _lastQuestion = question;
      _input.clear();
    });
    _toEnd();
    try {
      final reply = await ref.read(assistantRepositoryProvider).ask(question);
      if (!mounted) return;
      setState(() => _messages.add(_Message.bot(reply)));
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiError
          ? (error.fields['question']?.first ?? error.message)
          : ApiError.offlineMessage;
      setState(() => _messages.add(_Message.error(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
      _toEnd();
    }
  }

  void _retry() {
    final q = _lastQuestion;
    if (q == null || _loading) return;
    setState(() => _messages.removeLast());
    // The failed attempt's user bubble stays; ask again without duplicating it.
    setState(() => _messages.removeWhere((m) => m.user && m.text == q));
    _send(q);
  }

  void _reset() => setState(() {
    _messages.clear();
    _lastQuestion = null;
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppScaffold(
      title: 'المساعد القانوني',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_messages.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const ValueKey('assistant-new'),
                onPressed: _loading ? null : _reset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('محادثة جديدة'),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? _Empty(onPick: _send)
                : ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s3,
                    ),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: RSpace.s3),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) return const _Typing();
                      final m = _messages[i];
                      return _Bubble(
                        message: m,
                        onRetry: m.failed && i == _messages.length - 1
                            ? _retry
                            : null,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: RSpace.s2),
            child: Text(
              assistantNotice,
              style: RType.caption.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: RSpace.s2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('assistant-input'),
                  controller: _input,
                  enabled: !_loading,
                  maxLength: _limit,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك هنا…',
                    counterText: '',
                    filled: true,
                    fillColor: c.surface,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: RSpace.s4,
                      vertical: RSpace.s3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RRadius.xl),
                      borderSide: BorderSide(color: c.borderStrong),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: RSpace.s2),
              IconButton.filled(
                key: const ValueKey('assistant-send'),
                tooltip: 'إرسال',
                onPressed: _loading || _input.text.trim().isEmpty
                    ? null
                    : _send,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: RSpace.s2),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.symmetric(vertical: RSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(RSpace.s4),
            decoration: BoxDecoration(
              color: c.surfaceBrandSoft,
              border: Border.all(color: c.border, width: RBorderWidth.thin),
              borderRadius: BorderRadius.circular(RRadius.x2xl),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: c.primary),
                const SizedBox(width: RSpace.s3),
                Expanded(
                  child: Text(
                    'اسألني عن النصوص التي أدخلتها إدارة رعايتي، وأجيبك منها مع ذكر المصدر.',
                    style: RType.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RSpace.s4),
          Text(
            'أمثلة على الأسئلة',
            style: RType.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: RSpace.s2),
          for (final q in _examples) ...[
            InkWell(
              onTap: () => onPick(q),
              borderRadius: BorderRadius.circular(RRadius.xl),
              child: Container(
                padding: const EdgeInsetsDirectional.all(RSpace.s4),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border, width: RBorderWidth.thin),
                  borderRadius: BorderRadius.circular(RRadius.xl),
                ),
                child: Text(q, style: RType.body.copyWith(color: c.textPrimary)),
              ),
            ),
            const SizedBox(height: RSpace.s2),
          ],
        ],
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      key: const ValueKey('assistant-typing'),
      padding: const EdgeInsetsDirectional.all(RSpace.s3),
      decoration: BoxDecoration(
        color: context.c.surfaceSunken,
        borderRadius: BorderRadius.circular(RRadius.xl),
      ),
      child: const SizedBox(
        width: RSpace.s5,
        height: RSpace.s5,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry});
  final _Message message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final m = message;
    final reply = m.reply;
    final bg = m.user
        ? c.primary
        : m.failed
        ? c.feedbackErrorBg
        : c.surface;
    final fg = m.user
        ? c.textOnAction
        : m.failed
        ? c.feedbackErrorText
        : c.textPrimary;
    return Align(
      alignment: m.user
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Container(
          padding: const EdgeInsetsDirectional.all(RSpace.s4),
          decoration: BoxDecoration(
            color: bg,
            border: m.user
                ? null
                : Border.all(color: c.border, width: RBorderWidth.thin),
            borderRadius: BorderRadius.circular(RRadius.x2xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.text,
                style: RType.body.copyWith(color: fg, height: 1.6),
              ),
              if (reply != null && reply.sources.isNotEmpty) ...[
                const SizedBox(height: RSpace.s3),
                Text(
                  'المصادر',
                  style: RType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: RSpace.s1_5),
                Wrap(
                  spacing: RSpace.s2,
                  runSpacing: RSpace.s2,
                  children: [
                    for (final s in reply.sources)
                      ActionChip(
                        key: ValueKey('assistant-source-${s.id}'),
                        label: Text(
                          s.reference == null || s.reference!.isEmpty
                              ? s.title
                              : '${s.title} · ${s.reference}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: s.slug == null
                            ? null
                            : () => context.push('/library/${s.slug}'),
                      ),
                  ],
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: RSpace.s2),
                TextButton(
                  key: const ValueKey('assistant-retry'),
                  onPressed: onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
