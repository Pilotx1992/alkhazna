import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Simple client that injects static headers (e.g., Authorization) into requests
class HeadersClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  HeadersClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _headers.forEach((k, v) => request.headers[k] = v);
    if (kDebugMode) {
      final auth = request.headers['Authorization'];
      // Debug: show request URL and short auth header preview
      print('dYO? Making request to: ${request.url}');
      if (auth != null) {
        final preview = auth.length > 30 ? '${auth.substring(0, 30)}...' : auth;
        print('dY"` Auth header: $preview');
      }
    }
    return _inner.send(request);
  }
}

