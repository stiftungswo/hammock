library hammock_core;

import 'dart:convert';
import 'dart:collection';

class Resource {
  final String type;
  final Object id;
  final Map<String, dynamic> content;

  Resource(this.type, this.id, this.content);
}

Resource resource(String type, Object id, [Map<String, dynamic> content]) => new Resource(type, id, content);

class CommandResponse {
  final Resource resource;
  final content;
  CommandResponse(this.resource, this.content);
}

class QueryResult<T> extends Object with ListMixin<T>  {
  final List<T> list;
  final Map meta;

  QueryResult(this.list, [this.meta=const {}]);

  T operator[](index) => list[index];
  int get length => list.length;

  operator[]=(index,value) => list[index] = value;
  set length(value) => list.length = value;

  QueryResult<E> map<E>(E fn(T element)) => new QueryResult(list.map(fn).toList(), meta);

  QueryResult<T> toList({ bool growable: true }) => this;
}

abstract class DocumentFormat {
  String resourceToDocument(Resource res);
  Resource documentToResource(String resourceType, String document);
  QueryResult<Resource> documentToManyResources(String resourceType, String document);
  CommandResponse documentToCommandResponse(Resource res, String document);
}

abstract class JsonDocumentFormat implements DocumentFormat {
  Map<String, dynamic> resourceToJson(Resource resource);
  Resource jsonToResource(String resourceType, Map<String, dynamic> json);
  QueryResult<Resource> jsonToManyResources(String resourceType, json);

  final JsonEncoder _encoder = new JsonEncoder();
  final JsonDecoder _decoder = new JsonDecoder();

  String resourceToDocument(Resource res) =>
      _encoder.convert(resourceToJson(res));

  Resource documentToResource(String resourceType, String document) =>
      jsonToResource(resourceType, _toJSON(document));

  QueryResult<Resource> documentToManyResources(String resourceType, String document) =>
      jsonToManyResources(resourceType, _toJSON(document));

  CommandResponse documentToCommandResponse(Resource res, String document) =>
      new CommandResponse(res, _toJSON(document));

  _toJSON(document) {
    try {
      return (document is String) ? _decoder.convert(document) : document;
    } on FormatException catch(_) {
      return document;
    }
  }
}

class SimpleDocumentFormat extends JsonDocumentFormat {
  Map<String, dynamic> resourceToJson(Resource res) =>
      res.content;

  Resource jsonToResource(String type, Map<String, dynamic> json) =>
      resource(type, json["id"], json);

  QueryResult<Resource> jsonToManyResources(String type, json) {
    if(json is Map){
      json = json.values.toList();
    } 
    return new QueryResult(json.map((j) => jsonToResource(type, j)).toList());
  }
}
