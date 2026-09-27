// lib/features/ai/presentation/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/app_colors.dart';
import 'ai_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final String courseContext;
  final String courseTitle;

  const AiAssistantScreen({
    super.key,
    required this.courseContext,
    required this.courseTitle,
  });

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    ref.read(doubtProvider(widget.courseContext).notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doubtProvider(widget.courseContext));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              backgroundColor: AppColors.bgPrimary,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Doubt Assistant',
                      style: TextStyle(fontSize: 16)),
                  Text(
                    widget.courseTitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => ref
                      .read(doubtProvider(widget.courseContext).notifier)
                      .clear(),
                  tooltip: 'Clear chat',
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyChat(
                    courseTitle: widget.courseTitle,
                    onSuggestion: (q) {
                      _msgCtrl.text = q;
                      _send();
                    })
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: state.messages.length,
                    itemBuilder: (ctx, i) => _MessageBubble(
                      message: state.messages[i],
                      index: i,
                    ),
                  ),
          ),

          // Error
          if (state.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to get response. Please try again.',
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              border:
                  Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about ${widget.courseTitle}…',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accentPurple,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _send,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.index});
  final ChatMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  gradient: AppColors.brandGradient, shape: BoxShape.circle),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accentPurple : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 0.5),
              ),
              child: message.isLoading
                  ? _TypingIndicator()
                  : isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, height: 1.5),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.6),
                            code: const TextStyle(
                              color: AppColors.accentCyan,
                              backgroundColor: AppColors.bgElevated,
                              fontSize: 13,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            h1: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            h2: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            listBullet:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
            )
                .animate(delay: Duration(milliseconds: index * 50))
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final val = ((_ctrl.value - i * 0.2) % 1.0).clamp(0.0, 1.0);
            final opacity = val < 0.5 ? val * 2 : (1.0 - val) * 2;
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.3 + opacity * 0.7),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.courseTitle, required this.onSuggestion});
  final String courseTitle;
  final void Function(String) onSuggestion;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Summarize the key concepts from this course',
      'What are the most important things to remember?',
      'Can you explain this topic in simpler terms?',
      'Give me a quick quiz on this material',
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                gradient: AppColors.brandGradient, shape: BoxShape.circle),
            child:
                const Center(child: Text('✨', style: TextStyle(fontSize: 40))),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          const Text(
            'Ask me anything!',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'I\'m your AI tutor for $courseTitle',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...suggestions.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => onSuggestion(entry.value),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                    ),
                  )
                      .animate(
                          delay: Duration(milliseconds: 100 + entry.key * 80))
                      .fadeIn()
                      .slideX(begin: -0.05),
                ),
              )),
        ],
      ),
    );
  }
}
