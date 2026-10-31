import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

// ===== أرقام الضبط =====
// عرض الإطار: قلّله لو فيه فراغ على الجنب (جرّب 380 ثم 370 ثم 360)
const double kVirtualWidth = 380;
// أقل طول للإطار: زوّده لو لسه فيه سكرول (جرّب 850 ثم 900)
const double kMinHeight = 850;
const double kFontScale = 1.0;
const double kLineScale = 1.0;
const int kStartPage = 50;

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

class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final TransformationController _tc = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final z = _tc.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) setState(() => _zoomed = z);
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final vh = math.max(kMinHeight, kVirtualWidth * h / w);

            return InteractiveViewer(
              transformationController: _tc,
              minScale: 1,
              maxScale: 3.5,
              panEnabled: _zoomed, // السحب للتنقل بين الصفحات لما مش مكبّر
              child: SizedBox(
                width: w,
                height: h,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: kVirtualWidth,
                    height: vh,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(kVirtualWidth, vh),
                        textScaler: TextScaler.noScaling,
                      ),
                      child: PageviewQuran(
                        initialPageNumber: kStartPage,
                        sp: kFontScale,
                        h: kLineScale,
                        onPageChanged: (p) => debugPrint('Page: $p'),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}