import 'package:get/get.dart';
import 'zh_cn.dart';
import 'en_us.dart';
import 'ja_jp.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': zhCN,
        'en_US': enUS,
        'ja_JP': jaJP,
      };
}
