part of hammock_test;

class IntegrationPost {
  int id;
  String title;
  String errors;
}

testIntegration() {
  //setUpAngular();

  ResourceStore resourceStore;
  ObjectStore objectStore;
  HammockConfig config;
  MockClient http;
  HttpDefaultHeaders defaultHeaders;

  setUp(() {
    http = new MockClient();
    config = new HammockConfig(null);
    defaultHeaders = new HttpDefaultHeaders();
    resourceStore = new ResourceStore(http.client, config, defaultHeaders);
    objectStore = new ObjectStore(resourceStore, config);
  });

  deserializePost(r) => new IntegrationPost()
    ..id = r.id
    ..title = r.content["title"]
    ..errors = r.content["errors"];

  serializePost(post) =>
      resource("posts", post.id, {"id" : post.id, "title" : post.title});



  group("Custom Document Formats", () {
    test("can support jsonapi.org format", () async {
      config.documentFormat = new JsonApiOrgFormat();

      http.router.get("/posts/123", (_,__) => {"posts" : [{"id" : 123, "title" : "title"}]});
      await resourceStore.one("posts", 123).then((post) {
        expect(post.content["title"], equals("title"));
      });

      http.router.put("/posts/123", (_,__) => {"posts":[{"id":123,"title":"new"}]});
      return resourceStore.update(resource("posts", 123, {"id" : 123, "title" : "new"})).then((response) {
        expect(response.content["posts"][0]["id"], equals(123));
      });
    });
  });

  group("Different Types of Responses", () {
    final post = new IntegrationPost()..id = 123..title = "new";

    test("works when when a server returns an updated resource", () async {

      config.set({
        "posts" : {
          "type" : IntegrationPost,
          "serializer" : serializePost,
          "deserializer" : deserializePost
        }
      });

      http.router.put("/posts/123", (_,__) => {"id" : 123, "title" : "updated"});


      await objectStore.update(post).then((up) {
        expect(up.title, equals("updated"));
      });

      http.clearRoutes();
      http.router.put("/posts/123", (_,__) => json({"id" : 123, "title" : "updated", "errors" : "some errors"}, 422));

      return objectStore.update(post).catchError((up) {
        expect(up.title, equals("updated"));
        expect(up.errors, equals("some errors"));
      });
    });

    test("works when a server returns a status", () async {

      config.set({
        "posts" : {
          "type" : IntegrationPost,
          "serializer" : serializePost,
          "deserializer" : {
            "command" : {
              "success" : (obj, r) => true,
              "error" : (obj, r) => r.content["errors"]
            }
          }
        }
      });


      http.router.put("/posts/123", (_,__) => "OK");

      await objectStore.update(post).then((res) {
        expect(res, isTrue);
      });

      http.clearRoutes();
      http.router.put("/posts/123", (_,__) => json({"errors" : "some errors"}, 422));

      return objectStore.update(post).catchError((errors) {
        expect(errors, equals("some errors"));
      });
    });
  });
}

class JsonApiOrgFormat extends JsonDocumentFormat {
  resourceToJson(Resource res) =>
      {res.type.toString(): [res.content]};

  Resource jsonToResource(type, json) =>
      resource(type, json[type][0]["id"], json[type][0]);

  QueryResult<Resource> jsonToManyResources(type, json) =>
      json[type].map((r) => resource(type, r["id"], r)).toList();
}