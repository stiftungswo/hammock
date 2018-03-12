library hammock_test;

import 'dart:async';

import 'package:guinness/guinness.dart';
import 'package:hammock/hammock.dart';
import 'package:http/http.dart';

import 'MockClient.dart';

part 'src/config_test.dart';
part 'src/integration_test.dart';
part 'src/object_store_test.dart';
part 'src/resource_store_test.dart';

main() {
  testConfig();
  testResourceStore();
  testObjectStore();
  testIntegration();
}
