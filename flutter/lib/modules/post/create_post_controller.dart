import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/upload_service.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/services/post_service.dart';
import '../../data/models/post_model.dart';

class CreatePostController extends GetxController {
  final PostRepository _repo = PostRepository();

  final contentCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final locationName = ''.obs;
  final selectedType = 'POST'.obs;
  final isSubmitting = false.obs;
  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();
  final _uploadService = UploadService();
  final pickedImages = <Uint8List>[].obs;
  final pickedNames = <String>[].obs;
  final ImagePicker _picker = ImagePicker();

  // Tag support
  final tags = <String>[].obs;
  final tagInputCtrl = TextEditingController();
  final showTagPicker = false.obs;

  static const hotTags = [
    '日常', '美食', '旅行', '摄影', '音乐', '电影', '读书', '运动',
    '游戏', '科技', '时尚', '生活', '搞笑', '萌宠', '绘画', '手工',
    '健身', '穿搭', '探店', '打卡',
  ];

  @override
  void onInit() {
    super.onInit();
    contentCtrl.addListener(_onContentChanged);
  }

  @override
  void onClose() {
    contentCtrl.removeListener(_onContentChanged);
    contentCtrl.dispose();
    titleCtrl.dispose();
    locationCtrl.dispose();
    tagInputCtrl.dispose();
    super.onClose();
  }

  void _onContentChanged() {
    final text = contentCtrl.text;
    final cursorPos = contentCtrl.selection.baseOffset;
    if (cursorPos > 0 && cursorPos <= text.length && text[cursorPos - 1] == '#') {
      showTagPicker.value = true;
    }
  }

  void addTag(String tag) {
    final trimmed = tag.trim().replaceAll('#', '');
    if (trimmed.isNotEmpty && !tags.contains(trimmed) && tags.length < 5) {
      tags.add(trimmed);
    }
    showTagPicker.value = false;
  }

  void removeTag(String tag) {
    tags.remove(tag);
  }

  void setLocation(String name, double? lat, double? lng) {
    locationCtrl.text = name;
    locationName.value = name;
    selectedLatitude.value = lat;
    selectedLongitude.value = lng;
  }

  Future<void> pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    for (final xfile in images) {
      final bytes = await xfile.readAsBytes();
      pickedImages.add(bytes);
      pickedNames.add(xfile.name);
    }
  }

  void removeImage(int index) {
    pickedImages.removeAt(index);
    if (index < pickedNames.length) pickedNames.removeAt(index);
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = pickedImages.removeAt(oldIndex);
    pickedImages.insert(newIndex, item);
    if (oldIndex < pickedNames.length) {
      final name = pickedNames.removeAt(oldIndex);
      pickedNames.insert(newIndex, name);
    }
  }

  Future<void> submit() async {
    final content = contentCtrl.text.trim();
    if (content.isEmpty) {
      Get.snackbar('提示', '请输入内容');
      return;
    }
    isSubmitting.value = true;
    try {
      final data = <String, dynamic>{
        'content': content,
        'type': selectedType.value,
      };
      if (selectedType.value == 'ARTICLE' && titleCtrl.text.trim().isNotEmpty) {
        data['title'] = titleCtrl.text.trim();
      }
      if (tags.isNotEmpty) {
        data['tags'] = tags.toList();
      }
      if (locationCtrl.text.trim().isNotEmpty) {
        data['locationName'] = locationCtrl.text.trim();
      }
      if (selectedLatitude.value != null) {
        data['latitude'] = selectedLatitude.value;
      }
      if (selectedLongitude.value != null) {
        data['longitude'] = selectedLongitude.value;
      }
      if (pickedImages.isNotEmpty) {
        final imageUrls = <String>[];
        for (int i = 0; i < pickedImages.length; i++) {
          try {
            final name = i < pickedNames.length ? pickedNames[i] : 'image_$i.jpg';
            final url = await _uploadService.uploadImageBytes(pickedImages[i], name);
            imageUrls.add(url);
          } catch (e) {
            Get.snackbar('Error', 'Image upload failed: $e');
          }
        }
        if (imageUrls.isNotEmpty) {
          data['images'] = imageUrls;
        }
      }
      final post = await _repo.createPost(data);
      // 通知所有已注册的列表（发现页、社区页等）新帖子已发布
      try {
        Get.find<PostService>().notifyPostCreated(post);
      } catch (_) {}
      Get.back(result: true);
      Get.snackbar('成功', '发布成功');
    } catch (e) {
      Get.snackbar('失败', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
