import 'package:get/get.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../core/network/socket_service.dart';
import '../../core/storage/storage_service.dart';
import '../home/home_controller.dart';

class ChatListController extends GetxController {
  final ChatRepository _repo = ChatRepository();
  final conversations = <ConversationModel>[].obs;
  final isLoading = false.obs;

  void _updateUnreadCount() {
    try {
      Get.find<HomeController>().updateUnreadConversationCount();
    } catch (_) {}
  }

  void _setupSocket() {
    SocketService.to.onReceiveMessage((data) {
      final convId = data['conversationId'];
      final senderId = data['senderId'];
      final isSelf = senderId == StorageService.to.getUser()?['id'];
      final index = conversations.indexWhere((c) => c.id == convId);
      if (index >= 0) {
        final conv = conversations.removeAt(index);
        final updated = ConversationModel(
          id: conv.id, type: conv.type, name: conv.name, avatar: conv.avatar,
          members: conv.members, unreadCount: isSelf ? conv.unreadCount : conv.unreadCount + 1,
          isPinned: conv.isPinned, isMuted: conv.isMuted,
          lastMessage: LastMessage(
            id: data['id'], content: data['content'], type: data['type'],
            senderId: data['senderId'], senderName: data['senderName'],
            createdAt: data['createdAt'],
          ),
          updatedAt: data['createdAt'],
        );
        _insertSorted(updated);
      } else {
        final otherName = data['otherMemberName'] ?? '';
        final otherAvatar = data['otherMemberAvatar'];
        final newConv = ConversationModel(
          id: convId,
          type: 'PRIVATE',
          name: otherName.isNotEmpty ? otherName : (data['senderName'] ?? ''),
          avatar: isSelf ? otherAvatar : data['senderAvatar'],
          unreadCount: isSelf ? 0 : 1,
          lastMessage: LastMessage(
            id: data['id'], content: data['content'], type: data['type'],
            senderId: data['senderId'], senderName: data['senderName'],
            createdAt: data['createdAt'],
          ),
          updatedAt: data['createdAt'],
        );
        _insertSorted(newConv);
        loadConversations();
      }
      _updateUnreadCount();
    });
  }

  void _insertSorted(ConversationModel conv) {
    if (conv.isPinned) {
      int lastPinned = -1;
      for (int i = 0; i < conversations.length; i++) {
        if (conversations[i].isPinned) lastPinned = i;
      }
      conversations.insert(lastPinned + 1, conv);
    } else {
      final firstNonPinned = conversations.indexWhere((c) => !c.isPinned);
      if (firstNonPinned >= 0) {
        conversations.insert(firstNonPinned, conv);
      } else {
        conversations.add(conv);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadConversations();
    _setupSocket();
  }

  Future<void> loadConversations() async {
    isLoading.value = true;
    try {
      final list = await _repo.getConversations();
      conversations.value = list.where((c) => c.id.isNotEmpty).toList();
      _updateUnreadCount();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _repo.deleteConversation(id);
      conversations.removeWhere((c) => c.id == id);
      _updateUnreadCount();
    } catch (_) {}
  }

  Future<void> togglePin(String id) async {
    try {
      final isPinned = await _repo.pinConversation(id);
      final index = conversations.indexWhere((c) => c.id == id);
      if (index < 0) return;
      final conv = conversations.removeAt(index);
      _insertSorted(conv.copyWith(isPinned: isPinned));
    } catch (_) {}
  }

  Future<void> markAsUnread(String id) async {
    try {
      await _repo.markUnread(id);
      final index = conversations.indexWhere((c) => c.id == id);
      if (index < 0) return;
      final conv = conversations.removeAt(index);
      _insertSorted(conv.copyWith(unreadCount: 1));
      _updateUnreadCount();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repo.markRead(id);
      clearLocalUnread(id);
    } catch (_) {}
  }

  void clearLocalUnread(String id) {
    final index = conversations.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final conv = conversations[index];
    if (conv.unreadCount > 0) {
      conversations[index] = conv.copyWith(unreadCount: 0);
      _updateUnreadCount();
    }
  }
}
