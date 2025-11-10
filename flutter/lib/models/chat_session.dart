import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'llm_provider.dart';

part 'chat_session.g.dart';

@JsonSerializable()
class ChatSession extends Equatable {
  final String id;
  final String title;
  final String userId;
  final LLMProvider llmProvider;
  final String llmModel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int messageCount;
  final Map<String, dynamic>? settings;

  const ChatSession({
    required this.id,
    required this.title,
    required this.userId,
    required this.llmProvider,
    required this.llmModel,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.messageCount = 0,
    this.settings,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => _$ChatSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);

  ChatSession copyWith({
    String? id,
    String? title,
    String? userId,
    LLMProvider? llmProvider,
    String? llmModel,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? messageCount,
    Map<String, dynamic>? settings,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
      llmProvider: llmProvider ?? this.llmProvider,
      llmModel: llmModel ?? this.llmModel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [id, title, userId, llmProvider, llmModel, isActive, messageCount];
}
