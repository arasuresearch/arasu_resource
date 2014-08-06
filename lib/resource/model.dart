part of arasu.resource;

class Model<K, V> extends MapBase<K, V> {
  Map clone = new Map();
  Map attrs = new Map();
  Map changes = new Map();
  int get length => attrs.length;
  void operator []=(var k, var v) => attrs[k] = v;
  operator [](var k) => attrs[k];
  List get keys => attrs.keys;
  V remove(var k) => attrs.remove(k);
  void clear() => attrs.clear();
  Map<String, dynamic> metadata = new Map<String, dynamic>();


  Model({Map map}) {
    if (map != null) this.addAll(map);
  }
  void updateClone() {
    clone = Util.clone(attrs);
    changes.clear();
  }
  void resetToClone() {
    attrs = Util.clone(clone);
    changes.clear();
  }

  noSuchMethod(Invocation invo) {
    String key = MirrorSystem.getName(invo.memberName);
    List args = invo.positionalArguments;
    if (args.isEmpty && invo.isGetter) {
      return this[key] = new Model();
    } else if (args.length == 1 && invo.isSetter) {
      return this[key.substring(0, key.length - 1)] = args[0];
    }
    super.noSuchMethod(invo);
  }
  String encode() => JSON.encode({
    "attr": Util.encodeForJSON(changes)
  });

  bool get hasChanged {
    changes = Util.changes(attrs, clone, metadata);
    return changes.isNotEmpty;
  }

}
