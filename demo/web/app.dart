library hammock_demo_app;

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:hammock/hammock.dart';
import 'util/mirror_based_serializers.dart';
import 'dart:async';

//-----------------------
//--------MODELS---------
//-----------------------

// Any Dart object can be used as a model. No special interfaces or classes are required.
// For example, here Site and Post have no knowledge of Hammock or Angular.
class Site {
  int id;
  String name;
  List<Post> posts;
  Site(this.id, this.name, this.posts);

  remove(Post post) => posts.remove(post);
}

class Post {
  int id;
  String title;
  int views;
  Post(this.id, this.title, this.views);

  get popular => views > 100;
}

//-----------------------
//------COMPONENTS-------
//-----------------------
@Component(
  selector: 'post',
  templateUrl: 'partials/post.html',
  directives: const [CORE_DIRECTIVES],
)
class PostComponent {
  @Input("post")
  Post post;
  @Input("site")
  Site site;

  ObjectStore store;
  PostComponent(this.store);

  void delete() {
    // Hammock does not track associations, so we have to do it ourselves.
    siteStore.delete(post).then((_) => site.remove(post));
  }

  get siteStore => store.scope(site);
}

@Component(
  selector: 'site',
  templateUrl: 'partials/site.html',
  directives: const [PostComponent, CORE_DIRECTIVES, formDirectives],
)
class SiteComponent {
  @Input("site")
  Site site;

  ObjectStore store;
  SiteComponent(this.store);

  void update() {
    // This is an example of handling success and error cases differently.
    store.update(site).then((_) => print("success!"), onError: (errors) => print("errors $errors"));
  }
}

@Component(
  selector: 'app',
  templateUrl: 'partials/app.html',
  directives: const [SiteComponent, CORE_DIRECTIVES],
)
class App {
  List<Site> sites;

  App(ObjectStore store) {
    store.list(Site).then((sites) => this.sites = (sites as List<Site>));
  }
}

//-----------------------
//------SERIALIZERS------
//-----------------------

// A simple function can be used as a deserializer.
parseErrors(obj, CommandResponse resp) => resp.content["errors"];

// If it get tedious, we can always use some library removing the boilerplate.
final serializePost = serializer("posts", ["id", "title", "views"]);
final deserializePost = deserializer(Post, ["id", "title", "views"]);
final serializeSite = serializer("sites", ["id", "name"]);

// Some deserializers are quite complex and may require other injectables.
@Injectable()
class DeserializeSite {
  ObjectStore store;
  DeserializeSite(this.store);

  call(Resource r) {
    final site = new Site(r.id, r.content["name"], []);

    // Since a Deserializer can return a future,
    // you can load all the associations right here.
    return store.scope(site).list(Post).then((posts) {
      site.posts = (posts as List<Post>);
      return site;
    });
  }
}

createHammockConfig(Injector inj) {
  return new HammockConfig(inj)
    ..set({
      "posts": {
        "type": Post,
        "serializer": serializePost,
        "deserializer": {"query": deserializePost}
      },
      "sites": {
        "type": Site,
        "serializer": serializeSite,
        "deserializer": {
          "query": DeserializeSite, //When given a type, Hammock will use the Injector to get an instance of it.
          "command": {"success": null, "error": parseErrors}
        }
      }
    })
    ..urlRewriter.baseUrl = 'http://127.0.0.1:3001/api';
}

//-----------------------
//---------MAIN----------
//-----------------------
main() {
  List<dynamic> customProviders = [
    Hammock.getProviders(),
    provide(HammockConfig, useFactory: createHammockConfig, deps: const [Injector]),
    provide(SiteComponent),
    provide(PostComponent),
    provide(DeserializeSite),
  ];

  bootstrap(App, customProviders);
}
