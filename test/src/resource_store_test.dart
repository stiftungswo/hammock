part of hammock_test;

httpBackendFactory(){
  return new MockHttpBackend();
}

testResourceStore() {
  describe("ResourceStore", () {
    setUpAngular();

    ResourceStore store;
    MockHttpBackend hb;
    HammockConfig config;

    beforeEach((){
      var injector = new Injector.slowReflective([
        const Provider(HammockConfig, useFactory: hammockConfigFactory, deps: const [Injector]),
        const Provider(ObjectStore, useFactory: objectStoreFactory, deps: const [ResourceStore, HammockConfig]),
        const Provider(ResourceStore, useFactory: resourceStoreFactory, deps: const [MockHttpBackend, HammockConfig]),
        const Provider(MockHttpBackend, useFactory: httpBackendFactory),
      ]);
      store = injector.get(ResourceStore);
      hb = injector.get(MockHttpBackend);
      config = injector.get(HammockConfig);
    });

    describe("Queries", () {
      it("returns a resource", () {
        hb.whenGET("/posts/123").respond({"id": 123, "title" : "SampleTitle"});

        wait(store.one("posts", 123), (resource) {
          expect(resource.id).toEqual(123);
          expect(resource.content["title"]).toEqual("SampleTitleio"); //THIS SHOULD BREAK
        });
      });

      it("returns multiple resources", () {
        hb.whenGET("/posts").respond([{"id": 123, "title" : "SampleTitle"}]);

        wait(store.list("posts"), (resources) {
          expect(resources.length).toEqual(1);
          expect(resources[0].content["title"]).toEqual("SampleTitle");
        });
      });

      it("returns a nested resource", () {
        hb.whenGET("/posts/123/comments/456").respond({"id": 456, "text" : "SampleComment"});

        final post = resource("posts", 123);
        wait(store.scope(post).one("comments", 456), (resource) {
          expect(resource.id).toEqual(456);
          expect(resource.content["text"]).toEqual("SampleComment");
        });
      });

      it("handles errors", () {
        hb.whenGET("/posts/123").respond(500, "BOOM", {});

        waitForError(store.one("posts", 123), (resp) {
          expect(resp.data).toBe("BOOM");
        });
      });

      describe("default params", () {
        it("uses request defaults", () {
          config.requestDefaults.withCredentials = true;

          hb.when("GET", "/posts/123", null, null, true).respond(200, {"id" : 123});

          wait(store.one("posts", 123));
        });

        it("should merge params", () {
          config.requestDefaults.params = {"defaultParam" : "dvalue"};

          hb.when("GET", "/posts?defaultParam=dvalue&requestParam=rvalue").respond(200, []);

          wait(store.list("posts", params: {"requestParam" : "rvalue"}));
        });
      });

      describe("custom queries", () {
        it("returns one resource", () {
          hb.whenGET("/posts/123").respond({"id": 123, "title" : "SampleTitle"});

          wait(store.customQueryOne("posts", new CustomRequestParams(method: "GET", url:"/posts/123")), (resource) {
            expect(resource.content["title"]).toEqual("SampleTitle");
          });
        });

        it("returns many resource", () {
          hb.whenGET("/posts").respond([{"id": 123, "title" : "SampleTitle"}]);

          wait(store.customQueryList("posts", new CustomRequestParams(method: "GET", url: "/posts")), (resources) {
            expect(resources.length).toEqual(1);
            expect(resources[0].content["title"]).toEqual("SampleTitle");
          });
        });
      });
    });


    describe("Commands", () {
      it("create a resource", () {
        hb.expectPOST("/posts", '{"title":"New"}').respond({"id" : 123, "title" : "New"});

        final post = resource("posts", null, {"title": "New"});

        wait(store.create(post), (resp) {
          expect(resp.content["id"]).toEqual(123);
          expect(resp.content["title"]).toEqual("New");
        });
      });

      it("updates a resource", () {
        hb.expectPUT("/posts/123", '{"id":123,"title":"New"}').respond({"id": 123, "title": "Newer"});

        final post = resource("posts", 123, {"id": 123, "title": "New"});

        wait(store.update(post), (resp) {
          expect(resp.content["id"]).toEqual(123);
          expect(resp.content["title"]).toEqual("Newer");
        });
      });

      it("updates a nested resource", () {
        hb.expectPUT("/posts/123/comments/456", '{"id":456,"text":"New"}').respond({});

        final post = resource("posts", 123);
        final comment = resource("comments", 456, {"id": 456, "text" : "New"});

        wait(store.scope(post).update(comment));
      });

      it("deletes a resource", () {
        hb.expectDELETE("/posts/123").respond("OK");

        final post = resource("posts", 123);

        wait(store.delete(post), (resp) {
          expect(resp.content).toEqual("OK");
        });
      });

      it("handles errors", () {
        hb.expectDELETE("/posts/123").respond(500, "BOOM", {});

        final post = resource("posts", 123);

        waitForError(store.delete(post), (resp) {
          expect(resp.content).toEqual("BOOM");
        });
      });

      it("supports custom commands", () {
        hb.expectDELETE("/posts/123").respond("OK");

        final post = resource("posts", 123);

        wait(store.customCommand(post, new CustomRequestParams(method: 'DELETE', url: '/posts/123')), (resp) {
          expect(resp.content).toEqual("OK");
        });
      });
    });


    describe("Custom Configuration", () {
      it("uses route", () {
        config.set({
            "posts" : {"route": 'custom'}
        });

        hb.whenGET("/custom/123").respond({});

        wait(store.one("posts", 123));
      });

      it("uses urlRewriter", () {
        config.urlRewriter.baseUrl = "/base";
        config.urlRewriter.suffix = ".json";

        hb.whenGET("/base/posts/123.json").respond({});

        wait(store.one("posts", 123));

        config.urlRewriter = (url) => "$url.custom";

        hb.whenGET("/posts/123.custom").respond({});

        wait(store.one("posts", 123));
      });
    });
  });
}