// 本项目的**开发/测试通道**（不是原作机制，所以没有 `PORT OF:`）。
//
// ## 为什么需要它
//
// 现在的验证方式只有两条：
//   * `FE8R_SCRIPT` —— 一串**写死**的按键，60ms 一个，喂完就不管
//   * `FE8R_DUMP`   —— 跑完写一次状态
//
// 于是调试长这样：**先猜**一长串按键，跑 30–90 秒，再看转储，
// 发现猜错了（多按了一次确认把单位又动了一次）→ 改脚本 → 再跑。
// 这一轮我在序章上就这么来回烧了好几轮。
//
// 这个通道把它换成"**看得见再按键**"：AI/测试连上来，
// 先 `state` 读全部状态，再决定按什么，再读一次确认。
//
// ## 协议（loopback TCP，一行一个 JSON，一行一个回复）
//
//     {"cmd":"state"}                    → dumpState() 的全部字段
//     {"cmd":"press","keys":["start"]}   → 立即注入按键（无间隔）
//     {"cmd":"script","seq":"down,confirm"} → 交给 runScript（带 60ms 间隔、支持 wait）
//     {"cmd":"quit"}                     → 关闭
//
// 只在 `FE8R_CTL=<port>` 时监听，且**只绑 127.0.0.1**。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 默认端口。**不要用 19387** —— 那是 DSH Web GUI 的端口（会回 HTTP 400）。
const int kCtlDefaultPort = 41999;

class CtlServer {
  CtlServer({
    required this.port,
    required this.onState,
    required this.onPress,
    required this.onScript,
    this.onQuit,
    this.log,
  });

  final int port;
  final Map<String, dynamic> Function() onState;
  final void Function(List<String> keys) onPress;
  final Future<void> Function(String seq) onScript;
  final void Function()? onQuit;
  final void Function(String)? log;

  ServerSocket? _srv;

  Future<void> start() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    _srv = s;
    log?.call('监听 127.0.0.1:$port');
    s.listen(_handle, onError: (Object e) => log?.call('连接出错: $e'));
  }

  Future<void> stop() async {
    await _srv?.close();
    _srv = null;
  }

  Future<void> _handle(Socket sock) async {
    sock.setOption(SocketOption.tcpNoDelay, true);
    final lines = utf8.decoder.bind(sock).transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      Object? reply;
      var quit = false;
      try {
        final req = jsonDecode(line) as Map<String, dynamic>;
        switch (req['cmd']) {
          case 'state':
            reply = onState();
          case 'press':
            final keys = ((req['keys'] as List?) ?? const []).cast<String>();
            onPress(keys);
            reply = {'ok': true, 'pressed': keys};
          case 'script':
            final seq = '${req['seq'] ?? ''}';
            unawaited(onScript(seq));
            reply = {'ok': true, 'queued': seq};
          case 'quit':
            reply = {'ok': true};
            quit = true;
          default:
            reply = {'ok': false, 'error': 'unknown cmd ${req['cmd']}'};
        }
      } catch (e) {
        reply = {'ok': false, 'error': '$e'};
      }
      sock.writeln(jsonEncode(reply));
      await sock.flush();
      if (quit) {
        sock.destroy(); // 不等对端 FIN（否则对端 `close()` 会挂住）
        await stop();
        onQuit?.call();
        return;
      }
    }
    // ★ EOF（客户端关了）也要**把这一侧的 socket 收掉**：
    // 不收就停在 CLOSE_WAIT，而对端 `await close()` 会一直等我们 —— 第一次就这么挂住了。
    sock.destroy();
  }
}
