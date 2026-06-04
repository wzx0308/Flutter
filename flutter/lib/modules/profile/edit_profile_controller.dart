import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/upload_service.dart';
import '../../core/storage/storage_service.dart';
import '../../data/repositories/user_repository.dart';
import '../home/home_controller.dart';

class EditProfileController extends GetxController {
  final UserRepository _userRepo = UserRepository();
  final _uploadService = UploadService();
  Uint8List? _avatarBytes;
  String? _avatarName;

  final nicknameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final avatarUrl = ''.obs;
  final selectedGender = 'UNKNOWN'.obs;
  final selectedBirthday = Rxn<DateTime>();
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    nicknameCtrl.dispose();
    bioCtrl.dispose();
    locationCtrl.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final userData = StorageService.to.getUser();
    if (userData != null) {
      nicknameCtrl.text = userData['nickname'] ?? '';
      bioCtrl.text = userData['bio'] ?? '';
      locationCtrl.text = userData['location'] ?? '';
      avatarUrl.value = userData['avatar'] ?? '';
      selectedGender.value = userData['gender'] ?? 'UNKNOWN';
      if (userData['birthday'] != null) {
        selectedBirthday.value = DateTime.tryParse(userData['birthday']);
      }
    }
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      _avatarBytes = await picked.readAsBytes();
      _avatarName = picked.name;
      avatarUrl.value = picked.path;
    }
  }

  Future<void> save() async {
    final nickname = nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      Get.snackbar('提示', '昵称不能为空');
      return;
    }

    isSaving.value = true;
    try {
      final data = <String, dynamic>{
        'nickname': nickname,
        'bio': bioCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'gender': selectedGender.value,
      };
      if (selectedBirthday.value != null) {
        final b = selectedBirthday.value!;
        data['birthday'] = '${b.year.toString().padLeft(4, '0')}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}';
      }
      if (_avatarBytes != null) {
        try {
          final url = await _uploadService.uploadImageBytes(_avatarBytes!, _avatarName ?? 'avatar.jpg');
          data['avatar'] = url;
        } catch (e) {
          Get.snackbar('Error', 'Avatar upload failed: $e');
        }
      }
      await _userRepo.updateMe(data);
      // Refresh home page user data
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshUser();
      }
      Get.back();
      Get.snackbar('成功', '资料已更新');
    } catch (e) {
      Get.snackbar('失败', e.toString());
    } finally {
      isSaving.value = false;
    }
  }
}
