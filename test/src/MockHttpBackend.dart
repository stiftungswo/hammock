import 'dart:async';
import 'dart:convert';
import 'package:angular/core.dart';
import 'package:hammock/compat/http.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

@Injectable()
class MockHttpBackend extends HttpShim{
  MockClient client;

  List<Definition> definitions = [];


  MockHttpBackend() {
    client = new MockClient(getResponse);
    super.client = client;
  }

  Future<Response> getResponse(Request request) async{
    var def = definitions.singleWhere((d){
      return d.url == request.url && d.method == request.method;
    });

    return new Response(def.body, 200);
  }

  _Chain when(String method, [String url, data, headers, withCredentials = false]) {
    var def = new Definition()
        ..method = method
        ..url = url;
    definitions.add(def);
    return new _Chain(def);
  }

  _Chain whenGET(String url){
    return when('GET', url);
  }

  _Chain expectPOST(url, data) {
    return when('POST', url, data);
  }

  _Chain expectPUT(url, data) {
    return when('PUT', url, data);
  }

  _Chain expectDELETE(url) {
    return when('DELETE', url);
  }

}

class _Chain{
  Definition definition;
  _Chain(this.definition);

  void respond([statusOrDataOrFunction, dataOrHeaders, headersOrNone]) {
    if (statusOrDataOrFunction is Function) return statusOrDataOrFunction;
    var status, data, headers;
    if (statusOrDataOrFunction is num) {
      status = statusOrDataOrFunction;
      data = dataOrHeaders;
      headers = headersOrNone;
    } else {
      status = 200;
      data = statusOrDataOrFunction;
      headers = dataOrHeaders;
    }
    if (data is Map || data is List) data = JSON.encode(data);

    definition
      ..status = status
      ..response = data.toString();

  }
}

class Definition{
  String url;
  String method;
  String response;
  int status = 200;
  bool called = false;
}
