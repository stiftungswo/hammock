import 'dart:async';
import 'dart:convert';
import 'package:angel_route/angel_route.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;


text(String data, [int status = 200]) => new http.Response(data, status);
json(dynamic data, [int status = 200]) => text(JSON.encode(data), status);

class MockClient {

  Router router = new Router();

  http_testing.MockClient client;

  MockClient() {
    client = new http_testing.MockClient(this.handler);
  }

  Future<http.Response> handler(http.Request request) async {
    RoutingResult result = router.resolveAbsolute(request.url.path, method: request.method.toUpperCase()).first;

    var response = result.handlers.first(request, result);

    if (response is http.Response) {
      return response;
    }

    if (response is String) {
      return new http.Response(response, 200);
    }

    if (response is Map || response is List) {
      return new http.Response(JSON.encode(response), 200);
    }

    throw new Exception('Invalid return type of handler: ${response.runtimeType}');
  }

  clearRoutes() {
    this.router = new Router();
  }
}