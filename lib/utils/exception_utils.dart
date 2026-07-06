import 'dart:convert';
import 'package:http/http.dart' as http;

/// Extracts a human-readable error message from an HTTP [response].
/// Inspects `message`, `error`, and `errors` keys; falls back to
/// [defaultMessage] when the body cannot be decoded.
String parseErrorMessage(
  http.Response response, {
  String defaultMessage = 'Request failed',
}) {
  try {
    final data = jsonDecode(response.body);
    if (data is Map) {
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      if (data.containsKey('errors')) {
        final errors = data['errors'];
        if (errors is Map) {
          return errors.values.map((e) {
            if (e is List) return e.join(', ');
            return e.toString();
          }).join('\n');
        }
        if (errors is List) return errors.join(', ');
        return errors.toString();
      }
    }
  } catch (_) {}
  return '$defaultMessage (${response.statusCode})';
}

/// Strips the leading `"Exception: "` prefix added by Dart's default
/// [Exception.toString], making messages safe to show directly in the UI.
String stripException(String message) =>
    message.replaceFirst('Exception: ', '');
