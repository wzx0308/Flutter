import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'edit_profile_controller.dart';

class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final hintColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('edit_profile'.tr),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => TextButton(
                onPressed: controller.isSaving.value ? null : controller.save,
                child: controller.isSaving.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('confirm_ok'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              )),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 32.h, bottom: 32.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor, accentColor.withOpacity(0.7)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final avatar = controller.avatarUrl.value;
                    return GestureDetector(
                      onTap: controller.pickAvatar,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 46.r,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                              child: avatar.isEmpty
                                  ? Icon(Icons.person, size: 46.r, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Icon(Icons.camera_alt, size: 16, color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                  Text('tap_change_avatar'.tr, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField('nickname'.tr, controller.nicknameCtrl, Icons.person_outline, textColor: textColor, hintColor: hintColor, accentColor: accentColor, maxLength: 20),
                      _buildDivider(dividerColor),
                      _buildTextField('bio_hint'.tr, controller.bioCtrl, Icons.edit_outlined, textColor: textColor, hintColor: hintColor, accentColor: accentColor, maxLines: 3, maxLength: 100),
                      _buildDivider(dividerColor),
                      _buildGenderSelector(textColor: textColor, accentColor: accentColor, isDark: isDark),
                      _buildDivider(dividerColor),
                      _buildBirthdayPicker(context, textColor: textColor, accentColor: accentColor),
                      _buildDivider(dividerColor),
                      _buildTextField('location_hint'.tr, controller.locationCtrl, Icons.location_on_outlined, textColor: textColor, hintColor: hintColor, accentColor: accentColor, maxLength: 30),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(Color dividerColor) {
    return Divider(height: 1, indent: 54, color: dividerColor);
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {
    required Color textColor, required Color hintColor, required Color accentColor,
    int maxLines = 1, int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: maxLines,
              maxLength: maxLength,
              style: TextStyle(fontSize: 15, color: textColor),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(color: hintColor),
                labelText: label,
                labelStyle: TextStyle(color: hintColor, fontSize: 13),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector({required Color textColor, required Color accentColor, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.wc_outlined, color: accentColor, size: 20),
          const SizedBox(width: 14),
          Text('gender'.tr, style: TextStyle(fontSize: 15, color: textColor)),
          const Spacer(),
          Obx(() => Row(
                children: [
                  _genderChip('male'.tr, 'MALE', accentColor: accentColor, isDark: isDark),
                  const SizedBox(width: 8),
                  _genderChip('female'.tr, 'FEMALE', accentColor: accentColor, isDark: isDark),
                  const SizedBox(width: 8),
                  _genderChip('unknown_gender'.tr, 'UNKNOWN', accentColor: accentColor, isDark: isDark),
                ],
              )),
        ],
      ),
    );
  }

  Widget _genderChip(String label, String value, {required Color accentColor, required bool isDark}) {
    final selected = controller.selectedGender.value == value;
    return GestureDetector(
      onTap: () => controller.selectedGender.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accentColor : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accentColor : (isDark ? Colors.grey[700]! : Colors.grey[200]!)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]!),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdayPicker(BuildContext context, {required Color textColor, required Color accentColor}) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: controller.selectedBirthday.value ?? DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: accentColor),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          controller.selectedBirthday.value = date;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, color: accentColor, size: 20),
            const SizedBox(width: 14),
            Text('birthday'.tr, style: TextStyle(fontSize: 15, color: textColor)),
            const Spacer(),
            Obx(() => Text(
                  controller.selectedBirthday.value != null
                      ? '${controller.selectedBirthday.value!.year}-${controller.selectedBirthday.value!.month.toString().padLeft(2, '0')}-${controller.selectedBirthday.value!.day.toString().padLeft(2, '0')}'
                      : 'not_set'.tr,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                )),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }
}
