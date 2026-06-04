import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/models/channel_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import 'channel_card.dart';

class ChannelGrid extends StatefulWidget {
  const ChannelGrid({super.key});

  @override
  State<ChannelGrid> createState() => _ChannelGridState();
}

class _ChannelGridState extends State<ChannelGrid> {
  final Map<String, String> _coverImages = {};
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadCoverImages();
  }

  Future<void> _loadCoverImages() async {
    for (final channel in ChannelModel.officialChannels) {
      try {
        final res = await _api.dio.get('/posts', queryParameters: {
          'tag': channel.tag,
          'page': 1,
          'pageSize': 1,
        });
        if (res.data['code'] == 0) {
          final list = res.data['data'];
          if (list is List && list.isNotEmpty) {
            final post = list[0];
            final images = post['images'];
            if (images is List && images.isNotEmpty) {
              setState(() {
                _coverImages[channel.tag] = images[0];
              });
            } else if (post['coverImage'] != null) {
              setState(() {
                _coverImages[channel.tag] = post['coverImage'];
              });
            }
          }
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                children: [
                  Text(
                    'community'.tr,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF212121),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.search),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                mainAxisSpacing: 12.w,
                crossAxisSpacing: 12.w,
                childAspectRatio: 1.3,
              ),
              itemCount: ChannelModel.officialChannels.length,
              itemBuilder: (_, i) {
                final channel = ChannelModel.officialChannels[i];
                return ChannelCard(
                  channel: channel,
                  coverImage: _coverImages[channel.tag],
                  onTap: () => Get.toNamed(
                    '${AppRoutes.channel}/${Uri.encodeComponent(channel.tag)}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
