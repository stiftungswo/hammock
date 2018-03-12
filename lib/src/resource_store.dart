part of hammock;

@Injectable()
class ResourceStore {
  final Client http;
  final HammockConfig config;
  final List<Resource> scopingResources;
  HttpDefaultHeaders defaultHeader;

  ResourceStore(this.http, this.config, this.defaultHeader)
      : scopingResources = [];

  ResourceStore.copy(ResourceStore original)
      : this.scopingResources = new List.from(original.scopingResources),
        this.http = original.http,
        this.config = original.config,
        this.defaultHeader = original.defaultHeader;

  ResourceStore scope(scopingResource) => new ResourceStore.copy(this)..scopingResources.add(scopingResource);


  Future<Resource> one(resourceType, resourceId) {
    final url = _url(resourceType, resourceId);
    return _invoke("GET", url).then(_parseResource(resourceType));
  }

  Future<QueryResult<Resource>> list(resourceType, {Map params}) {
    final url = _url(resourceType);
    return _invoke("GET", url, params: params).then(_parseManyResources((resourceType)));
  }

  Future<Resource> customQueryOne(resourceType, CustomRequestParams params) =>
      params.invoke(callHttp).then(_parseResource(resourceType));

  Future<QueryResult<Resource>> customQueryList(resourceType, CustomRequestParams params)  =>
      params.invoke(callHttp).then(_parseManyResources(resourceType));


  Future<CommandResponse> create(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type);
    final p = _parseCommandResponse(resource);
    return _invoke("POST", url, data: content).then(p, onError: _error(p));
  }

  Future<CommandResponse> update(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type, resource.id);
    final p = _parseCommandResponse(resource);
    return _invoke("PUT", url, data: content).then(p, onError: _error(p));
  }

  Future<CommandResponse> delete(Resource resource) {
    final url = _url(resource.type, resource.id);
    final p = _parseCommandResponse(resource);
    return _invoke("DELETE", url).then(p, onError: _error(p));
  }

  Future<CommandResponse> customCommand(Resource resource, CustomRequestParams params) {
    final p = _parseCommandResponse(resource);
    return params.invoke(this.callHttp).then(p, onError: _error(p));
  }

  _invoke(String method, String url, {String data, Map params}) {
    final d = config.requestDefaults;
    return callHttp(
        method: method,
        url: url,
        data: data,
        params: _paramsWithDefaults(params),
        headers: d.headers,
        withCredentials: d.withCredentials,
        xsrfCookieName: d.xsrfCookieName,
        xsrfHeaderName: d.xsrfHeaderName,
        interceptors: d.interceptors,
        cache: d.cache,
        timeout: d.timeout
    );
  }

  _paramsWithDefaults(Map rParams) {
    if (config.requestDefaults.params == null && rParams == null) return null;
    final params = config.requestDefaults.params == null ? {} : config.requestDefaults.params;
    if (rParams != null) rParams.forEach((key, value) => params[key] = value);
    return params;
  }

  _parseResource(resourceType) => (resp) => _docFormat.documentToResource(resourceType, resp.body);
  _parseManyResources(resourceType) => (resp) => _docFormat.documentToManyResources(resourceType, resp.body);
  _parseCommandResponse(res) => (resp) => _docFormat.documentToCommandResponse(res, resp.body);
  _error(Function func) => (resp) => new Future.error(func(resp));

  DocumentFormat get _docFormat => config.documentFormat;

  _url(type, [id=_u]) {
    final parentFragment = scopingResources.map((r) => "/${config.route(r.type)}/${r.id}").join("");
    final currentFragment = "/${config.route(type)}";
    final idFragment = (id != _u) ? "/$id" :  "";
    return config.urlRewriter("$parentFragment$currentFragment$idFragment");
  }

  Future<Response> callHttp({
    String url,
    String method,
    dynamic data,
    Map<String, dynamic> params = const {},
    Map<String, dynamic> headers = const {},
    bool withCredentials: false,
    String xsrfHeaderName,
    String xsrfCookieName,
    interceptors,
    cache,
    timeout
  }) async  {
    Uri uri = Uri.parse(url);

    params = (params ?? {});
    var paramKeys = params.keys.where((key) => params[key] != null);
    var paramValues = params.values.where((value) => value != null).map((value) => value.toString());
    params = new Map.fromIterables(paramKeys, paramValues);
    params.addAll(uri.queryParameters);

    Uri newUri = new Uri(scheme: uri.scheme, userInfo: uri.userInfo, host: uri.host,port: uri.port, path: uri.path, queryParameters: params,fragment: uri.fragment);


    Request req = new Request(method.toUpperCase(), newUri);
    req.headers.addAll(defaultHeader.map);
    if (headers != null) {
      req.headers.addAll(headers);
    }

    if (data != null) {
      req.headers['content-type'] = 'application/json';
      req.body = data;
    }

    var stream = await http.send(req);
    var response = await Response.fromStream(stream);

    if (stream.statusCode > 299) {
      throw response;
    } else {
      return response;
    }
  }
}
