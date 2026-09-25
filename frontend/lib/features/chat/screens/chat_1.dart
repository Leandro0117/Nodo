import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nodo/core/constants/api_constants.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/chat/logic/chat_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final String applicationId;
  final String currentUserId;
  final String otherPersonName;

  /// Cuando es `true` el historial se muestra pero no se pueden enviar mensajes
  /// (trabajo finalizado). No se abre WebSocket.
  final bool readOnly;

  const ChatScreen({
    super.key,
    required this.applicationId,
    required this.currentUserId,
    required this.otherPersonName,
    this.readOnly = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _conversationId;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;

  List<Map<String, dynamic>> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;
  bool _wsConnected = false;
  String? _error;

  static const _bgChat = Color(0xFFEFF3F7);
  static const _textDark = Color(0xFF1A2A3A);
  static const _bubbleBorder = Color(0xFFDDE3EA);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _channel?.sink.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final id = await ChatService.getOrCreateConversation(widget.applicationId);
      if (!mounted) return;
      setState(() => _conversationId = id);
      await _loadHistory();
      // En modo solo-lectura no se necesita WebSocket
      if (!widget.readOnly) _connectWebSocket(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el chat.';
        _loadingHistory = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final msgs = await ChatService.getMessages(_conversationId!);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  void _connectWebSocket(String conversationId) {
    final uri = Uri.parse(ApiConstants.chatWsUrl(conversationId));
    _channel = WebSocketChannel.connect(uri);

    _wsSub = _channel!.stream.listen(
      (raw) {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        if (data['type'] == 'message') {
          final optimisticIdx = _messages.indexWhere(
            (m) =>
                m['id'] == 'pending' &&
                m['senderId'] == data['senderId'] &&
                m['content'] == data['content'],
          );
          setState(() {
            if (optimisticIdx >= 0) {
              _messages[optimisticIdx] = data;
            } else {
              _messages = [..._messages, data];
            }
          });
          _scrollToBottom();
        }
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _wsConnected = false);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _conversationId != null) _connectWebSocket(_conversationId!);
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _wsConnected = false);
      },
    );

    if (mounted) setState(() => _wsConnected = true);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _channel == null || _sending) return;

    _inputController.clear();
    setState(() => _sending = true);

    final optimistic = <String, dynamic>{
      'id': 'pending',
      'senderId': widget.currentUserId,
      'content': text,
      'sentAt': DateTime.now().toIso8601String(),
      'status': 'sent',
    };
    setState(() {
      _messages = [..._messages, optimistic];
      _sending = false;
    });
    _scrollToBottom();

    try {
      _channel!.sink.add(jsonEncode({
        'senderId': widget.currentUserId,
        'content': text,
      }));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages = _messages.where((m) => m['id'] != 'pending').toList());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje.')),
      );
      _inputController.text = text;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('h:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }

  String _formatDateLabel(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDay = DateTime(date.year, date.month, date.day);
      if (msgDay == today) return 'Hoy';
      if (msgDay == yesterday) return 'Ayer';
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  bool _showDateSeparator(int index) {
    if (index == 0) return true;
    try {
      final curr = DateTime.parse(_messages[index]['sentAt'] ?? '').toLocal();
      final prev = DateTime.parse(_messages[index - 1]['sentAt'] ?? '').toLocal();
      return !(curr.year == prev.year &&
          curr.month == prev.month &&
          curr.day == prev.day);
    } catch (_) {
      return false;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgChat,
      appBar: _buildAppBar(),
      body: _loadingHistory
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            )
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    if (widget.readOnly)
                      _buildReadOnlyBanner()
                    else
                      _buildInputBar(),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.blue,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.orange,
            child: Text(
              _initials(widget.otherPersonName),
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontFamily: 'GothamBold',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.otherPersonName,
                  style: AppTypography.subtitle.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.readOnly)
                  Text(
                    'Solo lectura · Trabajo finalizado',
                    style: AppTypography.caption.copyWith(color: Colors.white60),
                  )
                else if (!_wsConnected && !_loadingHistory)
                  Text(
                    'Reconectando…',
                    style: AppTypography.caption.copyWith(color: Colors.white60),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.slateGrey),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.body.copyWith(color: AppColors.slateGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loadingHistory = true;
                });
                _init();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin mensajes',
              style: AppTypography.subtitle.copyWith(color: AppColors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              widget.readOnly
                  ? 'No hubo mensajes en este trabajo.'
                  : '¡Inicia la conversación!',
              style: AppTypography.body.copyWith(color: AppColors.slateGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg['senderId'] == widget.currentUserId;
        final isPending = msg['id'] == 'pending';
        return Column(
          children: [
            if (_showDateSeparator(index)) _buildDateSeparator(msg['sentAt']),
            _buildBubble(msg, isMe, isPending),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(String? iso) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Color(0xFFCDD5DD), thickness: 0.8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _formatDateLabel(iso),
              style: AppTypography.caption.copyWith(color: AppColors.slateGrey),
            ),
          ),
          const Expanded(
            child: Divider(color: Color(0xFFCDD5DD), thickness: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, bool isPending) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: isMe ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: _bubbleBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['content'] ?? '',
              style: AppTypography.body.copyWith(
                color: isMe ? Colors.white : _textDark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg['sentAt']),
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: isMe ? Colors.white54 : AppColors.slateGrey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isPending
                        ? Icons.access_time_rounded
                        : Icons.done_rounded,
                    size: 11,
                    color: Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Banner que reemplaza la barra de escritura cuando el trabajo ya terminó.
  Widget _buildReadOnlyBanner() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.08),
          border: Border(
            top: BorderSide(color: AppColors.success.withOpacity(0.25)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            Text(
              'Este trabajo ha finalizado · El chat es de solo lectura',
              style: AppTypography.caption.copyWith(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgChat,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _bubbleBorder),
                  ),
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje…',
                      hintStyle: AppTypography.body
                          .copyWith(color: AppColors.slateGrey),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: AppTypography.body.copyWith(color: _textDark),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
