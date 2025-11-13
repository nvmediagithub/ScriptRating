import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/llm_service.dart';
import '../../models/chat_message.dart';

/// Simple test chat message model for LLM dashboard testing
class TestChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? error;
  final double? responseTimeMs;

  TestChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.error,
    this.responseTimeMs,
  });

  factory TestChatMessage.user(String content) {
    return TestChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory TestChatMessage.assistant(String content, {double? responseTimeMs}) {
    return TestChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      responseTimeMs: responseTimeMs,
    );
  }

  factory TestChatMessage.error(String error) {
    return TestChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      error: error,
    );
  }
}

class TestChatWidget extends StatefulWidget {
  final LlmService llmService;
  final String currentProvider;
  final String currentModel;

  const TestChatWidget({
    super.key,
    required this.llmService,
    required this.currentProvider,
    required this.currentModel,
  });

  @override
  State<TestChatWidget> createState() => _TestChatWidgetState();
}

class _TestChatWidgetState extends State<TestChatWidget> {
  final List<TestChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = TestChatMessage.assistant(
      'Hello! I\'m your LLM test assistant. Current provider: ${widget.currentProvider.toUpperCase()}, Model: ${widget.currentModel}. Type a message to test the ${widget.currentProvider} provider.',
    );
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty || _isProcessing) return;

    // Add user message
    final userMessage = TestChatMessage.user(content.trim());
    setState(() {
      _messages.add(userMessage);
      _isProcessing = true;
    });

    _scrollToBottom();

    try {
      // Use the real chat API with direct LLM processing endpoint
      final chatSessionId = await _ensureTestChatSession();

      // Send message to backend - this will trigger async LLM processing
      final response = await widget.llmService.sendChatMessage(chatSessionId, content.trim());

      // For now, add a placeholder for the LLM response while it processes
      final placeholderMessage = TestChatMessage.assistant(
        'Processing with ${widget.currentProvider.toUpperCase()}...',
        responseTimeMs: 0,
      );

      setState(() {
        _messages.add(placeholderMessage);
      });

      // Start polling for the actual LLM response
      _pollForLLMResponse(chatSessionId, _messages.length - 1);
    } catch (e) {
      final errorMessage = TestChatMessage.error('Error: $e');
      setState(() {
        _messages.add(errorMessage);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Test failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _ensureTestChatSession() async {
    // Try to get existing test chat session
    final sessions = await widget.llmService.getChatSessions();

    // Look for a test session or create one
    String? testSessionId;
    for (final session in sessions) {
      if (session.title.contains('LLM Test') || session.title.contains('Test Chat')) {
        testSessionId = session.id;
        break;
      }
    }

    if (testSessionId != null) {
      return testSessionId;
    }

    // Create a new test chat session
    final newSession = await widget.llmService.createChatSession(
      title: 'LLM Test Chat - ${widget.currentProvider.toUpperCase()}',
      provider: widget.currentProvider,
      model: widget.currentModel,
      settings: {'is_test': true},
    );

    return newSession.id;
  }

  void _pollForLLMResponse(String sessionId, int messageIndex) async {
    const maxAttempts = 60; // Poll for up to 60 seconds
    const delayDuration = Duration(milliseconds: 2000); // Poll every 2 seconds

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(delayDuration);

      try {
        final messages = await widget.llmService.getChatMessages(sessionId, page: 1, pageSize: 10);

        // Find the latest assistant message
        for (final message in messages.reversed) {
          // Ensure we're working with ChatMessage objects, not raw data
          if (message.role == MessageRole.assistant &&
              message.content.isNotEmpty &&
              !message.content.contains('Processing')) {
            // Update the placeholder with the actual response
            final assistantMessage = TestChatMessage.assistant(
              message.content,
              responseTimeMs: message.responseTimeMs?.toDouble(),
            );

            setState(() {
              if (messageIndex < _messages.length) {
                _messages[messageIndex] = assistantMessage;
              }
            });

            _scrollToBottom();
            return; // Success
          }
        }
      } catch (e) {
        // Continue polling if there's an error
        debugPrint('Error polling for LLM response: $e');
        continue;
      }
    }

    // Timeout - update the message to show timeout
    final timeoutMessage = TestChatMessage.error(
      'Response timeout - the LLM may still be processing',
    );
    setState(() {
      if (messageIndex < _messages.length) {
        _messages[messageIndex] = timeoutMessage;
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _handleSubmitted(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      _sendMessage(value.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(fit: FlexFit.loose, child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LLM Test Chat',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Provider: ${widget.currentProvider.toUpperCase()} • Model: ${widget.currentModel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(onPressed: _clearChat, icon: const Icon(Icons.refresh), tooltip: 'Clear Chat'),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      height: 400, // Fixed height to prevent unbounded constraints
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message, index);
        },
      ),
    );
  }

  Widget _buildMessageBubble(TestChatMessage message, int index) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(isUser), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBubbleColor(isUser, message),
                borderRadius: _getBorderRadius(isUser),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.error != null)
                    _buildErrorDisplay(message.error!)
                  else if (_isProcessing && index == _messages.length - 1 && !isUser)
                    _buildTypingIndicator()
                  else if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14),
                    ),
                  if (message.responseTimeMs != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Response time: ${message.responseTimeMs}ms',
                      style: TextStyle(
                        color: isUser ? Colors.white70 : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _buildAvatar(isUser)],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Theme.of(context).primaryColor : Colors.grey[400],
      child: Icon(isUser ? Icons.person : Icons.smart_toy, color: Colors.white, size: 16),
    );
  }

  Color _getBubbleColor(bool isUser, TestChatMessage message) {
    if (message.error != null) {
      return Colors.red[50]!;
    }
    if (isUser) return Theme.of(context).primaryColor;
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

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
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

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedDot(delay: const Duration(milliseconds: 0)),
        const SizedBox(width: 2),
        _AnimatedDot(delay: const Duration(milliseconds: 200)),
        const SizedBox(width: 2),
        _AnimatedDot(delay: const Duration(milliseconds: 400)),
        const SizedBox(width: 8),
        Text(
          'Thinking...',
          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.send,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                hintText: _isProcessing ? 'Processing message...' : 'Type a test message...',
                hintStyle: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: _isProcessing ? Colors.grey[50] : Colors.transparent,
              ),
              style: const TextStyle(fontSize: 14),
              onSubmitted: _handleSubmitted,
              inputFormatters: [
                LengthLimitingTextInputFormatter(1000), // Max 1000 chars for testing
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    if (_isProcessing) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    final canSend = _controller.text.trim().isNotEmpty;

    return Material(
      color: canSend ? Theme.of(context).primaryColor : Colors.grey[300],
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: canSend ? () => _handleSubmitted(_controller.text) : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.send, color: canSend ? Colors.white : Colors.grey[500], size: 18),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final Duration delay;

  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        _animationController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Icon(Icons.circle, size: 6, color: Colors.grey[600]),
        );
      },
    );
  }
}
