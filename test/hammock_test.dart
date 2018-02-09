library hammock_test;

import 'angular_guinness.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'src/MockHttpBackend.dart';

part 'src/resource_store_test.dart';
part 'src/object_store_test.dart';
part 'src/config_test.dart';
part 'src/integration_test.dart';

main() {
  testConfig();
  testResourceStore();
  //testObjectStore();
  //testIntegration();
}

//EEEWWWW
microLeap(){
  //FIXME this used to be a mechanism that blocked until async tasts resolved
}

wait(future, [callback]) {
  callback = callback != null ? callback : (_) {};

  microLeap();
  //inject((MockHttpBackend http) => http.flush());
  //http.flush();

  future.then(callback);
}

waitForError(future, [callback]) {
  callback = callback != null ? callback : (_) {};

  microLeap();
  //inject((MockHttpBackend http) => http.flush());

  future.catchError(callback);
}