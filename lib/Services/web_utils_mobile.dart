import 'package:url_launcher/url_launcher.dart';
import 'web_utils.dart';

class WebUtilsImpl implements WebUtils {
  static Future<void> openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
