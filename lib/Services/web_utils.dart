abstract class WebUtils {
  Future<void> openUrl(String url);
  
  static WebUtils getInstance() {
    throw UnsupportedError('Platform implementation not found');
  }
}
