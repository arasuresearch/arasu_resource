part of arasu.model;
abstract class BigdataModel {
  bool isRdbms = false; 

  Map<String,Map<String,String>> _metadata = new Map<String,Map<String,String>>();
  Map<String,String> metadata(String cf)=> _metadata[cf];
  Map<String,VariableMirror> VariableMirrors;
  Map<String,dynamic> _base;
  
  Map<String,dynamic> get changes {
    Map<String,dynamic> latest = encode();
    if(_base==null) {
      return latest;
    }
    Map<String,dynamic> changed = new Map<String,dynamic>();
    latest.keys.forEach((e){ 
      if(_base[e]==null){
        changed[e] = latest[e];
      }else{
        if(latest[e] != _base[e]) {
          if (e=="Id") {
            changed[e] = latest[e];
          }else{
            if (latest[e]==null){
              latest[e] = new Map<String,dynamic>();
            }
            Map<String,dynamic> chg = _diff(_base[e],latest[e]);
            if (chg!=null){
              changed[e]=chg;
            }
          }
        }  
      }
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

  Map<String,dynamic> _diff(Map<String,dynamic> src,Map<String,dynamic> dst){
    Map<String,dynamic> res={};
    List<String> srcKeys=src.keys.toList();
    List<String> dstKeys=dst.keys.toList();
    List<String> allKeys=new List<String>();
    allKeys.addAll(srcKeys);
    allKeys.addAll(dstKeys);
    allKeys.toSet().forEach((e){
      if (src[e]!=dst[e] && dst[e]!=null) res[e]=dst[e]; 
//      print(src[e]);
//      print(dst[e]);
//      print(src[e]!=dst[e]);
//      if (src[e]!=dst[e])  {
//        switch (dst[e].runtimeType.toString()){
//          case 'DateTime':
//            res[e]=dst[e].toString();
//            break;
//          default:
//            res[e]=dst[e];
//        }
//      }
    });
    if (res.isEmpty){
      return null;
    }
    return res;
  }
}  

//  List boolTrueOptions = ['1', 'true', true, 1,'True','TRUE'];
//  List boolFalseOptions = ['0', 'false', false, 0,'False','FALSE'];
//  List _boolOptions;
//  List get boolOptions {
//    if (_boolOptions==null) {
//      _boolOptions.addAll(boolTrueOptions);
//      _boolOptions.addAll(boolFalseOptions);
//    }
//    return _boolOptions;
//  }
