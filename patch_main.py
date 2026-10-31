p = "lib/main.dart"
s = open(p, encoding="utf-8-sig").read()

def rep(old, new):
    global s
    if s.count(old) != 1:
        print("NOT FOUND (or repeated):", old[:50])
        return
    s = s.replace(old, new)

rep("import 'package:flutter/services.dart';",
    "import 'package:flutter/services.dart';\nimport 'package:shared_preferences/shared_preferences.dart';")

rep("""  final PageController _pc = PageController(initialPage: kStartPage - 1);
  bool _dark = true;
  int _page = kStartPage;
""", """  PageController? _pc;
  bool _dark = true;
  int _page = kStartPage;
  SharedPreferences? _prefs;
  late final Future<void> _init = _loadPrefs();
  late final Future<MushafData> _ready =
      Future.wait([_future, _init]).then((r) => r[0] as MushafData);

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    _dark = p.getBool('dark') ?? true;
    _page = (p.getInt('page') ?? kStartPage).clamp(1, 604).toInt();
    _pc = PageController(initialPage: _page - 1);
  }
""")

rep("_pc.dispose();", "_pc?.dispose();")

rep("onPressed: () => setState(() => _dark = !_dark),",
    """onPressed: () {
              setState(() => _dark = !_dark);
              _prefs?.setBool('dark', _dark);
            },""")

rep("future: _future,", "future: _ready,")
rep("controller: _pc,", "controller: _pc!,")

rep("onPageChanged: (i) => setState(() => _page = i + 1),",
    """onPageChanged: (i) {
                        setState(() => _page = i + 1);
                        _prefs?.setInt('page', i + 1);
                      },""")

open(p, "w", encoding="utf-8", newline="\n").write(s)
print("done")
