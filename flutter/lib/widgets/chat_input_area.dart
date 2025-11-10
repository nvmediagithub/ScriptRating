import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInputArea extends StatefulWidget {
  final ValueChanged<String> onSendMessage;
  final bool isEnabled;
  final bool isProcessing;
  final String? hintText;

  const ChatInputArea({
    super.key,
    required this.onSendMessage,
    this.isEnabled = true,
    this.isProcessing = false,
    this.hintText,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newCanSend =
        _controller.text.trim().isNotEmpty && widget.isEnabled && !widget.isProcessing;

    if (_canSend != newCanSend) {
      setState(() {
        _canSend = newCanSend;
      });
    }
  }

  void _handleSendMessage() {
    if (!_canSend) return;

    final message = _controller.text.trim();
    if (message.isEmpty) return;

    widget.onSendMessage(message);
    _controller.clear();

    // Request focus back to maintain input flow
    _focusNode.requestFocus();
  }

  void _handleSubmitted(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      _handleSendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildTextField()),
            const SizedBox(width: 12),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    String displayHint;
    if (!widget.isEnabled) {
      displayHint = 'Connecting...';
    } else if (widget.isProcessing) {
      displayHint = 'Processing message...';
    } else {
      displayHint = widget.hintText ?? 'Type your message...';
    }

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      minLines: 1,
      textInputAction: TextInputAction.send,
      enabled: widget.isEnabled && !widget.isProcessing,
      decoration: InputDecoration(
        hintText: displayHint,
        hintStyle: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: widget.isEnabled ? Colors.transparent : Colors.grey[50],
      ),
      style: const TextStyle(fontSize: 16),
      onSubmitted: _handleSubmitted,
      inputFormatters: [
        LengthLimitingTextInputFormatter(4000), // Max 4000 characters
      ],
    );
  }

  Widget _buildSendButton() {
    if (widget.isProcessing) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    return Material(
      color: widget.isEnabled ? Theme.of(context).primaryColor : Colors.grey[300],
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _canSend ? _handleSendMessage : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.send,
            color: widget.isEnabled ? Colors.white : Colors.grey[500],
            size: 20,
          ),
        ),
      ),
    );
  }
}
