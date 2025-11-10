// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => ChatSession(
  id: json['id'] as String,
  title: json['title'] as String,
  userId: json['userId'] as String,
  llmProvider: $enumDecode(_$LLMProviderEnumMap, json['llmProvider']),
  llmModel: json['llmModel'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
  settings: json['settings'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatSessionToJson(ChatSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'userId': instance.userId,
      'llmProvider': _$LLMProviderEnumMap[instance.llmProvider]!,
      'llmModel': instance.llmModel,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
      'messageCount': instance.messageCount,
      'settings': instance.settings,
    };

const _$LLMProviderEnumMap = {
  LLMProvider.local: 'local',
  LLMProvider.openrouter: 'openrouter',
};
