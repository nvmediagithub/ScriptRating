import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage extends Equatable {
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isStreaming;
  final String? llmProvider;
  final String? llmModel;
  final int? responseTimeMs;
  final int? tokensUsed;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isStreaming = false,
    this.llmProvider,
    this.llmModel,
    this.responseTimeMs,
    this.tokensUsed,
    this.errorMessage,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStreaming,
    String? llmProvider,
    String? llmModel,
    int? responseTimeMs,
    int? tokensUsed,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStreaming: isStreaming ?? this.isStreaming,
      llmProvider: llmProvider ?? this.llmProvider,
      llmModel: llmModel ?? this.llmModel,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, sessionId, role, content, createdAt, isStreaming, errorMessage];
}

enum MessageRole { user, assistant, system }
