// @dart=2.12
import 'dart:html' as html;
import 'web_utils.dart';

class WebUtilsWeb implements WebUtils {
  @override
  Future<void> openUrl(String url) async {
    html.window.open(url, '_blank');
  }
}

WebUtils getWebUtils() => WebUtilsWeb();
