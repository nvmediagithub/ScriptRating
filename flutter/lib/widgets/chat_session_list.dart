import 'package:flutter/material.dart';
import '../models/chat_session.dart';
import '../models/llm_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatSessionList extends StatelessWidget {
  final List<ChatSession> sessions;
  final ChatSession? selectedSession;
  final ValueChanged<ChatSession>? onSessionSelected;
  final VoidCallback? onNewSession;
  final ValueChanged<ChatSession>? onDeleteSession;
  final bool isLoading;

  const ChatSessionList({
    super.key,
    required this.sessions,
    this.selectedSession,
    this.onSessionSelected,
    this.onNewSession,
    this.onDeleteSession,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionItem(context, session, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Chat Sessions', style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(),
          if (onNewSession != null)
            FloatingActionButton.small(onPressed: onNewSession, child: const Icon(Icons.add)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No chat sessions yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation to begin chatting with the LLM',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onNewSession != null)
            ElevatedButton.icon(
              onPressed: onNewSession,
              icon: const Icon(Icons.add),
              label: const Text('Start New Chat'),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, ChatSession session, int index) {
    final isSelected = selectedSession?.id == session.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onSessionSelected?.call(session),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _buildProviderIcon(context, session.llmProvider),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${session.llmProvider.value} • ${session.llmModel}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(session.updatedAt),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.message, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${session.messageCount} messages',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDeleteSession != null) ...[
                  const SizedBox(width: 8),
                  _buildDeleteButton(context, session),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderIcon(BuildContext context, LLMProvider provider) {
    IconData iconData;
    Color color;

    switch (provider) {
      case LLMProvider.local:
        iconData = Icons.computer;
        color = Colors.blue;
        break;
      case LLMProvider.openrouter:
        iconData = Icons.cloud;
        color = Colors.orange;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Widget _buildDeleteButton(BuildContext context, ChatSession session) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          onDeleteSession?.call(session);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
    );
  }
}
