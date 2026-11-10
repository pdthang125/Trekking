import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../bloc/ai_assistant_bloc_handler.dart';

class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AiAssistantBlocHandler>(),
      child: const _AiAssistantView(),
    );
  }
}

class _AiAssistantView extends StatefulWidget {
  const _AiAssistantView();

  @override
  State<_AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<_AiAssistantView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    'Bị rắn cắn ở bắp chân',
    'Chóng mặt, buồn nôn do nắng',
    'Người lạnh run rẩy, môi tím',
    'Trẹo mắt cá chân không đi được',
    'Bị ong rừng đốt nhiều nốt',
  ];

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (quickText == null) {
      _controller.clear();
    }

    context.read<AiAssistantBlocHandler>().add(SendMessageEvent(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 TrekGuard AI Chat'),
        actions: [
          BlocBuilder<AiAssistantBlocHandler, AiAssistantState>(
            builder: (context, state) {
              final isOnline = state.isOnline;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.safeColor.withAlpha(30)
                      : AppTheme.warningColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? AppTheme.safeColor.withAlpha(120)
                        : AppTheme.warningColor.withAlpha(120),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                      size: 14,
                      color: isOnline ? AppTheme.safeColor : AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online (Gemini)' : 'Offline (Local Model)',
                      style: TextStyle(
                        color: isOnline ? AppTheme.safeColor : AppTheme.warningColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Xoá lịch sử',
            onPressed: () {
              context.read<AiAssistantBlocHandler>().add(const ClearHistoryEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<AiAssistantBlocHandler, AiAssistantState>(
        listener: (context, state) {
          _scrollToBottom();
        },
        builder: (context, state) {
          final messages = state.messages;
          final isLoading = state is AiAssistantLoading;

          return Column(
            children: [
              // ── Gợi ý câu hỏi nhanh ──────────────────────────
              if (messages.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Tình huống khẩn cấp thường gặp:',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickPrompts.map((prompt) {
                          return ActionChip(
                            label: Text(prompt, style: const TextStyle(fontSize: 12)),
                            avatar: const Icon(Icons.medical_services_outlined, size: 14),
                            onPressed: () => _sendMessage(prompt),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Danh sách tin nhắn ──────────────────────────
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.support_agent_rounded, size: 64, color: theme.colorScheme.primary.withAlpha(120)),
                            const SizedBox(height: 12),
                            Text(
                              'Nhập triệu chứng hoặc thắc mắc dã ngoại',
                              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hệ thống tự động chuyển giữa Cloud Gemini và Local Model',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length + (isLoading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == messages.length) return const _TypingIndicator();
                          return _ChatBubble(message: messages[i]);
                        },
                      ),
              ),

              // ── Thanh nhập tin nhắn ──────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outline.withAlpha(50)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: state.isOnline
                                ? 'Hỏi sơ cứu, thời tiết (Cloud Gemini)...'
                                : 'Tra cứu sơ cứu ngoại tuyến (Local Model)...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: isLoading ? null : () => _sendMessage(),
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageEntity message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: !isUser && message.source == MessageSource.localModel
              ? Border.all(color: AppTheme.warningColor.withAlpha(120))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Huy hiệu hiển thị nguồn phản hồi
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    message.source == MessageSource.geminiCloud
                        ? Icons.cloud_rounded
                        : Icons.memory_rounded,
                    size: 13,
                    color: message.source == MessageSource.geminiCloud
                        ? theme.colorScheme.primary
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.source == MessageSource.geminiCloud
                        ? 'Gemini Cloud'
                        : 'Local Model (On-Device)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: message.source == MessageSource.geminiCloud
                          ? theme.colorScheme.primary
                          : AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('Đang phân tích triệu chứng...', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
