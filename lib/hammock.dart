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

class Hammock {

  static getProviders() {
    return [
      //provide(HammockConfig),
      provide(HttpDefaultHeaders, useFactory: getHttpDefaultHeaders, deps: const []),
      provide(ResourceStore, useFactory: getResourceStore, deps: const [Client, HammockConfig, HttpDefaultHeaders]),
      provide(ObjectStore, useFactory: getObjectStore, deps: const [ResourceStore, HammockConfig]),
      provide(Client, useFactory: getBrowserClient),
    ];
  }

  static getBrowserClient() {
    return new BrowserClient()..withCredentials = true;
  }

  static getResourceStore(Client client, HammockConfig config, HttpDefaultHeaders h) {
    return new ResourceStore(client, config, h);
  }

  static getObjectStore(ResourceStore resourceStore, HammockConfig config) {
    return new ObjectStore(resourceStore, config);
  }

  static getHttpDefaultHeaders() {
    return new HttpDefaultHeaders();
  }
}