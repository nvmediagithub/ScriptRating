// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  content: json['content'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  isStreaming: json['isStreaming'] as bool? ?? false,
  llmProvider: json['llmProvider'] as String?,
  llmModel: json['llmModel'] as String?,
  responseTimeMs: (json['responseTimeMs'] as num?)?.toInt(),
  tokensUsed: (json['tokensUsed'] as num?)?.toInt(),
  errorMessage: json['errorMessage'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isStreaming': instance.isStreaming,
      'llmProvider': instance.llmProvider,
      'llmModel': instance.llmModel,
      'responseTimeMs': instance.responseTimeMs,
      'tokensUsed': instance.tokensUsed,
      'errorMessage': instance.errorMessage,
      'metadata': instance.metadata,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};
