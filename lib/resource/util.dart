part of arasu.resource;
class Util {
  static Map<String, dynamic> changes(Map<String, dynamic> dst, src, var metadata) {
    if (src == null && dst == null) return {};
    if (src == null) return dst;

    if (metadata == null) metadata = {};
    Map<String, dynamic> res = new Map<String, dynamic>();
    List<String> keys = dst.keys.toList();
    keys.addAll(src.keys.toList());
    keys = keys.toSet().toList();

    keys.forEach((String k) {
      if (dst[k] != src[k]) {
        String type = dst[k].runtimeType.toString();
        if (type.startsWith('_LinkedHashMap')) {
          Map localMap = changes(dst[k], src[k], metadata[k]);
          if (localMap.isNotEmpty) res[k] = localMap;
        } else {
          var value = dst[k].toString();
          switch (metadata[k]) {
            case 'String':
              value = value;
              break;
            case 'int':
              value = int.parse(value, onError: (_) => 0);
              break;
            case 'Int':
              value = int.parse(value, onError: (_) => 0);
              break;
            case 'bool':
              value = ['1', 'true', true, 1].contains(value);
              break;
            case 'Bool':
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
              value = dst[k];
              Logger.root.info("can't identify $k data type,so making it to incoming type");
          } //end switch
          if (value != src[k]) res[k] = value;
        }
      }//end if
    });
    return res;
  }

  static Map<String, dynamic> encodeForJSON(Map<String, dynamic> attr) {
    Map<String, dynamic> map = new Map<String, dynamic>();
    attr.forEach((String k, var v) {
      String type = v.runtimeType.toString();
      if (type.startsWith('_LinkedHashMap')) {
        if (v.isNotEmpty) map[k] = encodeForJSON(v);
      } else {
        switch (v.runtimeType.toString()) {
          case 'DateTime':
            map[k] = v.toString();
            break;
          default:
            map[k] = v;
        }
      }
    });
    return map;
  }
  static Map<String, dynamic> clone(Map<String, dynamic> src) {
    Map<String, dynamic> res = new Map<String, dynamic>();
    src.forEach((String k, var v) {
      String type = v.runtimeType.toString();
      if (type.startsWith('_LinkedHashMap')) {
        if (v.isNotEmpty) res[k] = clone(v);
      } else {
        switch (v.runtimeType.toString()) {
          case 'DateTime':
            res[k] = DateTime.parse(v.toString());
            break;
          default:
            res[k] = v;
        }
      }
    });
    return res;
  }

}
