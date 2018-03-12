part of hammock_test;

testResourceStore() {
  group("ResourceStore", () {
    //setUpAngular();

    ResourceStore store;
    HammockConfig config;
    MockClient http;
    HttpDefaultHeaders defaultHeaders;

    setUp(() {
      http = new MockClient();
      config = new HammockConfig(null);
      defaultHeaders = new HttpDefaultHeaders();
      store = new ResourceStore(http.client, config, defaultHeaders);
    });

    group("Queries", () {
      test("returns a resource", () {
        http.router.get("/posts/123", (_,__) => {"id": 123, "title": "SampleTitle"});

        return store.one("posts", 123).then((resource) {
          expect(resource.id, equals(123));
          expect(resource.content["title"], equals("SampleTitle"));
        });
      });

      test("returns multiple resources", () {
        http.router.get("/posts", (_,__) => [{"id": 123, "title" : "SampleTitle"}]);

        return store.list("posts").then((resources) {
          expect(resources.length, equals(1));
          expect(resources[0].content["title"], equals("SampleTitle"));
        });
      });

      test("returns a nested resource", () {
        http.router.get("/posts/123/comments/456", (_,__) => {"id": 456, "text" : "SampleComment"});

        final post = resource("posts", 123);
        return store.scope(post).one("comments", 456).then((resource) {
          expect(resource.id, equals(456));
          expect(resource.content["text"], equals("SampleComment"));
        });
      });

      test("handles errors", () {
        http.router.get("/posts/123", (_,__) => text("BOOM", 500));

        return store.one("posts", 123).catchError((resp) {
          expect(resp.body, equals("BOOM"));
        });
      });

      group("default params", () {
        test("uses request defaults", () {
          config.requestDefaults.withCredentials = true;
          // todo with credentials?

          http.router.get("/posts/123", (_,__) => {"id" : 123});

          return store.one("posts", 123).then((resource) {
            expect(resource.id, equals(123));
          });
        });

        test("should merge params", () {
          config.requestDefaults.params = {"defaultParam" : "dvalue"};

          http.router.get("/posts", (Request request, _) {
            var params = request.url.queryParameters;
            return json([{"id": 1}..addAll(params)]);
          });

          return store.list("posts", params: {"requestParam" : "rvalue"}).then((resource) {
            expect(resource.length, equals(1));
            expect(resource[0].content['defaultParam'], equals('dvalue'));
            expect(resource[0].content['requestParam'], equals('rvalue'));
          });
        });
      });

      group("custom queries", () {
        test("returns one resource", () {
          http.router.get("/posts/123", (_,__) => {"id": 123, "title" : "SampleTitle"});

          return store.customQueryOne("posts", new CustomRequestParams(method: "GET", url:"/posts/123")).then((resource) {
            expect(resource.content["title"], equals("SampleTitle"));
          });
        });

        test("returns many resource", () {
          http.router.get("/posts", (_,__) => [{"id": 123, "title" : "SampleTitle"}]);

          return store.customQueryList("posts", new CustomRequestParams(method: "GET", url: "/posts")).then((resources) {
            expect(resources.length, equals(1));
            expect(resources[0].content["title"], equals("SampleTitle"));
          });
        });
      });
    });


    group("Commands", () {
      test("create a resource", () {
        var reqBody;
        http.router.post('/posts', (Request request,_) {
          reqBody = request.body;
          return json({"id" : 123, "title" : "New"});
        });

        final post = resource("posts", null, {"title": "New"});

        return store.create(post).then((resp) {
          expect(reqBody, equals('{"title":"New"}'));
          expect(resp.content["id"], equals(123));
          expect(resp.content["title"], equals("New"));
        });
      });

      test("updates a resource", () {
        var reqBody;
        http.router.put('/posts/123', (Request request,_) {
          reqBody = request.body;
          return json({"id": 123, "title": "Newer"});
        });

        final post = resource("posts", 123, {"id": 123, "title": "New"});

        return store.update(post).then((resp) {
          expect(reqBody, equals('{"id":123,"title":"New"}'));
          expect(resp.content["id"], equals(123));
          expect(resp.content["title"], equals("Newer"));
        });
      });

      test("updates a nested resource", () {
        var reqBody;
        http.router.put('/posts/123/comments/456', (Request request,_) {
          reqBody = request.body;
          return text('{}');
        });

        final post = resource("posts", 123);
        final comment = resource("comments", 456, {"id": 456, "text" : "New"});

        return store.scope(post).update(comment).then((response) {
          expect(reqBody, equals('{"id":456,"text":"New"}'));
        });
      });

      test("deletes a resource", () {
        http.router.delete("/posts/123", (_,__) => text('OK'));

        final post = resource("posts", 123);

        return store.delete(post).then((resp) {
          expect(resp.content, equals("OK"));
        });
      });

      test("handles errors", () {
        http.router.delete("/posts/123", (_,__) => text('BOOM', 500));

        final post = resource("posts", 123);

        return store.delete(post).catchError((resp) {
          expect(resp.content, equals("BOOM"));
        });
      });

      test("supports custom commands", () {
        http.router.delete("/posts/123", (_,__) => text('OK'));

        final post = resource("posts", 123);

        return store.customCommand(post, new CustomRequestParams(method: 'DELETE', url: '/posts/123')).then((resp) {
          expect(resp.content, equals("OK"));
        });
      });
    });


    group("Custom Configuration", () {
      test("uses route", () {
        config.set({
          "posts" : {"route": 'custom'}
        });

        http.router.get("/custom/123", (_,__) => text('{}'));

        return store.one("posts", 123).then((response) {
          expect(response.content, equals({}));
        });
      });

      test("uses urlRewriter", () async  {
        config.urlRewriter.baseUrl = "/base";
        config.urlRewriter.suffix = ".json";

        http.router.get("/base/posts/123.json", (_,__) => text('{}'));

        await store.one("posts", 123).then((response) {
          expect(response.content, equals({}));
        });

        config.urlRewriter = (url) => "$url.custom";

        http.clearRoutes();
        http.router.get("/posts/123.custom", (_,__) => text('{}'));

        return store.one("posts", 123).then((response) {
          expect(response.content, equals({}));
        });
      });
    });
  });
}