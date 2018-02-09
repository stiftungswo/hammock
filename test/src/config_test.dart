part of hammock_test;


HammockConfig hammockConfigFactory(Injector injector){
  return new HammockConfig(injector);
}

ObjectStore objectStoreFactory(ResourceStore res, HammockConfig config){
  return new ObjectStore(res, config);
}

ResourceStore resourceStoreFactory(MockHttpBackend hb, HammockConfig config){
  return new ResourceStore(hb, config);
}

_TestInjectable testInjectableFactory(ObjectStore store){
  return new _TestInjectable(store);
}

MockHttpBackend backendFactory(){
  return new MockHttpBackend();
}

testConfig() {
  Injector injector;
  HammockConfig c;
  beforeEach((){
    injector = new Injector.slowReflective([
      const Provider(HammockConfig, useFactory: hammockConfigFactory, deps: const [Injector]),
      const Provider(ObjectStore, useFactory: objectStoreFactory, deps: const [ResourceStore, HammockConfig]),
      const Provider(ResourceStore, useFactory: resourceStoreFactory, deps: const [MockHttpBackend, HammockConfig]),
      const Provider(_TestInjectable, useFactory: testInjectableFactory, deps: const [ObjectStore]),
      const Provider(MockHttpBackend, useFactory: httpBackendFactory),
    ]);
    c = injector.get(HammockConfig);
  });

  describe("HammockConfig", () {
    setUpAngular();

    it("returns a route for a resource type", () {
      c.set({"type" : {"route" : "aaa"}});

      expect(c.route("type")).toEqual("aaa");
    });

    it("defaults the route to the given resource type", () {
      expect(c.route("type")).toEqual("type");
    });

    it("returns a serializer for a resource type", () {
      c.set({"type" : {"serializer" : "serializer"}});

      expect(c.serializer("type")).toEqual("serializer");
    });

    it("throws when there is no serializer", () {
      expect(() => c.serializer("type")).toThrow();
    });

    it("returns a deserializer for a resource type", () {
      c.set({"type" : {"deserializer" : "deserializer"}});

      expect(c.deserializer("type", [])).toEqual("deserializer");
    });

    it("returns a deserializer for a resource type (nested)", () {
      c.set({"type" : {"deserializer" : {"query" : "deserializer"}}});

      expect(c.deserializer("type", ['query'])).toEqual("deserializer");
    });

    it("returns null when there is no deserializer", () {
      expect(c.deserializer("type", [])).toBeNull();
    });

    it("returns a resource type for an object type", () {
      c.set({"resourceType" : {"type" : "someType"}});

      expect(c.resourceType("someType")).toEqual("resourceType");
    });

    it("throws when no resource type is found", () {
      expect(() => c.resourceType("someType")).toThrowWith(message: "No resource type found");
    });

    describe("when given types", () {
      //registerBindings([_TestInjectable]);

      injector = new Injector.slowReflective([
        const Provider(HammockConfig, useFactory: hammockConfigFactory, deps: const [Injector]),
        const Provider(ObjectStore, useFactory: objectStoreFactory, deps: const [HammockConfig, ResourceStore]),
        const Provider(ResourceStore, useFactory: resourceStoreFactory, deps: const [HammockConfig]),
        const Provider(_TestInjectable, useFactory: testInjectableFactory, deps: const [ObjectStore])
      ]);
      c = injector.get(HammockConfig);

      it("uses Injector to instantiate serializers and deserializers", () {
        c.set({
            "type" : {
                "serializer" : _TestInjectable,
                "deserializer" : _TestInjectable
            }
        });

        expect(c.serializer("type")).toBeA(_TestInjectable);
        expect(c.deserializer("type")).toBeA(_TestInjectable);
      });
    });
  });
}

class _TestInjectable {
  ObjectStore store;
  _TestInjectable(this.store);
}