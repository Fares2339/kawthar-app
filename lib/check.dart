import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

void main() {
  final s = getVerseQCF(1, 1, verseEndSymbol: false);
  debugPrint('CODES: ${s.runes.map((r) => r.toRadixString(16)).join(' ')}');
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            s,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'QCF_P001',
              package: 'qcf_quran',
              fontSize: 40,
            ),
          ),
        ),
      ),
    ),
  );
}
