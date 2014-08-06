part of arasu.model;
class Util {
  static Iterable<DeclarationMirror> declarations(ClassMirror cm) => cm.declarations.values.where((dm) => dm is VariableMirror && !dm.isConst && !dm.isFinal && !dm.isPrivate && !dm.isStatic && !dm.isTopLevel);
  static List<String> commonList(List<String> a, List<String> b) {
    List<String> c = new List<String>();
    a.forEach((e) {
      if (b.contains(e)) c.add(e);
    });
    return c;
  }
  
  static Map<String,VariableMirror> VariableMirrors(ClassMirror cm) {
    Map<String,VariableMirror> vars = new Map<String,VariableMirror>();
    declarations(cm).forEach((e)=>vars[MirrorSystem.getName(e.simpleName)]=e);
    return vars;
  }
  
}
