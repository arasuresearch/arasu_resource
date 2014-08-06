part of arasu.resource;
@Injectable()
class Db {
  Database dbase;
  String name = window.location.host;
  Map<Type, Store> stores = new Map<Type, Store>();
  Http http;
  Future _opened;
  Db({String name}) {
    this.name = (name != null && name.isNotEmpty) ? name : this.name;
  }
  Future delete() => window.indexedDB.deleteDatabase(name);
  Future get opened {
    //Logger.root.info('$name database opened sucessfully ');
    if (_opened == null) _opened = window.indexedDB.open(this.name).then((e) => dbase = e);
    return _opened;
  }
  Store get(Type type, {String name, String origin, String path}) {
    if (stores.containsKey(type)) return stores[type];
    name = (name != null && name.isNotEmpty) ? name : MirrorSystem.getName(reflectClass(type).simpleName);
    origin = (origin != null && origin.isNotEmpty) ? origin : window.location.origin;
    path = (path != null && path.isNotEmpty) ? path : (name.toLowerCase()+"s");
    stores[type] = new Store(type, this, http, name, origin, path);
    return stores[type];
  }
}
