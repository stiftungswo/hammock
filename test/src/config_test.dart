part of hammock_test;

testConfig() {
  group("HammockConfig", () {
    //setUpAngular();

    HammockConfig c;

    setUp(() {
      c = new HammockConfig(null);
    });

    test("returns a route for a resource type", () {
      c.set({"type" : {"route" : "aaa"}});

      expect(c.route("type"), equals("aaa"));
    });

    test("defaults the route to the given resource type", () {
      expect(c.route("type"), equals("type"));
    });

    test("returns a serializer for a resource type", () {
      c.set({"type" : {"serializer" : "serializer"}});

      expect(c.serializer("type"), equals("serializer"));
    });

    test("throws when there is no serializer", () {
      expect(() => c.serializer("type"), throws);
    });

    test("returns a deserializer for a resource type", () {
      c.set({"type" : {"deserializer" : "deserializer"}});

      expect(c.deserializer("type", []), equals("deserializer"));
    });

    test("returns a deserializer for a resource type (nested)", () {
      c.set({"type" : {"deserializer" : {"query" : "deserializer"}}});

      expect(c.deserializer("type", ['query']), equals("deserializer"));
    });

    test("returns null when there is no deserializer", () {
      expect(c.deserializer("type", []), isNull);
    });

    test("returns a resource type for an object type", () {
      c.set({"resourceType" : {"type" : "someType"}});

      expect(c.resourceType("someType"), equals("resourceType"));
    });

    test("throws when no resource type is found", () {
      expect(() => c.resourceType("someType"), throwsA(contains("No resource type found")));
    });

    /*
    todo: disabled because tests run without angular injector (youd need to find out how to use injector standalone with angular > 1)
    group("when given types", () {
      registerBindings([_TestInjectable]);

      test("uses Injector to instantiate serializers and deserializers", () {
        c.set({
            "type" : {
                "serializer" : _TestInjectable,
                "deserializer" : _TestInjectable
            }
        });

        expect(c.serializer("type")).toBeA(_TestInjectable);
        expect(c.deserializer("type")).toBeA(_TestInjectable);
      });
    });*/
  });
}

class _TestInjectable {
  ObjectStore store;
  _TestInjectable(this.store);
}