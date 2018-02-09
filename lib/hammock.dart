library hammock;

import 'dart:developer';
import 'package:angular/angular.dart';
import 'dart:async';
import 'hammock_core.dart';
import 'package:hammock/compat/http.dart';
import 'package:http/http.dart';
export 'hammock_core.dart';

part 'src/resource_store.dart';
part 'src/config.dart';
part 'src/request_defaults.dart';
part 'src/custom_request_params.dart';
part 'src/object_store.dart';
part 'src/utils.dart';

class Hammock {

  static getProviders() {
    return [
      provide(HammockConfig),
      provide(ResourceStore),
      provide(ObjectStore),
    ];
  }
}