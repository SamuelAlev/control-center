import 'dart:convert';

import 'package:cc_domain/features/sandboxing/domain/terminal_command_buffer.dart';
import 'package:test/test.dart';

void main() {
  List<int> bytes(String s) => utf8.encode(s);

  test('keystrokes without Enter are not a send', () {
    final buf = TerminalCommandBuffer();
    expect(buf.feed(bytes('l')), TerminalWriteResult.none);
    expect(buf.feed(bytes('s')), TerminalWriteResult.none);
  });

  test('Enter after typed characters submits the reconstructed line', () {
    final buf = TerminalCommandBuffer();
    buf.feed(bytes('l'));
    buf.feed(bytes('s'));
    final result = buf.feed(bytes('\r'));
    expect(result.sent, isTrue);
    expect(result.command, 'ls');
  });

  test('a paste that includes the send reports the line in one shot', () {
    final result = TerminalCommandBuffer().feed(bytes('git status\r'));
    expect(result.sent, isTrue);
    expect(result.command, 'git status');
  });

  test('CRLF is one send, not two', () {
    final oneShot = TerminalCommandBuffer();
    expect(oneShot.feed(bytes('pwd\r\n')).command, 'pwd');

    final split = TerminalCommandBuffer();
    split.feed(bytes('pwd'));
    expect(split.feed(bytes('\r')).command, 'pwd');
    expect(split.feed(bytes('\n')), TerminalWriteResult.none);
  });

  test('backspace edits the pending line before send', () {
    final buf = TerminalCommandBuffer();
    buf.feed(bytes('lss'));
    buf.feed([0x7f]);
    expect(buf.feed(bytes('\r')).command, 'ls');
  });

  test('Ctrl+U and Ctrl+C clear the pending line without sending', () {
    final buf = TerminalCommandBuffer();
    buf.feed(bytes('rm -rf /'));
    expect(buf.feed([0x15]), TerminalWriteResult.none);
    expect(buf.feed(bytes('\r')).command, '');
    buf.feed(bytes('secret'));
    expect(buf.feed([0x03]), TerminalWriteResult.none);
    expect(buf.feed(bytes('\r')).command, '');
  });
}
