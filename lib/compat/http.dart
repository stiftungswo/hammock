import 'dart:async';
import 'package:http/http.dart';

class HttpShim {
  BaseClient client;

  Future<Response> call({String method, String url, String data, params, Map<String, dynamic> headers, bool withCredentials, String xsrfCookieName, String xsrfHeaderName, interceptors, cache, timeout}) async{
      Request req = new Request(method, Uri.parse(url));
      return Response.fromStream(await client.send(req));
  }
}
