part of hammock_test;

testObjectStore() {
  describe("ObjectStore", () {
    //setUpAngular();

    ObjectStore store;
    HammockConfig config;
    MockClient http;
    HttpDefaultHeaders defaultHeaders;

    beforeEach(() {
      http = new MockClient();
      config = new HammockConfig(null);
      defaultHeaders = new HttpDefaultHeaders();
      var resourceStore = new ResourceStore(http.client, config, defaultHeaders);
      store = new ObjectStore(resourceStore, config);
    });

    describe("Queries", () {
      beforeEach(() {
        config.set({
            "posts" : {
                "type" : Post,
                "serializer" : serializePost,
                "deserializer" : deserializePost
            },
            "comments" : {
                "type": Comment,
                "deserializer" : deserializeComment
            }
        });
      });

      it("returns an object", () {
        http.router.get("/posts/123", (_,__) => {"title" : "SampleTitle"});

        return store.one(Post, 123).then((Post post) {
          expect(post.title).toEqual("SampleTitle");
        });
      });

      it("returns multiple objects", () {
        http.router.get("/posts", (_,__) => [{"title" : "SampleTitle"}]);

        return store.list(Post).then((List<Post> posts) {
          expect(posts.length).toEqual(1);
          expect(posts[0].title).toEqual("SampleTitle");
        });
      });

      it("returns a nested object", () {
        final post = new Post()..id = 123;
        http.router.get("/posts/123/comments/456", (_,__) => {"text" : "SampleComment"});

        return store.scope(post).one(Comment, 456).then((Comment comment) {
          expect(comment.text).toEqual("SampleComment");
        });
      });

      it("handles errors", () {
        http.router.get("/posts/123", (_,__) => text('BOOM', 500));

        return store.one(Post, 123).catchError((resp) {
          expect(resp.body).toEqual("BOOM");
        });
      });

      it("uses a separate deserializer for queries", () {

        config.set({
            "posts" : {
              "type" : Post,
              "deserializer" : {
                "query" : deserializePost
              }
            }
        });

        http.router.get("/posts/123", (_,__) => {"title" : "SampleTitle"});

        return store.one(Post, 123).then((Post post) {
          expect(post.title).toEqual("SampleTitle");
        });
      });

      it("supports deserializers that return Futures", () async  {

        config.set({
            "posts" : {
              "type" : Post,
              "deserializer" : (r) => new Future.value(deserializePost(r))
            }
        });

        http.router.get("/posts/123", (_,__) => {"title" : "SampleTitle"});

        await store.one(Post, 123).then((Post post) {
          expect(post.title).toEqual("SampleTitle");
        });

        http.router.get("/posts", (_,__) => [{"title" : "SampleTitle"}]);

        return store.list(Post).then((List posts) {
          expect(posts.first.title).toEqual("SampleTitle");
        });
      });

      it("support custom queries returning one object", () {
        http.router.get("/posts/123", (_,__) => {"id": 123, "title" : "SampleTitle"});

        return store.customQueryOne(Post, new CustomRequestParams(method: "GET", url:"/posts/123")).then((Post post) {
          expect(post.title).toEqual("SampleTitle");
        });
      });

      it("support custom queries returning many object", () {
        http.router.get("/posts", (_,__) => [{"id": 123, "title" : "SampleTitle"}]);

        return store.customQueryList(Post, new CustomRequestParams(method: "GET", url: "/posts")).then((List posts) {
          expect(posts.length).toEqual(1);
          expect(posts[0].title).toEqual("SampleTitle");
        });
      });
    });


    describe("Commands", () {
      describe("Without Deserializers", () {
        beforeEach(() {
          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost
              },
              "comments" : {
                  "type" : Comment,
                  "serializer" : serializeComment
              }
          });
        });

        it("creates an object", () {
          var reqBody;
          http.router.post("/posts", (Request r,__) {
            reqBody = r.body;
            return {"id":123,"title":"New"};
          });

          final post = new Post()..title = "New";

          return store.create(post).then((response) {
            expect(reqBody).toEqual('{"id":null,"title":"New"}');
            expect(response.content).toEqual({"id":123,"title":"New"});
          });
        });

        it("updates an object", () {
          var reqBody;
          http.router.put("/posts/123", (Request r,__) {
            reqBody = r.body;
            return {};
          });

          final post = new Post()..id = 123..title = "New";


          return store.update(post).then((response) {
            expect(reqBody).toEqual('{"id":123,"title":"New"}');
            expect(response.content).toEqual({});
          });
        });

        it("deletes a object", () {
          http.router.delete("/posts/123", (_,__) => {});

          final post = new Post()..id = 123;

          return store.delete(post).then((response) {
            expect(response.content).toEqual({});
          });
        });

        it("updates a nested object", () {
          var reqBody;
          http.router.put("/posts/123/comments/456", (Request r,__) {
            reqBody = r.body;
            return {};
          });

          final post = new Post()..id = 123;
          final comment = new Comment()..id = 456..text = "New";

          return store.scope(post).update(comment).then((response) {
            expect(reqBody).toEqual('{"id":456,"text":"New"}');
            expect(response.content).toEqual({});
          });
        });

        it("handles errors", () {
          var reqBody;
          http.router.post("/posts", (Request r,__) {
            reqBody = r.body;
            return text('BOOM', 500);
          });

          final post = new Post()..title = "New";

          return store.create(post).catchError((error) {
            expect(reqBody).toEqual('{"id":null,"title":"New"}');
            expect(error.content).toEqual('BOOM');
          });
        });

        it("supports custom commands", () {
          http.router.delete("/posts/123", (_,__) => 'OK');

          final post = new Post()..id = 123;

          return store.customCommand(post, new CustomRequestParams(method: 'DELETE', url: '/posts/123')).then((resp) {
            expect(resp.content).toEqual("OK");
          });
        });
      });

      describe("With Deserializers", () {
        var post;

        beforeEach(() {
          post = new Post()..id = 123..title = "New";
        });

        it("uses the same deserializer for queries and commands", () {

          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost,
                  "deserializer" : deserializePost
              }
          });

          http.router.put("/posts/123", (_,__) => {"id": 123, "title": "Newer"});

          return store.update(post).then((Post returnedPost) {
            expect(returnedPost.id).toEqual(123);
            expect(returnedPost.title).toEqual("Newer");
          });
        });

        it("uses a separate serializer for commands", () {

          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost,
                  "deserializer" : {
                    "command" : updatePost
                  }
              }
          });


          http.router.put("/posts/123", (_,__) => {"title": "Newer"});

          return store.update(post).then((Post returnedPost) {
            expect(returnedPost.title).toEqual("Newer");
            expect(post.title).toEqual("Newer");
          });
        });

        it("uses a separate serializer when a command fails", () {

          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost,
                  "deserializer" : {
                    "command" : {
                      "success" : deserializePost,
                      "error" : parseErrors
                    }
                  }
              }
          });

          http.router.put("/posts/123", (_,__) => text('BOOM', 500));

          return store.update(post).catchError((resp) {
            expect(resp).toEqual("BOOM");
          });
        });

        it("supports deserializers that return Futures", () async {

          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost,
                  "deserializer" : {
                    "command" : {
                      "success" : (r) => new Future.value(deserializePost(r)),
                      "error" : (p,r) => new Future.value(parseErrors(p,r))
                    }
                  }
              }
          });

          http.router.put("/posts/123", (_,__) => {"title": "Newer"});

          await store.update(post).then((Post returnedPost) {
            expect(returnedPost.title).toEqual("Newer");
          });

          http.clearRoutes();
          http.router.put("/posts/123", (_,__) => text('BOOM', 500));

          return store.update(post).catchError((resp) {
            expect(resp).toEqual("BOOM");
          });
        });
      });
    });
  });
}

class Post {
  int id;
  String title;
}

class Comment {
  int id;
  String text;
}

Post deserializePost(Resource r) => new Post()
  ..id = r.id
  ..title = r.content["title"];

Post updatePost(Post post, CommandResponse resp) {
  post.title = resp.content["title"];
  return post;
}

parseErrors(Post post, CommandResponse resp) =>
    resp.content;

Resource serializePost(Post post) =>
    resource("posts", post.id, {"id" : post.id, "title" : post.title});

Comment deserializeComment(Resource r) => new Comment()
  ..id = r.id
  ..text = r.content["text"];

Resource serializeComment(Comment comment) =>
    resource("comments", comment.id, {"id" : comment.id, "text" : comment.text});

