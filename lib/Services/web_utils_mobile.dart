import 'package:url_launcher/url_launcher.dart';
import 'web_utils.dart';

class WebUtilsMobile implements WebUtils {
  @override
  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

WebUtils getWebUtils() => WebUtilsMobile();
