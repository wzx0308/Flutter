import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/follow_provider.dart';

class FriendsListController extends GetxController {
  final FollowProvider _followProvider = FollowProvider();

  final users = <UserModel>[].obs;
  final searchResults = <UserModel>[].obs;
  final isLoading = false.obs;
  final hasMore = true.obs;
  final isSearching = false.obs;
  final searchKeyword = ''.obs;
  int _page = 1;
  int _searchPage = 1;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadFriends();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void onSearchChanged(String keyword) {
    searchKeyword.value = keyword;
    _debounce?.cancel();
    if (keyword.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchUsers(keyword.trim());
    });
  }

  Future<void> searchUsers(String keyword) async {
    _searchPage = 1;
    isSearching.value = true;
    isLoading.value = true;
    try {
      final res = await _followProvider.searchUsers(keyword, page: 1, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        searchResults.value = (list as List).map((e) => UserModel.fromJson(e)).toList();
        hasMore.value = searchResults.length < (data is Map ? (data['total'] ?? 0) : 0);
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFriends() async {
    _page = 1;
    isLoading.value = true;
    hasMore.value = true;
    try {
      final res = await _followProvider.getFriends(page: 1, pageSize: 20);
      if (res['code'] == 0) {
        final data = res['data'];
        final list = data is Map ? (data['list'] ?? []) : data;
        users.value = (list as List).map((e) => UserModel.fromJson(e)).toList();
        hasMore.value = users.length < (data is Map ? (data['total'] ?? 0) : 0);
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    isLoading.value = true;
    try {
      if (isSearching.value) {
        _searchPage++;
        final res = await _followProvider.searchUsers(searchKeyword.value, page: _searchPage, pageSize: 20);
        if (res['code'] == 0) {
          final data = res['data'];
          final list = data is Map ? (data['list'] ?? []) : data;
          final more = (list as List).map((e) => UserModel.fromJson(e)).toList();
          searchResults.addAll(more);
          hasMore.value = more.length >= 20;
        } else {
          _searchPage--;
        }
      } else {
        _page++;
        final res = await _followProvider.getFriends(page: _page, pageSize: 20);
        if (res['code'] == 0) {
          final data = res['data'];
          final list = data is Map ? (data['list'] ?? []) : data;
          final more = (list as List).map((e) => UserModel.fromJson(e)).toList();
          users.addAll(more);
          hasMore.value = more.length >= 20;
        } else {
          _page--;
        }
      }
    } catch (_) {
      if (isSearching.value) {
        _searchPage--;
      } else {
        _page--;
      }
    } finally {
      isLoading.value = false;
    }
  }
}
