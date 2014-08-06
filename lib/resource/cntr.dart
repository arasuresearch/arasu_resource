part of arasu.resource;
class Cntr {
  Db db;
  Store store;
  Type type;
  Future ready;
  String Id;
  RouteProvider routeProvider;
  NgRoutingHelper locationService;
  Cntr(this.type, this.routeProvider, this.db, this.locationService) {
    Id = this.routeProvider.parameters['id'];
    store = db.get(type);
    ready = Future.forEach([db, store], (e) => e.opened);
  }
}
