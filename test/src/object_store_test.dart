part of hammock_test;

testObjectStore() {
  group("ObjectStore", () {
    //setUpAngular();

    ObjectStore store;
    HammockConfig config;
    MockClient http;
    HttpDefaultHeaders defaultHeaders;

    setUp(() {
      http = new MockClient();
      config = new HammockConfig(null);
      defaultHeaders = new HttpDefaultHeaders();
      var resourceStore = new ResourceStore(http.client, config, defaultHeaders);
      store = new ObjectStore(resourceStore, config);
    });

    group("Queries", () {
      setUp(() {
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

      test("returns an object", () {
        http.router.get("/posts/123", (_,__) => {"title" : "SampleTitle"});

        return store.one(Post, 123).then((Post post) {
          expect(post.title, equals("SampleTitle"));
        });
      });

      test("returns multiple objects", () {
        http.router.get("/posts", (_,__) => [{"title" : "SampleTitle"}]);

        return store.list(Post).then((List<Post> posts) {
          expect(posts.length, equals(1));
          expect(posts[0].title, equals("SampleTitle"));
        });
      });

      test("returns a nested object", () {
        final post = new Post()..id = 123;
        http.router.get("/posts/123/comments/456", (_,__) => {"text" : "SampleComment"});

        return store.scope(post).one(Comment, 456).then((Comment comment) {
          expect(comment.text, equals("SampleComment"));
        });
      });

      test("handles errors", () {
        http.router.get("/posts/123", (_,__) => text('BOOM', 500));

        return store.one(Post, 123).catchError((resp) {
          expect(resp.body, equals("BOOM"));
        });
      });

      test("uses a separate deserializer for queries", () {

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
          expect(post.title, equals("SampleTitle"));
        });
      });

      test("supports deserializers that return Futures", () async  {

        config.set({
          "posts" : {
            "type" : Post,
            "deserializer" : (r) => new Future.value(deserializePost(r))
          }
        });

        http.router.get("/posts/123", (_,__) => {"title" : "SampleTitle"});

        await store.one(Post, 123).then((Post post) {
          expect(post.title, equals("SampleTitle"));
        });

        http.router.get("/posts", (_,__) => [{"title" : "SampleTitle"}]);

        return store.list(Post).then((List posts) {
          expect(posts.first.title, equals("SampleTitle"));
        });
      });

      test("support custom queries returning one object", () {
        http.router.get("/posts/123", (_,__) => {"id": 123, "title" : "SampleTitle"});

        return store.customQueryOne(Post, new CustomRequestParams(method: "GET", url:"/posts/123")).then((Post post) {
          expect(post.title, equals("SampleTitle"));
        });
      });

      test("support custom queries returning many object", () {
        http.router.get("/posts", (_,__) => [{"id": 123, "title" : "SampleTitle"}]);

        return store.customQueryList(Post, new CustomRequestParams(method: "GET", url: "/posts")).then((List posts) {
          expect(posts.length, equals(1));
          expect(posts[0].title, equals("SampleTitle"));
        });
      });
    });


    group("Commands", () {
      group("Without Deserializers", () {
        setUp(() {
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

        test("creates an object", () {
          var reqBody;
          http.router.post("/posts", (Request r,__) {
            reqBody = r.body;
            return {"id":123,"title":"New"};
          });

          final post = new Post()..title = "New";

          return store.create(post).then((response) {
            expect(reqBody, equals('{"id":null,"title":"New"}'));
            expect(response.content, equals({"id":123,"title":"New"}));
          });
        });

        test("updates an object", () {
          var reqBody;
          http.router.put("/posts/123", (Request r,__) {
            reqBody = r.body;
            return {};
          });

          final post = new Post()..id = 123..title = "New";


          return store.update(post).then((response) {
            expect(reqBody, equals('{"id":123,"title":"New"}'));
            expect(response.content, equals({}));
          });
        });

        test("deletes a object", () {
          http.router.delete("/posts/123", (_,__) => {});

          final post = new Post()..id = 123;

          return store.delete(post).then((response) {
            expect(response.content, equals({}));
          });
        });

        test("updates a nested object", () {
          var reqBody;
          http.router.put("/posts/123/comments/456", (Request r,__) {
            reqBody = r.body;
            return {};
          });

          final post = new Post()..id = 123;
          final comment = new Comment()..id = 456..text = "New";

          return store.scope(post).update(comment).then((response) {
            expect(reqBody, equals('{"id":456,"text":"New"}'));
            expect(response.content, equals({}));
          });
        });

        test("handles errors", () {
          var reqBody;
          http.router.post("/posts", (Request r,__) {
            reqBody = r.body;
            return text('BOOM', 500);
          });

          final post = new Post()..title = "New";

          return store.create(post).catchError((error) {
            expect(reqBody, equals('{"id":null,"title":"New"}'));
            expect(error.content, equals('BOOM'));
          });
        });

        test("supports custom commands", () {
          http.router.delete("/posts/123", (_,__) => 'OK');

          final post = new Post()..id = 123;

          return store.customCommand(post, new CustomRequestParams(method: 'DELETE', url: '/posts/123')).then((resp) {
            expect(resp.content, equals("OK"));
          });
        });
      });

      group("With Deserializers", () {
        var post;

        setUp(() {
          post = new Post()..id = 123..title = "New";
        });

        test("uses the same deserializer for queries and commands", () {

          config.set({
            "posts" : {
              "type" : Post,
              "serializer" : serializePost,
              "deserializer" : deserializePost
            }
          });

          http.router.put("/posts/123", (_,__) => {"id": 123, "title": "Newer"});

          return store.update(post).then((Post returnedPost) {
            expect(returnedPost.id, equals(123));
            expect(returnedPost.title, equals("Newer"));
          });
        });

        test("uses a separate serializer for commands", () {

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
            expect(returnedPost.title, equals("Newer"));
            expect(post.title, equals("Newer"));
          });
        });

        test("uses a separate serializer when a command fails", () {

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
            expect(resp, equals("BOOM"));
          });
        });

        test("supports deserializers that return Futures", () async {

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
            expect(returnedPost.title, equals("Newer"));
          });

          http.clearRoutes();
          http.router.put("/posts/123", (_,__) => text('BOOM', 500));

          return store.update(post).catchError((resp) {
            expect(resp, equals("BOOM"));
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

parseErrors(/*Post */post, CommandResponse resp) =>
    resp.content;

Resource serializePost(Post post) =>
    resource("posts", post.id, {"id" : post.id, "title" : post.title});

Comment deserializeComment(Resource r) => new Comment()
  ..id = r.id
  ..text = r.content["text"];

Resource serializeComment(Comment comment) =>
    resource("comments", comment.id, {"id" : comment.id, "text" : comment.text});

