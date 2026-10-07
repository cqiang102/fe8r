import 'dart:async';
// 实时控制通道的**客户端** —— 让 AI/脚本"看得见再按键"。
//
// 用法（游戏用 `FE8R_CTL=19387` 起）：
//
//     dart run tools/verify/ctl.dart '{"cmd":"state"}'                 # 打印全部状态（JSON）
//     dart run tools/verify/ctl.dart '{"cmd":"state"}' --get turn      # 只取一个字段
//     dart run tools/verify/ctl.dart '{"cmd":"press","keys":["start"]}'
//     dart run tools/verify/ctl.dart '{"cmd":"script","seq":"down,confirm"}'
//     dart run tools/verify/ctl.dart '{"cmd":"quit"}'
//
// 端口取 `FE8R_CTL_PORT`（默认 41999），与游戏端 `FE8R_CTL` 对应。
// ⚠️ 别用 19387（那是 DSH Web GUI 的端口）。
import 'dart:convert';
import 'dart:io';

Future<int> main(List<String> argv) async {
  if (argv.isEmpty) {
    stderr.writeln('用法: ctl.dart \'{"cmd":"state"}\' [--get 字段]');
    return 2;
  }
  final port = int.tryParse(Platform.environment['FE8R_CTL_PORT'] ?? '') ?? 41999;
  final raw = argv.first;
  final getIdx = argv.indexOf('--get');
  final get = getIdx >= 0 && getIdx + 1 < argv.length ? argv[getIdx + 1] : null;

  late final Socket sock;
  try {
    sock = await Socket.connect('127.0.0.1', port,
        timeout: const Duration(seconds: 3));
  } catch (e) {
    stderr.writeln('连不上 127.0.0.1:$port —— 游戏是用 FE8R_CTL=$port 起的吗？（$e）');
    return 1;
  }
  sock.writeln(raw);
  await sock.flush();

  final completer = Completer<String>();
  final buf = StringBuffer();
  sock.listen((d) {
    buf.write(utf8.decode(d));
    final s = buf.toString();
    if (s.contains('\n') && !completer.isCompleted) {
      completer.complete(s.split('\n').first);
    }
  }, onDone: () {
    if (!completer.isCompleted) completer.complete(buf.toString());
  }, onError: (Object e) {
    if (!completer.isCompleted) completer.completeError(e);
  });

  final line = await completer.future.timeout(const Duration(seconds: 10),
      onTimeout: () => '');
  sock.destroy(); // 不等对端 FIN
  if (line.isEmpty) {
    stderr.writeln('没有回复');
    return 1;
  }

  final decoded = jsonDecode(line);
  if (get != null) {
    // 支持点路径：`--get titleFlow.screen`
    Object? cur = decoded;
    for (final part in get.split('.')) {
      if (cur is Map && cur.containsKey(part)) {
        cur = cur[part];
      } else {
        stderr.writeln('没有字段 $get（在 "$part" 处断了）');
        return 1;
      }
    }
    stdout.writeln(cur is String ? cur : jsonEncode(cur));
    return 0;
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(decoded));
  return 0;
}
