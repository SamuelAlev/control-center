import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

void main() {
  group('code language registry', () {
    test('maps common extensions to language ids', () {
      expect(languageIdForPath('lib/a.dart'), 'dart');
      expect(languageIdForPath('src/app.js'), 'javascript');
      expect(languageIdForPath('src/app.jsx'), 'javascript');
      expect(languageIdForPath('src/app.mjs'), 'javascript');
      expect(languageIdForPath('src/app.ts'), 'typescript');
      expect(languageIdForPath('src/App.tsx'), 'tsx');
      expect(languageIdForPath('src/Foo.php'), 'php');
      expect(languageIdForPath('src/app.py'), 'python');
      expect(languageIdForPath('src/app.pyi'), 'python');
      expect(languageIdForPath('src/main.rs'), 'rust');
      expect(languageIdForPath('src/main.zig'), 'zig');
      expect(languageIdForPath('src/main.c'), 'c');
      expect(languageIdForPath('src/main.h'), 'c');
      expect(languageIdForPath('src/main.cpp'), 'cpp');
      expect(languageIdForPath('src/main.cc'), 'cpp');
      expect(languageIdForPath('src/main.hpp'), 'cpp');
      expect(languageIdForPath('src/main.go'), 'go');
      expect(languageIdForPath('src/Main.java'), 'java');
      expect(languageIdForPath('src/app.rb'), 'ruby');
      expect(languageIdForPath('src/Program.cs'), 'c_sharp');
      expect(languageIdForPath('src/App.swift'), 'swift');
      expect(languageIdForPath('src/Main.kt'), 'kotlin');
      expect(languageIdForPath('src/build.kts'), 'kotlin');
      expect(languageIdForPath('src/plot.R'), 'r');
      expect(languageIdForPath('src/boot.s'), 'asm');
      expect(languageIdForPath('src/boot.asm'), 'asm');
      expect(languageIdForPath('src/fit.m'), 'matlab');
      expect(languageIdForPath('src/pkg.ads'), 'ada');
      expect(languageIdForPath('src/pkg.adb'), 'ada');
      expect(languageIdForPath('src/pkg.ada'), 'ada');
    });

    test('returns null for unsupported / extensionless paths', () {
      expect(languageIdForPath('README.md'), isNull);
      expect(languageIdForPath('Makefile'), isNull);
      expect(languageIdForPath('trailing.'), isNull);
    });

    test('is case-insensitive on extension', () {
      expect(languageIdForPath('SRC/APP.TS'), 'typescript');
    });

    test('tsx reuses the typescript query; others map to themselves', () {
      expect(queryIdFor('tsx'), 'typescript');
      expect(queryIdFor('typescript'), 'typescript');
      expect(queryIdFor('javascript'), 'javascript');
      expect(queryIdFor('php'), 'php');
      expect(queryIdFor('dart'), 'dart');
      expect(queryIdFor('python'), 'python');
      expect(queryIdFor('c_sharp'), 'c_sharp');
      expect(queryIdFor('swift'), 'swift');
      expect(queryIdFor('kotlin'), 'kotlin');
      expect(queryIdFor('r'), 'r');
      expect(queryIdFor('asm'), 'asm');
      expect(queryIdFor('matlab'), 'matlab');
      expect(queryIdFor('ada'), 'ada');
    });
  });
}
