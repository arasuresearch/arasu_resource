part of arasu.resource;

class Store {
  String name, origin, path;
  Db db;
  Type type;
  Http http;
  bool _once = true;
  Future _opened;
  List _caches = new List();
  ClassMirror cm;

  Store(this.type, this.db, this.http, this.name, this.origin, this.path) {
    cm = reflectClass(type);
  }

  Future get opened {
    if (!db.dbase.objectStoreNames.contains(name)) {
      //Logger.root.info('$name store does not exists, so creating it');
      //Logger.root.info('$name store opened sucessfully ');
      db.dbase.close();
      _opened = window.indexedDB.open(db.dbase.name, version: db.dbase.version.hashCode + 1, onUpgradeNeeded: (VersionChangeEvent e) => ((e.target as Request).result as Database).createObjectStore(name, autoIncrement: true)).then((e) => db.dbase = e);
    } else {
      _opened = new Future.value();
    }
    return _opened;
  }
  dynamic New() {
    return cm.newInstance(new Symbol(''), [], {}).reflectee;
  }
  dynamic Get(var Id) {
    var obj = _caches.firstWhere((e) => e.attrs["Id"] == Id, orElse: () => null);
    if (obj == null) {
      obj = New();
      _caches.add(obj);
    }
    return obj;
  }

  void load() {
    var transaction = db.dbase.transaction(name, 'readwrite');
    var objectStore = transaction.objectStore(name);
    var cursors = objectStore.openCursor(autoAdvance: true).asBroadcastStream();
    cursors.listen((cursor) => syncData(Get(cursor.key), cursor.value));
    Logger.root.info("Load Completed...");
    //return new Future.value();
  }

  List get caches => _caches;

  void once() {
    if (_once) {
      load();
      fetch().then((_) => Logger.root.info("Fetch Completed..."));
      _once = false;
    }
  }

  Future fetch() {
    return http.get(path).then((HttpResponse response) {
      List data = response.data;
      if (data[1] == null) {
        if (data[0] != null && (data[0] as List).length > 0) {
          List records = data[0] as List;
          records.forEach((Map<String, dynamic> map) => syncData(Get(map["Id"]), map));
        } else {
          Logger.root.info("Empty Data Set Received");
        }
      } else {
        raiseIfNeeded(data[1]);
      }
    });
  }

  Future remove(dynamic obj) {
    return http.delete('$path/${obj.attrs["Id"]}').then((HttpResponse response) {
      List data = response.data;
      if (data[0] == null) {
        var transaction = db.dbase.transaction(name, 'readwrite');
        transaction.objectStore(name).delete(obj.attrs["Id"])
            ..then((_) => _caches.remove(obj))
            ..catchError(Logger.root.shout);
        return transaction.completed;
      } else {
        Logger.root.shout(JSON.decode(data[0]));
      }
    }).catchError(Logger.root.shout);
  }

  dynamic find(var Id) {
    var obj = _caches.firstWhere((e) => e.attrs["Id"] == Id, orElse: () => null);
    if (obj != null) {
      return obj;
    }
    obj = New();
    obj.Id = Id;
    var transaction = db.dbase.transaction(name, 'readwrite');
    transaction.objectStore(name).getObject(Id).then((map) {
      if (map != null && map.isNotEmpty) {
        _caches.add(obj);
        sync(obj.attrs, map, obj.metadata);
        obj.updateClone();
      } else {
        Logger.root.info("No Data load from store for $Id");
        throw("empty set");
        // http.get('$path/${Id}').then((HttpResponse response) {
        //   List data = response.data;
        //   if (data[1] == null) {
        //     Map map = data[0] as Map;
        //     if (map != null && map.isNotEmpty) {
        //       _caches.add(obj);
        //       syncData(obj, map);
        //     } else {
        //       Logger.root.info("No Data fetched from server for $Id");
        //     }
        //   } else {
        //     raiseIfNeeded(data[1]);
        //   }
        // }).catchError((e) => Logger.root.shout);


      }
    }).catchError((_) {
      http.get('$path/${Id}').then((HttpResponse response) {
        List data = response.data;
        if (data[1] == null) {
          Map map = data[0] as Map;
          if (map != null && map.isNotEmpty) {
            _caches.add(obj);
            syncData(obj, map);
          } else {
            Logger.root.info("No Data fetched from server for $Id");
          }
        } else {
          raiseIfNeeded(data[1]);
        }
      }).catchError((e) => Logger.root.shout);

    });
    return obj;

  }
  void raiseIfNeeded(var error) {
    if (error is Map) {
      Logger.root.shout("Server Response Error :$error ");
    } else {
      Logger.root.shout("Server Response Error :$error ");
    }

  }
  void UpToDate(var obj) {
    
    http.get('$path/${obj.Id}?UpdatedAt=${obj.UpdatedAt}').then((HttpResponse response) {
      List data = response.data;
      if (data[1] == null) {
        Map map = data[0] as Map;
        if (map != null && map.isNotEmpty) {
          if (obj == null) {
            _caches.add(obj);
          }
          syncData(obj, map);
        } else {
          Logger.root.info("No Data Received");
        }
      } else {
        raiseIfNeeded(data[1]);
      }
    }).catchError(Logger.root.shout);
  }

  dynamic findThroughFetch(var Id) {
    var obj = _caches.firstWhere((e) => e.attrs["Id"] == Id, orElse: () => null);
    http.get('$path/${Id}').then((HttpResponse response) {
      List data = response.data;
      if (data[1] == null) {
        Map map = data[0] as Map;
        if (map != null && map.isNotEmpty) {
          if (obj == null) {
            _caches.add(obj);
          }
          syncData(obj, map);
        } else {
          Logger.root.info("No Data Received");
        }
      } else {
        raiseIfNeeded(data[1]);
      }
    }).catchError(Logger.root.shout);
    return obj;
  }

  Future clear() {
    var transaction = db.dbase.transaction(name, 'readwrite');
    var objectStore = transaction.objectStore(name);
    objectStore.clear()
        ..then((_) => _caches.clear())
        ..catchError((e) => Logger.root.shout(e));
    return transaction.completed;
  }
  void updateDstore(Model model) {
    var transaction = db.dbase.transaction(name, 'readwrite');
    transaction.objectStore(name).put(Util.encodeForJSON(model.attrs), model.attrs["Id"])
        ..then((addedKey) {
          model.updateClone();
          //obj.Id = addedKey;
          //syncCache(obj);
        })
        ..catchError((e) => Logger.root.shout(e));
    return transaction.completed;
  }

  void syncData(Model model, Map json) {
    if (sync(model.attrs, json, model.metadata)) updateDstore(model);
  }
  Future add(Model model) {
    return http.post(path, model.encode()).then((HttpResponse response) {
      List data = response.data;
      if (data[1] == null) {
        Map map = data[0] as Map;
        if (map != null && map.isNotEmpty) {
          //model.attrs["Id"] = map["Id"];
          _caches.add(model);
          syncData(model, map);
        } else {
          Logger.root.info("No Data Received");
        }
      } else {
        raiseIfNeeded(data[1]);
        //TODO : add error into model object
      }
    }).catchError((e) => Logger.root.shout(e));
  }

  Future put(Model model) {
    //String data = JSON.encode(Util.encodeForJSON(attrs));
    return http.put('$path/${model.attrs["Id"]}', model.encode()).then((HttpResponse response) {
      List data = response.data;
      if (data[1] == null) {
        Map map = data[0] as Map;
        if (map != null && map.isNotEmpty) {
          syncData(model, map);
          updateDstore(model);
        } else {
          Logger.root.info("No Data Received");
        }
      } else {
        model.resetToClone();
        raiseIfNeeded(data[1]);
        //TODO : add error into model object
      }
    }).catchError((e) => Logger.root.shout(e));
  }

  bool sync(Map dst, Map src, Map metadata) {
    bool altered;
    if (metadata == null) metadata = {};
    src.keys.forEach((String k) {
      if (dst[k] == null) dst[k] = {};
      //if(dst[k] != src[k]){
      String type = src[k].runtimeType.toString();
      if (type.startsWith('_LinkedHashMap')) {
        if (sync(dst[k], src[k], metadata[k])) altered = true;
      } else {
        var value = src[k].toString();
        switch (metadata[k]) {
          case 'String':
            value = value;
            break;
          case 'int':

            value = int.parse(value, onError: (_) => 0);
            break;
          case 'bool':
            value = ['1', 'true', true, 1].contains(value);
            break;
          case 'DateTime':
            if (value.length > 24) value = value.substring(0, 24);
            value = DateTime.parse(value);
            break;
          case 'num':
            value = int.parse(value, onError: (_) => 0);
            break;
          default:
            value = src[k];
          //Logger.root.info("can't identify $k data type,so making it to incoming type");
        }
        if (dst[k] != value) {
          altered = true;
          dst[k] = value;
        } //end switch
      }//end if

    });
    return altered;
  }
}
