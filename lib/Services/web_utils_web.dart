import 'dart:html' show window;
import 'web_utils.dart';

class WebUtilsImpl implements WebUtils {
  static void openUrl(String url) => window.open(url, '_blank');
}
