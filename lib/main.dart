import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int kStartPage = 50;

// أول صفحة في كل جزء (راجعها مع مصحفك المطبوع)
const List<int> kJuzStart = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
  201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
  402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
];

int juzOf(int page) {
  var j = 1;
  for (var i = 0; i < kJuzStart.length; i++) {
    if (page >= kJuzStart[i]) j = i + 1;
  }
  return j;
}

class MushafColors {
  final Color bg, text, accent;
  const MushafColors(this.bg, this.text, this.accent);
  static const light =
      MushafColors(Color(0xFFFCF8EE), Color(0xFF1B1B1B), Color(0xFF9C7A2B));
  static const dark =
      MushafColors(Color(0xFF14161A), Color(0xFFE8E2D0), Color(0xFFC8A951));
}

void main() {
  runApp(const KawtharApp());
}

class KawtharApp extends StatelessWidget {
  const KawtharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كوثر',
      home: MushafScreen(),
    );
  }
}

class MushafData {
  final List<String> surahs;
  final List<List<Map<String, dynamic>>> pages;
  final List<int> startSurah;
  MushafData(this.surahs, this.pages, this.startSurah);

  static Future<MushafData> load() async {
    final raw = await rootBundle.loadString('assets/mushaf_v2.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final surahs = List<String>.from(json['surahs'] as List);
    final pages = (json['pages'] as List)
        .map((p) => (p as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList())
        .toList();
    final start = <int>[];
    var cur = 1;
    for (final p in pages) {
      start.add(p.isNotEmpty && p.first['t'] == 's' ? p.first['n'] as int : cur);
      for (final l in p) {
        if (l['t'] == 's') cur = l['n'] as int;
      }
    }
    return MushafData(surahs, pages, start);
  }
}

class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final Future<MushafData> _future = MushafData.load();
  PageController? _pc;
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

  @override
  void dispose() {
    _pc?.dispose();
    super.dispose();
  }

  Widget _topBar(MushafData d, MushafColors c) {
    final style = TextStyle(color: c.text.withAlpha(210), fontSize: 13);
    final surah = d.surahs[d.startSurah[_page - 1] - 1];
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text('الجزء ${juzOf(_page)}', style: style),
          Expanded(
            child: Center(
              child: Text(
                'سورة $surah',
                style: style.copyWith(
                    color: c.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Text('$_page', style: style),
          IconButton(
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            color: c.accent,
            icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() => _dark = !_dark);
              _prefs?.setBool('dark', _dark);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _dark ? MushafColors.dark : MushafColors.light;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: FutureBuilder<MushafData>(
          future: _ready,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData) {
              return Center(child: CircularProgressIndicator(color: c.accent));
            }
            final d = snap.data!;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  _topBar(d, c),
                  Expanded(
                    child: PageView.builder(
                      controller: _pc!,
                      itemCount: d.pages.length,
                      onPageChanged: (i) {
                        setState(() => _page = i + 1);
                        _prefs?.setInt('page', i + 1);
                      },
                      itemBuilder: (context, i) => MushafPage(
                        pageNumber: i + 1,
                        lines: d.pages[i],
                        surahs: d.surahs,
                        c: c,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MushafPage extends StatelessWidget {
  final int pageNumber;
  final List<Map<String, dynamic>> lines;
  final List<String> surahs;
  final MushafColors c;

  const MushafPage({
    super.key,
    required this.pageNumber,
    required this.lines,
    required this.surahs,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final family = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';

    return LayoutBuilder(
      builder: (context, box) {
        // 8 هامش خارجي + 6 مسافة داخل الإطار + 1 سمك الإطار
        final w = box.maxWidth - 16 - 12 - 2;
        final h = box.maxHeight - 12 - 12 - 2;

        TextStyle styleAt(double size, {String? fam}) => TextStyle(
              fontFamily: fam ?? family,
              package: 'qcf_quran',
              fontSize: size,
              height: 1.0,
              color: c.text,
            );

        double measure(String t) {
          final tp = TextPainter(
            text: TextSpan(text: t.replaceAll('|', ''), style: styleAt(100)),
            textDirection: TextDirection.rtl,
            maxLines: 1,
          )..layout();
          return tp.width;
        }

        double justMax = 0;
        double allMax = 0;
        for (final l in lines) {
          if (l['t'] != 'a') continue;
          final wd = measure(l['x'] as String);
          if (wd > allMax) allMax = wd;
          if (l['c'] == 0 && wd > justMax) justMax = wd;
        }
        final ref = justMax > 0 ? justMax : allMax / 0.82;
        var font = ref > 0 ? 100 * w / ref : 24.0;

        final count = lines.length;
        final rowH = count >= 15 ? h / 15 : math.min(h / 15 * 1.6, h / count);
        font = math.min(font, rowH);

        Widget diamond() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    border: Border.all(color: c.accent, width: 1.4),
                  ),
                ),
              ),
            );

        InlineSpan verseSpan(String raw) {
          final parts = raw.split('|');
          return TextSpan(
            children: [
              for (var i = 0; i < parts.length; i++)
                if (parts[i].isNotEmpty)
                  TextSpan(
                    text: parts[i],
                    style: i.isOdd ? TextStyle(color: c.accent) : null,
                  ),
            ],
          );
        }

        Widget buildLine(Map<String, dynamic> l) {
          final type = l['t'] as String;

          if (type == 's') {
            final n = l['n'] as int;
            return SizedBox(
              width: w,
              height: rowH,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: rowH * 0.06),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.accent, width: 1.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.accent.withAlpha(28),
                      border: Border.all(
                          color: c.accent.withAlpha(150), width: 0.8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        diamond(),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'سورة ${surahs[n - 1]}',
                                style: TextStyle(
                                  fontSize: font * 0.95,
                                  fontWeight: FontWeight.bold,
                                  color: c.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        diamond(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          if (type == 'b') {
            return SizedBox(
              width: w,
              height: rowH,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\uFC41\uFC42\uFC43\uFC44',
                    textDirection: TextDirection.rtl,
                    style: styleAt(font, fam: 'QCF_P001'),
                  ),
                ),
              ),
            );
          }

          final justified = l['c'] == 0;
          return SizedBox(
            width: w,
            height: rowH,
            child: FittedBox(
              fit: justified ? BoxFit.contain : BoxFit.scaleDown,
              child: Text.rich(
                verseSpan(l['x'] as String),
                textDirection: TextDirection.rtl,
                softWrap: false,
                style: styleAt(font),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: c.accent.withAlpha(90)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: lines.map(buildLine).toList(),
          ),
        );
      },
    );
  }
}
