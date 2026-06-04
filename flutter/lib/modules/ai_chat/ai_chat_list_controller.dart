import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/ai_conversation_model.dart';

class AiChatListController extends GetxController with WidgetsBindingObserver {
  final conversations = <AiConversationModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadConversations();
    }
  }

  /// 手动刷新列表（从详情页返回时调用）
  void refreshConversations() {
    _loadConversations();
  }

  void _loadConversations() {
    try {
      final list = StorageService.to.getAiConversations();
      final parsed = <AiConversationModel>[];
      for (final json in list) {
        try {
          parsed.add(AiConversationModel.fromJson(json));
        } catch (_) {
          // Skip malformed conversations instead of failing the entire list
        }
      }
      conversations.value = parsed;
      _sortConversations();
    } catch (_) {
      conversations.value = [];
    }
  }

  void _sortConversations() {
    conversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> createConversation() async {
    final now = DateTime.now();
    final conv = AiConversationModel(
      id: now.millisecondsSinceEpoch.toString(),
      title: '新对话',
      createdAt: now,
      updatedAt: now,
    );
    conversations.insert(0, conv);
    _persistConversations();
    Get.toNamed('/ai-chat/detail/${conv.id}');
  }

  Future<void> deleteConversation(String id) async {
    // Clean up image files before removing messages
    try {
      final msgs = StorageService.to.getAiMessages(id);
      final allPaths = <String>[];
      for (final m in msgs) {
        final images = m['images'];
        if (images is List) {
          for (final img in images) {
            if (img is String && ImageCacheService.isFilePath(img)) {
              allPaths.add(img);
            }
          }
        }
      }
      await ImageCacheService.to.deleteImages(allPaths);
    } catch (_) {}
    conversations.removeWhere((c) => c.id == id);
    _persistConversations();
    await StorageService.to.deleteAiMessages(id);
  }

  Future<void> togglePin(String id) async {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final conv = conversations[idx];
    conversations[idx] = conv.copyWith(isPinned: !conv.isPinned);
    _sortConversations();
    _persistConversations();
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    conversations[idx] = conversations[idx].copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    _persistConversations();
  }

  void _persistConversations() {
    final list = conversations.map((c) => c.toJson()).toList();
    StorageService.to.saveAiConversations(list);
  }
}
