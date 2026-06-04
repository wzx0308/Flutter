import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'create_post_controller.dart';
import '../../app/theme/app_colors.dart';

class CreatePostPage extends GetView<CreatePostController> {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('publish_post'.tr),
        actions: [
          Obx(() => TextButton(
                onPressed: controller.isSubmitting.value ? null : controller.submit,
                child: controller.isSubmitting.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('post'.tr, style: TextStyle(color: Get.isDarkMode ? const Color(0xFF8B7FD4) : AppColors.primary, fontWeight: FontWeight.bold)),
              )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(cardColor, textColor),
            const SizedBox(height: 16),
            Obx(() => controller.selectedType.value == 'ARTICLE'
                ? Column(
                    children: [
                      TextField(
                        controller: controller.titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'article_title'.tr,
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 20, color: subTextColor),
                        ),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox.shrink()),
            TextField(
              controller: controller.contentCtrl,
              maxLines: null,
              minLines: 6,
              decoration: InputDecoration(
                hintText: 'share_thoughts'.tr,
                border: InputBorder.none,
                hintStyle: TextStyle(color: subTextColor),
              ),
              style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
            ),
            const SizedBox(height: 16),
            _buildTagSection(cardColor, textColor, subTextColor, accentColor),
            const SizedBox(height: 16),
            _buildLocationPicker(cardColor, textColor, subTextColor),
            const SizedBox(height: 16),
            _buildImagePicker(cardColor, subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(Color cardColor, Color textColor) {
    return Obx(() => Row(
          children: [
            _typeChip('post_type_image'.tr, 'POST', Icons.image, cardColor, textColor),
            const SizedBox(width: 12),
            _typeChip('post_type_article'.tr, 'ARTICLE', Icons.article, cardColor, textColor),
          ],
        ));
  }

  Widget _typeChip(String label, String type, IconData icon, Color cardColor, Color textColor) {
    final selected = controller.selectedType.value == type;
    return GestureDetector(
      onTap: () => controller.selectedType.value = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPicker(Color cardColor, Color textColor, Color? subTextColor) {
    return Obx(() {
      final name = controller.locationName.value;
      return GestureDetector(
        onTap: () => _showLocationInput(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Get.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: name.isNotEmpty ? AppColors.primary : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isNotEmpty ? name : 'add_location_optional'.tr,
                  style: TextStyle(color: name.isNotEmpty ? textColor : subTextColor, fontSize: 14),
                ),
              ),
              if (name.isNotEmpty)
                GestureDetector(
                  onTap: () => controller.setLocation('', null, null),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _showLocationInput() {
    final isDark = Get.isDarkMode;
    final ctrl = TextEditingController(text: controller.locationCtrl.text);
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(Get.context!).viewInsets.bottom + 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('add_location'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121))),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF212121)),
              decoration: InputDecoration(
                hintText: 'enter_location'.tr,
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      controller.setLocation('current_location'.tr, 39.9042, 116.4074);
                      Get.back();
                    },
                    icon: const Icon(Icons.my_location),
                    label: Text('use_current_location'.tr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    controller.setLocation(ctrl.text.trim(), null, null);
                  }
                  Get.back();
                },
                child: Text('confirm_ok'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection(Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing tags
        Obx(() {
          if (controller.tags.isEmpty) return const SizedBox.shrink();
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.tags.map((tag) => Chip(
              label: Text('#$tag', style: TextStyle(color: accentColor, fontSize: 13)),
              deleteIcon: Icon(Icons.close, size: 16, color: accentColor),
              onDeleted: () => controller.removeTag(tag),
              backgroundColor: accentColor.withOpacity(0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          );
        }),
        // Tag picker
        Obx(() {
          if (!controller.showTagPicker.value) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag, size: 18, color: accentColor),
                    const SizedBox(width: 6),
                    Text('添加标签'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 14)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => controller.showTagPicker.value = false,
                      child: Icon(Icons.close, size: 18, color: subTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Custom tag input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.tagInputCtrl,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '自定义标签'.tr,
                          hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (controller.tagInputCtrl.text.trim().isNotEmpty) {
                          controller.addTag(controller.tagInputCtrl.text.trim());
                          controller.tagInputCtrl.clear();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('添加'.tr, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Hot tags
                Text('热门标签'.tr, style: TextStyle(fontSize: 12, color: subTextColor)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CreatePostController.hotTags.map((tag) {
                    final isSelected = controller.tags.contains(tag);
                    return GestureDetector(
                      onTap: isSelected ? null : () => controller.addTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? accentColor : Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? accentColor : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        // Add tag button (when no picker shown)
        Obx(() {
          if (controller.showTagPicker.value || controller.tags.length >= 5) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => controller.showTagPicker.value = true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: subTextColor),
                  const SizedBox(width: 4),
                  Text('添加标签'.tr, style: TextStyle(color: subTextColor, fontSize: 13)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImagePicker(Color cardColor, Color? subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          if (controller.pickedImages.isEmpty) {
            return GestureDetector(
              onTap: controller.pickImages,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[400]),
                    const SizedBox(height: 4),
                    Text('image_label'.tr, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(controller.pickedImages.length, (i) {
              return SizedBox(
                width: 80.w,
                height: 80.w,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Get.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.memory(
                            controller.pickedImages[i],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => controller.removeImage(i),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        }),
        // Add more images button
        Obx(() {
          if (controller.pickedImages.isEmpty || controller.pickedImages.length >= 9) return const SizedBox.shrink();
          return GestureDetector(
            onTap: controller.pickImages,
            child: Container(
              width: 80.w,
              height: 80.w,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Get.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text('${controller.pickedImages.length}/9', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
