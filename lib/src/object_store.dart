part of hammock;

typedef CommandDeserializer(obj, CommandResponse resp);

@Injectable()
class ObjectStore {
  ResourceStore resourceStore;
  HammockConfig config;

  ObjectStore(this.resourceStore, this.config);

  ObjectStore scope(obj) =>
      new ObjectStore(resourceStore.scope(_wrapInResource(obj)), config);


  Future one(type, id)  =>
      _resourceQueryOne(type, (String rt) => resourceStore.one(rt, id));

  /// uses generic parameters to call [one] so you can write oneT<Entity>(id) and get a Future<Entity>
  /// instead of one(Entity, id) and get a Future<dynamic>
  Future<T> oneT<T>(id)  =>
      one(T, id);

  Future<List> list(type, {Map params}) =>
      _resourceQueryList(type, (String rt) => resourceStore.list(rt, params: params));

  /// uses generic parameters to call [list] so you can write listT<Entity>() and get a Future<List<Entity>>
  /// instead of list(Entity) and get a Future<List>
  Future<List<T>> listT<T>({Map params}) =>
      list(T, params: params);

  Future customQueryOne(type, CustomRequestParams params) =>
      _resourceQueryOne(type, (String rt) => resourceStore.customQueryOne(rt, params));

  /// uses generic parameters to call [customQueryOne] so you can write customQueryOneT<Entity>(params) and get a Future<Entity>
  /// instead of customQueryOne(Entity, params) and get a Future<dynamic>
  Future<T> customQueryOneT<T>(CustomRequestParams params) =>
      customQueryOne(T, params);

  Future<List> customQueryList(type, CustomRequestParams params) =>
      _resourceQueryList(type, (String rt) => resourceStore.customQueryList(rt, params));

  /// uses generic parameters to call [customQueryList] so you can write customQueryListT<Entity>(params) and get a Future<List<Entity>>
  /// instead of customQueryList(Entity, params) and get a Future<List>
  Future<List<T>> customQueryListT<T>(CustomRequestParams params) =>
      customQueryList(T, params);


  Future<T> create<T>(T object) =>
      _resourceStoreCommand(object, resourceStore.create);

  Future<T> update<T>(T object) =>
      _resourceStoreCommand(object, resourceStore.update);

  Future<T> delete<T>(T object) =>
      _resourceStoreCommand(object, resourceStore.delete);

  Future<T> customCommand<T>(T object, CustomRequestParams params) =>
      _resourceStoreCommand(object, (Resource res) => resourceStore.customCommand(res, params));


  _resourceQueryOne(type, Future<Resource> function(String type)) {
    final rt = config.resourceType(type);
    final deserialize = config.deserializer(rt, ['query']);
    return function(rt).then(deserialize);
  }

  _resourceQueryList(type, Future<QueryResult<Resource>> function(String type)) {
    final rt = config.resourceType(type);
    deserialize(QueryResult list) => _wrappedListIntoFuture(list.map(config.deserializer(rt, ['query'])));
    return function(rt).then(deserialize);
  }

  Future _resourceStoreCommand(object, Future<CommandResponse> function(Resource r)) {
    final res = _wrapInResource(object);
    final p = _parseSuccessCommandResponse(res, object);
    final ep = _parseErrorCommandResponse(res, object);
    return function(res).then(p, onError: ep);
  }

  Resource _wrapInResource(object) =>
      config.serializer(config.resourceType(object.runtimeType))(object);

  _parseSuccessCommandResponse(Resource res, object) =>
      _commandResponse(res, object, ['command', 'success']);

  _parseErrorCommandResponse(Resource res, object) =>
      (resp) => _wrappedIntoErrorFuture(_commandResponse(res, object, ['command', 'error'])(resp));

  _commandResponse(Resource res, object, path) {
    final d = config.deserializer(res.type, path);
    if (d == null) {
      return (resp) => resp;
    } else if (d is CommandDeserializer) {
      return (resp) => d(object, resp);
    } else {
      return (resp) => d(resource(res.type, res.id, (resp.content is Map) ? resp.content : null));
    }
  }

}