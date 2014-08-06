part of arasu.model;

abstract class RdbmsModel {
  bool isRdbms = true; 
  Map<String,dynamic> _base;
  
  Map<String,dynamic> get changes {
    Map<String,dynamic> attrs = encode();
    Map<String,dynamic> changed = new Map<String,dynamic>();
    attrs.keys.forEach((e){ 
      if(attrs[e] != _base[e]) changed[e]= attrs[e];
      });
    return changed;
  }  

  Map<String,dynamic> encode(){
    Map<String,dynamic> map = new Map<String,dynamic>();
    InstanceMirror im = reflect(this);
    Util.declarations(im.type).forEach((dm) {
      var key = MirrorSystem.getName(dm.simpleName);
      var val = im.getField(dm.simpleName).reflectee;
      if(val.runtimeType!=Null) map[key] = val;
    });
    return map;
  }
  
  String encodeWithAttr({String key: 'attr'}) => JSON.encode({key:encode()});

}
