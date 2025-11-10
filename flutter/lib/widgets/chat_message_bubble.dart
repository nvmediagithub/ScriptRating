import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_message.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const ChatMessageBubble({super.key, required this.message, this.isStreaming = false});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isAssistant = message.role == MessageRole.assistant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(context, isAssistant), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(isUser, isAssistant),
                    borderRadius: _getBorderRadius(isUser),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.content.isNotEmpty)
                        SelectableText(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      if (isStreaming) ...[const SizedBox(height: 4), _buildTypingIndicator()],
                      if (message.errorMessage != null) ...[
                        const SizedBox(height: 4),
                        _buildErrorDisplay(message.errorMessage!),
                      ],
                      if (_showMetadata()) ...[const SizedBox(height: 8), _buildMetadata()],
                    ],
                  ),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 4),
                _buildTimestamp(),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _buildAvatar(context, true)],
        ],
      ),
    );
  }

  Color _getBubbleColor(bool isUser, bool isAssistant) {
    if (isUser) return Colors.blue[500]!;
    if (isAssistant) return Colors.grey[200]!;
    return Colors.grey[100]!;
  }

  BorderRadius _getBorderRadius(bool isUser) {
    if (isUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(4),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(16),
      );
    }
  }

  Widget _buildAvatar(BuildContext context, bool isCurrentUser) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: isCurrentUser ? Theme.of(context).primaryColor : Colors.grey[400],
      child: Icon(isCurrentUser ? Icons.person : Icons.smart_toy, color: Colors.white, size: 20),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedDot(delay: 0.ms),
        const SizedBox(width: 2),
        _AnimatedDot(delay: 200.ms),
        const SizedBox(width: 2),
        _AnimatedDot(delay: 400.ms),
        const SizedBox(width: 8),
        Text(
          'Thinking...',
          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: TextStyle(color: Colors.red[700], fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.llmProvider != null)
            Text(
              'Provider: ${message.llmProvider}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          if (message.llmModel != null)
            Text(
              'Model: ${message.llmModel}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          if (message.responseTimeMs != null)
            Text(
              'Response time: ${message.responseTimeMs}ms',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      timeago.format(message.createdAt),
      style: TextStyle(color: Colors.grey[500], fontSize: 10),
    );
  }

  bool _showMetadata() {
    return message.llmProvider != null ||
        message.llmModel != null ||
        message.responseTimeMs != null;
  }
}

class _AnimatedDot extends StatefulWidget {
  final Duration delay;

  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> {
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.circle, size: 8, color: Colors.grey)
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 300.ms, delay: widget.delay)
        .then()
        .fadeOut(duration: 600.ms);
  }
}
