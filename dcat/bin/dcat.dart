import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

// 主函数
Future<void> main() async {
  // 如果环境变量中设置了 "PORT"，则使用它来监听请求。否则使用默认的 8080 端口。
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // 创建一个 Cascade 实例，用于级联多个处理程序函数。
  final cascade = Cascade()
      // 首先，从 'public' 目录中提供静态文件服务。
      .add(_staticHandler)
      // 如果找不到相应的文件，则将请求发送到 Router。
      .add(_router);

  // 在指定的地址和端口上启动服务器。
  final server = await shelf_io.serve(
    // 记录请求信息，并将请求发送到 Cascade 处理程序。
    logRequests().addHandler(cascade.handler),
    InternetAddress.anyIPv4, // 允许外部连接
    port,
  );

  // 打印服务器的地址和端口。
  print('Serving at http://${server.address.host}:${server.port}');

  // 用于追踪服务器运行时间的 Stopwatch 实例。
  _watch.start();
}

// 从文件系统中提供静态文件服务的处理程序函数。
final _staticHandler =
    shelf_static.createStaticHandler('public', defaultDocument: 'index.html');

// 用于路由请求的 Router 实例。
final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..get('/info.json', _infoHandler)
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>', _sumHandler)
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>/<c|[0-9]+>', _sumHandler02)
  ..get('/sum/<a>/<b>', _sumHandler03);

// 处理 "/helloworld" 请求的处理程序函数。
Response _helloWorldHandler(Request request) => Response.ok('Hello, World!');

// 用于返回当前时间的处理程序函数。
String _jsonEncode(Object? data) =>
    const JsonEncoder.withIndent(' ').convert(data);

// 用于返回 JSON 格式响应的 HTTP 头。
const _jsonHeaders = {
  'content-type': 'application/json',
};

// 处理 "/sum/<a>/<b>" 请求的处理程序函数。
Response _sumHandler(Request request,String a, String b) {
  final aNum = int.parse(a);
  final bNum = int.parse(b);
  return Response.ok(
    // 返回 JSON 格式响应。
    _jsonEncode({'a': aNum, 'b': bNum, 'sum': aNum + bNum}),
    headers: {
      ..._jsonHeaders,
      // 设置缓存控制头，使浏览器可以缓存响应结果。
      'Cache-Control': 'public, max-age=604800, immutable',
    },
  );
}

Response _sumHandler02(Request request,String a, String b,String c ) {
  final aNum = int.parse(a);
  final bNum = int.parse(b);
  final cNum = int.parse(c);
  return Response.ok(
    // 返回 JSON 格式响应。
    _jsonEncode({'a': aNum, 'b': bNum,'c': cNum,  'sum': aNum + bNum+cNum}),
    headers: {
      ..._jsonHeaders,
      // 设置缓存控制头，使浏览器可以缓存响应结果。
      'Cache-Control': 'public, max-age=604800, immutable',
    },
  );
}
// 处理 "/sum/<a>/<b>" 请求的处理程序函数。
Response _sumHandler03(Request request,String a, String b) {
 
  return Response.ok(
    // 返回 JSON 格式响应。
    _jsonEncode({'a': a, 'b': b, 'sum': '$a $b'}),
    headers: {
      ..._jsonHeaders,
      // 设置缓存控制头，使浏览器可以缓存响应结果。
      'Cache-Control': 'public, max-age=604800, immutable',
    },
  );
}


    
// 用于追踪服务器运行时间的 Stopwatch 实例。
final _watch = Stopwatch();

// 用于统计请求次数的计数器。
int _requestCount = 0;

// 当前 Dart 版本号。
final _dartVersion = () {
  final version = Platform.version;
  return version.substring(0, version.indexOf(' '));
}();

// 处理 "/info.json" 请求的处理程序函数。
Response _infoHandler(Request request) => Response(
      200,
      headers: {
        ..._jsonHeaders,
        // 禁止浏览器缓存响应结果。
        'Cache-Control': 'no-store',
      },
      body: _jsonEncode(
        {
          'Dart version': _dartVersion,
          'uptime': _watch.elapsed.toString(),
          'requestCount': ++_requestCount,
        },
      ),
    );