part of hammock;

typedef CommandDeserializer(obj, CommandResponse resp);

@Injectable()
class ObjectStore {
  ResourceStore resourceStore;
  HammockConfig config;

  ObjectStore(this.resourceStore, this.config);

  ObjectStore scope(obj) =>
      new ObjectStore(resourceStore.scope(_wrapInResource(obj)), config);


  Future<T> one<T>(type, id)  =>
      _resourceQueryOne(type, (String rt) => resourceStore.one(rt, id));

  Future<List<T>> list<T>(type, {Map<String, dynamic> params}) =>
      _resourceQueryList<T>(type, (String rt) => resourceStore.list(rt, params: params));

  Future<T> customQueryOne<T>(type, CustomRequestParams params) =>
      _resourceQueryOne<T>(type, (String rt) => resourceStore.customQueryOne(rt, params));

  Future<List<T>> customQueryList<T>(type, CustomRequestParams params) =>
      _resourceQueryList(type, (String rt) => resourceStore.customQueryList(rt, params));

  Future<T> create<T>(T object) =>
      _resourceStoreCommand<T>(object, resourceStore.create);

  Future<T> update<T>(T object) =>
      _resourceStoreCommand<T>(object, resourceStore.update);

  Future<T> delete<T>(T object) =>
      _resourceStoreCommand<T>(object, resourceStore.delete);

  Future<T> customCommand<T>(T object, CustomRequestParams params) =>
      _resourceStoreCommand<T>(object, (Resource res) => resourceStore.customCommand(res, params));


  Future<T> _resourceQueryOne<T>(type, Future<Resource> function(String type)) {
    final rt = config.resourceType(type);
    final deserialize = config.deserializer(rt, ['query']);
    return function(rt).then(deserialize);
  }

  Future<List<T>> _resourceQueryList<T>(type, Future<QueryResult<Resource>> function(String type)) {
    final rt = config.resourceType(type);
    deserialize(QueryResult<Resource> list) => _wrappedListIntoFuture(list.map(config.deserializer(rt, ['query'])));
    return function(rt).then(deserialize).then((List<dynamic> list) => list.cast());
  }

  Future<T> _resourceStoreCommand<T>(object, Future<CommandResponse> function(Resource r)) async {
    final res = _wrapInResource(object);
    final p = _parseSuccessCommandResponse(res, object);
    final ep = _parseErrorCommandResponse(res, object);
    try {
      CommandResponse response = await function(res);
      return await p(response);
    } catch (err) {
      throw await ep(err);
    }
  }

  Resource _wrapInResource(object) =>
      config.serializer(config.resourceType(object.runtimeType))(object);

  _parseSuccessCommandResponse(Resource res, object) =>
      _commandResponse(res, object, ['command', 'success']);

  _parseErrorCommandResponse(Resource res, object) =>
      _commandResponse(res, object, ['command', 'error']);

  _commandResponse(Resource res, object, path) {
    final d = config.deserializer(res.type, path);
    if (d == null) {
      return (resp) => resp;
    } else if (d is CommandDeserializer) {
      return (resp) => d(object, resp);
    } else {
      return (resp) => d(resource(res.type, res.id, (resp is CommandResponse && resp.content is Map) ? resp.content : null));
    }
  }

}