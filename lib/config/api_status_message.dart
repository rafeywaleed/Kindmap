import 'package:http/http.dart' as http;

const int success = 200;
const int created = 201;
const int deleted = 204;
const int badRequest = 400;
const int unauthorized = 401;
const int forbidden = 403;
const int notFound = 404;
const int conflict = 409;
const int internalServerError = 500;
const int serviceUnavailable = 503;

extension ApiStatus on http.Response {
  String get statusMessage => getApiStatusMessage(statusCode);
}

getApiStatusMessage(int statusCode) {
  switch (statusCode) {
    case success:
      return 'Success';
    case created:
      return 'Created';
    case deleted:
      return 'Deleted';
    case badRequest:
      return 'Bad Request';
    case unauthorized:
      return 'Unauthorized';
    case forbidden:
      return 'Forbidden';
    case notFound:
      return 'Not Found';
    case conflict:
      return 'Conflict';
    case internalServerError:
      return 'Internal Server Error';
    case serviceUnavailable:
      return 'Service Unavailable';
    default:
      return 'Unknown Status Code: $statusCode';
  }
}
