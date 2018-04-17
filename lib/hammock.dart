library hammock;

import 'package:angular/angular.dart';
import 'dart:async';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'hammock_core.dart';
export 'hammock_core.dart';

part 'src/resource_store.dart';
part 'src/config.dart';
part 'src/request_defaults.dart';
part 'src/custom_request_params.dart';
part 'src/object_store.dart';
part 'src/utils.dart';
part 'src/default_header.dart';

const hammockProviders = const [
  const Provider(HttpDefaultHeaders, useFactory: getHttpDefaultHeaders, deps: const []),
  const Provider(ResourceStore, useFactory: getResourceStore, deps: const [Client, HammockConfig, HttpDefaultHeaders]),
  const Provider(ObjectStore, useFactory: getObjectStore, deps: const [ResourceStore, HammockConfig]),
  const Provider(Client, useFactory: getBrowserClient)
];

BrowserClient getBrowserClient() {
  return new BrowserClient()..withCredentials = true;
}

ResourceStore getResourceStore(Client client, HammockConfig config, HttpDefaultHeaders h) {
  return new ResourceStore(client, config, h);
}

ObjectStore getObjectStore(ResourceStore resourceStore, HammockConfig config) {
  return new ObjectStore(resourceStore, config);
}

HttpDefaultHeaders getHttpDefaultHeaders() {
  return new HttpDefaultHeaders();
}

class Hammock {
  static getProviders() {
    return hammockProviders;
  }
}
