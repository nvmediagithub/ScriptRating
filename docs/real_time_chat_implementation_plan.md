# Real-Time Chat Interface Implementation Plan
## Replacing the LLM Testing Block with Modern Real-Time Chat

### Document Information
- **Document Version**: 1.0
- **Created**: 2025-11-10
- **Author**: System Architect
- **Review Status**: Draft
- **Target Implementation**: Q1 2025

---

## Executive Summary

This document provides a comprehensive plan for implementing a modern real-time chat interface to replace the outdated LLM testing block in the LLM Dashboard. The implementation leverages the existing robust LLM infrastructure while introducing WebSocket-based real-time communication, enhanced message management, and a superior user experience.

### Key Objectives
- Replace static LLM testing interface with dynamic real-time chat
- Implement WebSocket-based real-time messaging
- Maintain compatibility with existing LLM providers (Local, OpenRouter)
- Provide message history and conversation management
- Ensure seamless integration with current LLM service architecture

### Expected Benefits
- **Real-time User Experience**: Instant message delivery and typing indicators
- **Better LLM Interaction**: Conversational interface for testing and interaction
- **Message Persistence**: Chat history and conversation management
- **Enhanced Usability**: Modern chat UI with proper message threading
- **Scalable Architecture**: WebSocket-based system supporting multiple concurrent users

---

## Current State Analysis

### Existing LLM Infrastructure ✅

The Script Rating system already possesses a sophisticated LLM infrastructure:

#### Backend Implementation (FastAPI)
- **Comprehensive OpenRouter Client**: Production-ready with proper error handling
- **Extensive API Endpoints**: 15+ endpoints for LLM management
- **Provider Management**: Support for Local and OpenRouter providers
- **Performance Monitoring**: Built-in metrics and health checks
- **Configuration Management**: Runtime configuration updates

#### Flutter Frontend Structure
- **Model Architecture**: Complete LLM model definitions
- **Service Layer**: Well-structured LlmService (needs implementation)
- **State Management**: Riverpod-based provider architecture
- **UI Components**: Comprehensive test infrastructure
- **Navigation**: Integrated LLM dashboard screen

#### Key Findings
1. **Strong Foundation**: The existing infrastructure provides 80% of what's needed
2. **Test Coverage**: Extensive test suite indicates good planning
3. **Model Consistency**: Backend and frontend models are well-aligned
4. **API Design**: RESTful endpoints are comprehensive and well-designed

### Gap Analysis

#### What's Missing
1. **Real-time Communication**: No WebSocket implementation
2. **Chat-Specific Models**: Message, conversation, and chat state models
3. **Chat UI Components**: Message bubbles, input fields, chat history
4. **WebSocket Backend**: Real-time message handling infrastructure
5. **Message Persistence**: Chat history storage and retrieval

#### Current Limitations
- Static testing interface with no conversation flow
- No real-time updates or typing indicators
- Limited message interaction capabilities
- No chat history or conversation management

---

## Technical Architecture

### System Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│   FastAPI Server │◄──►│  LLM Providers  │
│                 │    │                  │    │                 │
│ • Chat UI       │    │ • WebSocket      │    │ • Local         │
│ • Message Mgmt  │    │ • Chat API       │    │ • OpenRouter    │
│ • State Mgmt    │    │ • LLM Service    │    │                 │
│ • WebSocket     │    │ • Message Queue  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         ▲                       ▲
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│   Local Storage │    │  Message Store   │
│                 │    │                  │
│ • Chat History  │    │ • PostgreSQL     │
│ • Preferences   │    │ • Redis Cache    │
└─────────────────┘    └──────────────────┘
```

### Technology Stack

#### Backend Technologies
- **FastAPI**: Enhanced with WebSocket support
- **WebSocket**: Real-time bidirectional communication
- **SQLAlchemy**: Database models for chat persistence
- **Redis**: Message queue and real-time caching
- **Pydantic**: Enhanced models for chat functionality

#### Frontend Technologies
- **Flutter**: Cross-platform mobile and web application
- **Dart**: Programming language
- **Riverpod**: State management (existing)
- **WebSocket**: Real-time communication
- **JSON**: Message serialization

#### Infrastructure
- **PostgreSQL**: Primary message storage
- **Redis**: Session management and real-time data
- **Docker**: Containerized deployment
- **Environment Config**: Flexible configuration management

---

## Required Dependencies

### Backend Dependencies (FastAPI)

```python
# Add to requirements.txt
fastapi==0.104.1
websockets==12.0
sqlalchemy==2.0.23
alembic==1.12.1
redis==5.0.1
celery==5.3.4  # For async message processing
pydantic==2.5.0
python-multipart==0.0.6  # For file uploads in chat
```

### Frontend Dependencies (Flutter)

```yaml
# Add to pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management (existing)
  flutter_riverpod: ^2.5.1
  
  # HTTP and WebSocket
  dio: ^5.7.0
  web_socket_channel: ^2.4.0
  socket_io_client: ^2.0.3+1
  
  # Real-time and Animation
  flutter_animate: ^4.2.0+1
  lottie: ^2.7.0  # For typing indicators and animations
  
  # UI Components
  intl: ^0.18.1  # For message timestamps
  cached_network_image: ^3.3.0  # For user avatars
  
  # Data Persistence
  hive: ^2.2.3
  hive_flutter: ^1.1.0  # For local chat storage
  
  # Utilities
  uuid: ^4.2.1  # For message IDs
  timeago: ^3.6.0  # For relative timestamps
```

### Development Dependencies

```yaml
# Add to pubspec.yaml (dev_dependencies)
dev_dependencies:
  # Testing
  mockito: ^5.4.3
  mocktail: ^1.0.3
  hive_test: ^1.0.0  # For Hive testing
  
  # Code Generation
  build_runner: ^2.4.12
  hive_generator: ^2.0.1
  
  # Linting
  flutter_lints: ^3.0.0
```

---

## Backend API Design

### WebSocket Endpoints

#### Chat Connection
```python
# /api/v1/chat/websocket/{session_id}
@router.websocket("/chat/websocket/{session_id}")
async def chat_websocket(websocket: WebSocket, session_id: str):
    """
    WebSocket endpoint for real-time chat communication.
    
    Features:
    - Message send/receive
    - Typing indicators
    - Connection status
    - Auto-reconnection support
    """
```

#### Chat Session Management
```python
# RESTful endpoints for chat session management
@router.post("/chat/sessions", response_model=ChatSessionResponse)
async def create_chat_session(request: CreateChatSessionRequest)

@router.get("/chat/sessions/{session_id}", response_model=ChatSessionResponse)
async def get_chat_session(session_id: str)

@router.delete("/chat/sessions/{session_id}")
async def delete_chat_session(session_id: str)
```

### Message Handling

#### Send Message
```python
@router.post("/chat/sessions/{session_id}/messages", response_model=MessageResponse)
async def send_message(
    session_id: str,
    request: SendMessageRequest
):
    """
    Send a message in a chat session.
    
    Process:
    1. Validate session and permissions
    2. Store message in database
    3. Queue for LLM processing
    4. Broadcast via WebSocket
    5. Return immediate response
    """
```

#### Get Messages
```python
@router.get("/chat/sessions/{session_id}/messages", response_model=List[MessageResponse])
async def get_messages(
    session_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    before: Optional[datetime] = None
):
    """
    Retrieve messages for a chat session with pagination.
    """
```

### LLM Integration

#### Process LLM Response
```python
@router.post("/chat/sessions/{session_id}/process-llm")
async def process_llm_response(
    session_id: str,
    request: ProcessLLMRequest
):
    """
    Process LLM response for a chat message.
    
    Integrates with existing LLM service for:
    - Model selection
    - Response generation
    - Error handling
    - Performance tracking
    """
```

#### Stream LLM Response
```python
@router.websocket("/chat/llm-stream/{message_id}")
async def llm_response_stream(websocket: WebSocket, message_id: str):
    """
    WebSocket endpoint for streaming LLM responses.
    
    Features:
    - Token-by-token streaming
    - Real-time response updates
    - Error handling
    - Cancellation support
    """
```

### Database Schema

#### Chat Sessions
```sql
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    title VARCHAR(255),
    llm_provider VARCHAR(50) NOT NULL,
    llm_model VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);
```

#### Messages
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    llm_response_time_ms INTEGER,
    tokens_used INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Flutter Chat UI Architecture

### Chat Screen Structure

```dart
// Main chat screen component
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: ChatAppBar(),
      body: Column(
        children: [
          // Chat message list
          Expanded(child: MessageList()),
          
          // Input area
          ChatInputArea(),
          
          // LLM status indicator
          LLMStatusIndicator(),
        ],
      ),
    );
  }
}
```

### Core Components

#### Message List Component
```dart
class MessageList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);
    final isConnected = ref.watch(websocketConnectionProvider);
    
    return RefreshIndicator(
      onRefresh: () => ref.refresh(chatSessionProvider),
      child: ListView.builder(
        reverse: true,  // Most recent messages at bottom
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[messages.length - 1 - index];
          return MessageBubble(
            message: message,
            isStreaming: message.isStreaming,
          );
        },
      ),
    );
  }
}
```

#### Message Bubble Component
```dart
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  
  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            UserAvatar(provider: message.llmProvider),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[500] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.content.isNotEmpty)
                    SelectableText(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  if (isStreaming)
                    TypingIndicator(),
                  if (message.errorMessage != null)
                    ErrorDisplay(message.errorMessage!),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            UserAvatar(isCurrentUser: true),
          ],
        ],
      ),
    );
  }
}
```

#### Chat Input Component
```dart
class ChatInputArea extends ConsumerStatefulWidget {
  @override
  _ChatInputAreaState createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends ConsumerState<ChatInputArea> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(websocketConnectionProvider);
    final isProcessing = ref.watch(processingMessageProvider);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                enabled: isConnected && !isProcessing,
                decoration: InputDecoration(
                  hintText: isConnected 
                      ? 'Type your message...' 
                      : 'Connecting...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _handleSendMessage,
              ),
            ),
            SizedBox(width: 8),
            SendButton(
              onPressed: _handleSendMessage,
              enabled: isConnected && !isProcessing && _controller.text.trim().isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleSendMessage([String? value]) async {
    final message = value ?? _controller.text.trim();
    if (message.isEmpty) return;
    
    _controller.clear();
    await ref.read(chatServiceProvider).sendMessage(message);
  }
}
```

---

## Message Models and State Management

### Core Models

#### Chat Message Model
```dart
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

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
  List<Object?> get props => [
    id,
    sessionId,
    role,
    content,
    createdAt,
    isStreaming,
    errorMessage,
  ];
}

enum MessageRole { user, assistant, system }
```

#### Chat Session Model
```dart
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

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    userId,
    llmProvider,
    llmModel,
    isActive,
    messageCount,
  ];
}
```

### State Management Providers

#### Chat Session Provider
```dart
final chatSessionProvider = StateProvider<ChatSession?>((ref) => null);

final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, AsyncValue<List<ChatSession>>>(
  (ref) => ChatSessionsNotifier(ref),
);

class ChatSessionsNotifier extends StateNotifier<AsyncValue<List<ChatSession>>> {
  ChatSessionsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadSessions();
  }

  final Ref _ref;

  Future<void> loadSessions() async {
    try {
      state = const AsyncValue.loading();
      final sessions = await _ref.read(chatServiceProvider).getSessions();
      state = AsyncValue.data(sessions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createSession({
    required String title,
    required LLMProvider provider,
    required String model,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final session = await _ref.read(chatServiceProvider).createSession(
        title: title,
        provider: provider,
        model: model,
        settings: settings,
      );
      
      state = await _ref.read(chatSessionsProvider.notifier).loadSessions();
    } catch (error) {
      rethrow;
    }
  }
}
```

#### Chat Messages Provider
```dart
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>(
  (ref, sessionId) => ChatMessagesNotifier(ref, sessionId),
);

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatMessagesNotifier(this._ref, this._sessionId) : super(const AsyncValue.loading()) {
    loadMessages();
    _setupWebSocketListener();
  }

  final Ref _ref;
  final String _sessionId;
  StreamSubscription<WebSocketMessage>? _webSocketSubscription;

  Future<void> loadMessages() async {
    try {
      state = const AsyncValue.loading();
      final messages = await _ref.read(chatServiceProvider).getMessages(_sessionId);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _setupWebSocketListener() {
    _webSocketSubscription = _ref.read(websocketServiceProvider).messagesStream.listen(
      (message) {
        if (message.sessionId == _sessionId) {
          state = state.whenData((messages) => [...messages, message]);
        }
      },
    );
  }

  Future<void> sendMessage(String content) async {
    try {
      await _ref.read(chatServiceProvider).sendMessage(_sessionId, content);
    } catch (error) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    super.dispose();
  }
}
```

#### WebSocket Connection Provider
```dart
final websocketConnectionProvider = StateProvider<WebSocketConnectionStatus>((ref) {
  return WebSocketConnectionStatus.disconnected;
});

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(
    ref.read(dioProvider),
    ref.read(websocketConnectionProvider.notifier),
  );
});

enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketService {
  WebSocketService(this._dio, this._connectionProvider);

  final Dio _dio;
  final StateController<WebSocketConnectionStatus> _connectionProvider;
  WebSocket? _webSocket;
  StreamController<WebSocketMessage>? _messageController;

  Stream<WebSocketMessage> get messagesStream => _messageController?.stream ?? const Stream.empty();

  Future<void> connect(String sessionId) async {
    try {
      _connectionProvider.state = WebSocketConnectionStatus.connecting;
      
      final wsUrl = 'ws://localhost:8000/api/v1/chat/websocket/$sessionId';
      _webSocket = WebSocket(wsUrl);
      _messageController = StreamController<WebSocketMessage>.broadcast();
      
      await _webSocket!.connect();
      _connectionProvider.state = WebSocketConnectionStatus.connected;
      
      _webSocket!.listen(
        (data) => _handleMessage(data),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnection(),
      );
    } catch (error) {
      _connectionProvider.state = WebSocketConnectionStatus.error;
      rethrow;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = WebSocketMessage.fromJson(json.decode(data as String));
      _messageController?.add(message);
    } catch (error) {
      debugPrint('Error parsing WebSocket message: $error');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _connectionProvider.state = WebSocketConnectionStatus.error;
  }

  void _handleDisconnection() {
    _connectionProvider.state = WebSocketConnectionStatus.disconnected;
  }

  Future<void> sendMessage(WebSocketMessage message) async {
    if (_webSocket != null && _connectionProvider.state == WebSocketConnectionStatus.connected) {
      _webSocket!.add(json.encode(message.toJson()));
    } else {
      throw Exception('WebSocket not connected');
    }
  }

  void dispose() {
    _webSocket?.close();
    _messageController?.close();
  }
}

class WebSocketMessage {
  final String sessionId;
  final String messageId;
  final WebSocketMessageType type;
  final dynamic data;

  WebSocketMessage({
    required this.sessionId,
    required this.messageId,
    required this.type,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      sessionId: json['session_id'] as String,
      messageId: json['message_id'] as String,
      type: WebSocketMessageType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'message_id': messageId,
      'type': type.name,
      'data': data,
    };
  }
}

enum WebSocketMessageType {
  newMessage,
  typing,
  messageUpdate,
  error,
  connectionStatus,
}
```

---

## Integration Strategy

### LLM Service Integration

#### Extending Existing LlmService
```dart
// Add to flutter/lib/services/llm_service.dart
class LlmService {
  // ... existing methods ...
  
  // New chat-related methods
  Future<ChatSession> createChatSession({
    required String title,
    required LLMProvider provider,
    required String model,
  }) async {
    final response = await _dio.post(
      '/chat/sessions',
      data: {
        'title': title,
        'llm_provider': provider.name,
        'llm_model': model,
      },
    );
    return ChatSession.fromJson(response.data);
  }

  Future<List<ChatMessage>> getChatMessages(
    String sessionId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/chat/sessions/$sessionId/messages',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    
    final messages = (response.data as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
    
    return messages;
  }

  Future<ChatMessage> sendChatMessage(
    String sessionId,
    String content,
  ) async {
    final response = await _dio.post(
      '/chat/sessions/$sessionId/messages',
      data: {'content': content},
    );
    
    return ChatMessage.fromJson(response.data);
  }
}
```

#### Provider Integration
```dart
// flutter/lib/providers/llm_chat_provider.dart
final llmChatProvider = StateNotifierProvider<LlmChatNotifier, AsyncValue<LlmChatState>>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  return LlmChatNotifier(llmService);
});

class LlmChatNotifier extends StateNotifier<AsyncValue<LlmChatState>> {
  LlmChatNotifier(this._llmService) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final LlmService _llmService;

  Future<void> _initialize() async {
    try {
      // Load current LLM configuration
      final config = await _llmService.getConfig();
      state = AsyncValue.data(LlmChatState(
        config: config,
        currentSession: null,
        messages: const [],
        isProcessing: false,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> startChatSession(String modelName) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      state = AsyncValue.data(currentState.copyWith(isProcessing: true));

      final session = await _llmService.createChatSession(
        title: 'Chat with $modelName',
        provider: currentState.config.activeProvider,
        model: modelName,
      );

      final messages = await _llmService.getChatMessages(session.id);

      state = AsyncValue.data(currentState.copyWith(
        currentSession: session,
        messages: messages,
        isProcessing: false,
      ));
    } catch (error) {
      state = AsyncValue.data(currentState.copyWith(isProcessing: false));
      rethrow;
    }
  }

  Future<void> sendMessage(String content) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.currentSession == null) return;

    try {
      // Add user message immediately
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: currentState.currentSession!.id,
        role: MessageRole.user,
        content: content,
        createdAt: DateTime.now(),
      );

      state = AsyncValue.data(currentState.copyWith(
        messages: [...currentState.messages, userMessage],
        isProcessing: true,
      ));

      // Send message and get response
      await _llmService.sendChatMessage(currentState.currentSession!.id, content);

      // Load updated messages
      final updatedMessages = await _llmService.getChatMessages(
        currentState.currentSession!.id,
      );

      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        isProcessing: false,
      ));
    } catch (error) {
      state = AsyncValue.data(currentState.copyWith(isProcessing: false));
      rethrow;
    }
  }
}
```

### Screen Integration

#### Replacing LLM Testing Block
```dart
// Update flutter/lib/screens/llm_dashboard_screen.dart

class _LlmDashboardScreenState extends State<LlmDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => _openChatInterface(),
          ),
        ],
      ),
      body: _buildDashboardView(),
    );
  }

  void _openChatInterface() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(),
      ),
    );
  }

  Widget _buildTestInterfaceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Test', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            
            // Replace the old test interface with chat preview
            ChatPreviewWidget(
              onStartChat: () => _openChatInterface(),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Chat Preview Widget
```dart
class ChatPreviewWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(llmChatProvider);
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: chatState.when(
        data: (state) => _buildPreviewContent(context, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorContent(context, error),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, LlmChatState state) {
    if (state.currentSession == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Start a chat session to test the LLM'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _startChatSession(context, ref),
              child: const Text('Start Chat'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: math.min(3, state.messages.length),
            itemBuilder: (context, index) {
              final message = state.messages[state.messages.length - 1 - index];
              return _buildPreviewMessage(message);
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Type a test message...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) => _sendMessage(context, ref, value),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => ref.read(llmChatProvider.notifier).sendMessage('Test message'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewMessage(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.content.length > 50 
            ? '${message.content.substring(0, 50)}...'
            : message.content,
        style: const TextStyle(fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _startChatSession(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(llmChatProvider.notifier).startChatSession('default');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $error')),
      );
    }
  }

  void _sendMessage(BuildContext context, WidgetRef ref, String message) {
    if (message.trim().isNotEmpty) {
      ref.read(llmChatProvider.notifier).sendMessage(message.trim());
    }
  }
}
```

---

## Implementation Timeline and Milestones

### Phase 1: Foundation (Weeks 1-2)

#### Week 1: Backend Infrastructure
- [ ] **Day 1-2**: Database schema design and implementation
  - Create chat_sessions and messages tables
  - Set up database migrations
  - Create SQLAlchemy models
- [ ] **Day 3-4**: WebSocket infrastructure
  - Implement WebSocket connection handling
  - Add message broadcasting system
  - Create WebSocket message schemas
- [ ] **Day 5**: LLM integration endpoints
  - Extend existing LLM service for chat
  - Create message processing pipeline
  - Add async LLM response handling

#### Week 2: Frontend Foundation
- [ ] **Day 1-2**: Chat data models
  - Create ChatMessage and ChatSession models
  - Implement JSON serialization
  - Add model validation
- [ ] **Day 3-4**: State management
  - Create chat providers
  - Implement WebSocket service
  - Add message persistence
- [ ] **Day 5**: Basic UI components
  - Create message bubble components
  - Implement basic chat input
  - Add message list view

### Phase 2: Core Chat Functionality (Weeks 3-4)

#### Week 3: Chat Interface
- [ ] **Day 1-2**: Main chat screen
  - Implement ChatScreen layout
  - Add message list with pagination
  - Create chat input area
- [ ] **Day 3-4**: Real-time messaging
  - Connect WebSocket for real-time updates
  - Implement typing indicators
  - Add connection status handling
- [ ] **Day 5**: Message processing
  - Handle LLM response streaming
  - Add message error handling
  - Implement message retry logic

#### Week 4: LLM Integration
- [ ] **Day 1-2**: Provider integration
  - Connect to existing LLM service
  - Handle provider-specific configurations
  - Add model selection for chat
- [ ] **Day 3-4**: Response handling
  - Implement streaming responses
  - Add token-by-token updates
  - Handle response errors
- [ ] **Day 5**: Performance optimization
  - Add message caching
  - Optimize WebSocket connections
  - Implement connection pooling

### Phase 3: Advanced Features (Weeks 5-6)

#### Week 5: User Experience
- [ ] **Day 1-2**: Chat history
  - Implement message pagination
  - Add chat session management
  - Create chat history view
- [ ] **Day 3-4**: UI polish
  - Add animations and transitions
  - Implement loading states
  - Add error states and recovery
- [ ] **Day 5**: Mobile optimization
  - Ensure responsive design
  - Add touch gestures
  - Optimize performance

#### Week 6: Integration and Testing
- [ ] **Day 1-2**: Dashboard integration
  - Replace LLM testing block
  - Add chat preview widget
  - Update navigation
- [ ] **Day 3-4**: Comprehensive testing
  - Unit tests for all components
  - Widget tests for chat interface
  - Integration tests for LLM flow
- [ ] **Day 5**: Bug fixes and optimization
  - Fix identified issues
  - Performance tuning
  - Code cleanup

### Phase 4: Launch Preparation (Week 7)

#### Week 7: Final Polish
- [ ] **Day 1-2**: Documentation
  - API documentation updates
  - User guide creation
  - Developer documentation
- [ ] **Day 3-4**: Deployment preparation
  - Environment configuration
  - Docker container updates
  - Database migration scripts
- [ ] **Day 5**: Final testing
  - End-to-end testing
  - Performance testing
  - User acceptance testing

### Success Metrics

#### Technical Metrics
- [ ] WebSocket connection stability: >99.5% uptime
- [ ] Message delivery latency: <100ms average
- [ ] LLM response time: <5 seconds for most models
- [ ] App startup time: <3 seconds
- [ ] Memory usage: <100MB for typical chat session

#### User Experience Metrics
- [ ] Message success rate: >99%
- [ ] Auto-reconnection success: >95%
- [ ] UI responsiveness: 60fps on target devices
- [ ] Error recovery: <5 second recovery time
- [ ] User satisfaction: >4.5/5 rating

---

## Success Criteria and Validation

### Functional Requirements ✅

#### Core Chat Functionality
- [ ] **Real-time Messaging**: Messages are delivered instantly via WebSocket
- [ ] **LLM Integration**: Seamless integration with Local and OpenRouter providers
- [ ] **Message History**: Chat sessions persist across app restarts
- [ ] **Typing Indicators**: Visual feedback during LLM response generation
- [ ] **Error Handling**: Graceful handling of network and LLM errors

#### User Interface Requirements
- [ ] **Intuitive Design**: Chat interface follows Material Design principles
- [ ] **Responsive Layout**: Works on mobile, tablet, and desktop devices
- [ ] **Accessibility**: Supports screen readers and keyboard navigation
- [ ] **Performance**: Smooth scrolling and animations at 60fps
- [ ] **Offline Support**: Graceful degradation when network is unavailable

#### Technical Requirements
- [ ] **WebSocket Support**: Real-time bidirectional communication
- [ ] **Database Integration**: Persistent message storage with proper indexing
- [ ] **Security**: Input validation and XSS protection
- [ ] **Scalability**: Support for multiple concurrent chat sessions
- [ ] **Monitoring**: Built-in logging and performance metrics

### Non-Functional Requirements ✅

#### Performance
- [ ] **Response Time**: <3 seconds for chat interface initialization
- [ ] **Latency**: <100ms for message delivery
- [ ] **Throughput**: Support 100+ concurrent users
- [ ] **Scalability**: Horizontal scaling capability
- [ ] **Resource Usage**: <50MB memory footprint

#### Reliability
- [ ] **Uptime**: 99.9% availability target
- [ ] **Recovery**: Automatic reconnection within 5 seconds
- [ ] **Data Integrity**: No message loss during normal operations
- [ ] **Fault Tolerance**: Graceful handling of LLM provider failures
- [ ] **Backup**: Regular message backup and recovery procedures

#### Security
- [ ] **Input Validation**: All user inputs are properly sanitized
- [ ] **Authentication**: Secure session management
- [ ] **Authorization**: Proper access control for chat sessions
- [ ] **Data Protection**: Message content encryption at rest
- [ ] **Privacy**: No unauthorized message access or logging

### Testing Strategy

#### Unit Testing (90% Coverage Target)
- [ ] **Model Testing**: ChatMessage, ChatSession serialization
- [ ] **Service Testing**: LlmService chat methods
- [ ] **Provider Testing**: State management logic
- [ ] **Utility Testing**: Message formatting and validation
- [ ] **Error Handling**: Exception scenarios and edge cases

#### Widget Testing
- [ ] **Component Testing**: Message bubble, input area, message list
- [ ] **Integration Testing**: Chat screen interactions
- [ ] **State Testing**: Provider state changes and UI updates
- [ ] **Navigation Testing**: Chat screen routing and navigation
- [ ] **Accessibility Testing**: Screen reader and keyboard navigation

#### Integration Testing
- [ ] **End-to-End Testing**: Complete chat flow with real LLM providers
- [ ] **WebSocket Testing**: Real-time message delivery
- [ ] **Database Testing**: Message persistence and retrieval
- [ ] **Error Recovery Testing**: Network failures and reconnection
- [ ] **Performance Testing**: Load testing with multiple users

#### User Acceptance Testing
- [ ] **Usability Testing**: User interface intuitiveness
- [ ] **Performance Testing**: Real-world usage scenarios
- [ ] **Compatibility Testing**: Cross-platform functionality
- [ ] **Reliability Testing**: Extended usage and stress testing
- [ ] **Feedback Integration**: User feedback incorporation

---

## Risk Assessment and Mitigation

### Technical Risks

#### Risk: WebSocket Connection Issues
- **Probability**: Medium
- **Impact**: High
- **Mitigation**: 
  - Implement automatic reconnection with exponential backoff
  - Add fallback to polling for critical messages
  - Comprehensive connection testing and monitoring

#### Risk: LLM Provider Outages
- **Probability**: Medium
- **Impact**: High
- **Mitigation**:
  - Implement provider failover switching
  - Cache recent responses for offline access
  - Clear user communication about provider status

#### Risk: Database Performance Issues
- **Probability**: Low
- **Impact**: High
- **Mitigation**:
  - Proper indexing on message queries
  - Database connection pooling
  - Query optimization and monitoring

### Security Risks

#### Risk: Message Interception
- **Probability**: Low
- **Impact**: High
- **Mitigation**:
  - HTTPS enforcement for all communications
  - WebSocket over WSS for secure connections
  - Regular security audits and penetration testing

#### Risk: Data Leakage
- **Probability**: Low
- **Impact**: High
- **Mitigation**:
  - Message encryption at rest
  - Access control and authentication
  - Regular backup and secure disposal procedures

### Project Risks

#### Risk: Timeline Overrun
- **Probability**: Medium
- **Impact**: Medium
- **Mitigation**:
  - Agile development with regular milestones
  - Feature prioritization and scope management
  - Early identification of blockers and dependencies

#### Risk: Resource Constraints
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**:
  - Proper resource planning and allocation
  - Regular progress monitoring
  - Contingency planning for additional resources

---

## Conclusion

The implementation of a real-time chat interface represents a significant enhancement to the Script Rating system's LLM capabilities. This comprehensive plan leverages the existing robust infrastructure while introducing modern real-time communication features that will transform the user experience.

### Key Strengths of the Current Foundation
1. **Comprehensive LLM Infrastructure**: The existing FastAPI backend provides a solid foundation with extensive provider support
2. **Well-Designed Architecture**: Clean separation of concerns with proper service layer design
3. **Extensive Testing Framework**: Existing test infrastructure ensures high code quality
4. **Model Consistency**: Backend and frontend models are well-aligned and comprehensive

### Expected Outcomes
1. **Enhanced User Experience**: Real-time chat interface replacing static testing
2. **Improved LLM Interaction**: Conversational flow enabling better model evaluation
3. **Scalable Architecture**: WebSocket-based system supporting future enhancements
4. **Maintained Reliability**: Integration with existing robust LLM service architecture

### Next Steps
1. **Approval and Planning**: Finalize scope and obtain stakeholder approval
2. **Resource Allocation**: Assign development team and establish timeline
3. **Infrastructure Preparation**: Set up development and testing environments
4. **Implementation Start**: Begin with Phase 1 foundation development

This implementation plan provides a clear roadmap for delivering a modern, scalable, and user-friendly real-time chat interface that will significantly enhance the Script Rating system's LLM testing and interaction capabilities.

---

*Document prepared by: System Architecture Team*  
*Last updated: 2025-11-10*  
*Version: 1.0*