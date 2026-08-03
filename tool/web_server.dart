import 'dart:async';
import 'dart:io';

const _defaultPort = 18765;

Future<void> main(List<String> arguments) async {
  final port = arguments.isEmpty
      ? _defaultPort
      : int.tryParse(arguments.first) ?? _defaultPort;
  final root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('找不到 build/web，请先构建网页版。');
    exitCode = 1;
    return;
  }

  late final HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  } on SocketException {
    // 已有求知网页服务运行时，启动器可以直接复用它。
    return;
  }

  stdout.writeln('求知网页版：http://127.0.0.1:$port');
  await for (final request in server) {
    // 每个请求独立 try-catch，单个请求异常不会让整个服务器崩溃。
    try {
      await _serve(request, root);
    } catch (error) {
      // 客户端刷新/取消请求时会触发异常，忽略即可。
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }
}

Future<void> _serve(HttpRequest request, Directory root) async {
  if (request.uri.path == '/api/hotwords') {
    await _proxyHotwords(request);
    return;
  }

  var path = Uri.decodeComponent(request.uri.path);
  if (path == '/' || path.isEmpty) path = '/index.html';
  if (path.split('/').contains('..')) {
    request.response.statusCode = HttpStatus.forbidden;
    await request.response.close();
    return;
  }

  final relative = path.substring(1).replaceAll('/', Platform.pathSeparator);
  var file = File('${root.path}${Platform.pathSeparator}$relative');
  if (!file.existsSync() || file is Directory) {
    // Flutter 使用客户端路由，未知路径交给入口页面处理。
    file = File('${root.path}${Platform.pathSeparator}index.html');
  }

  request.response.headers.contentType = _contentType(file.path);
  request.response.headers
    ..set('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
    ..set('Pragma', 'no-cache')
    ..set('Expires', '0');
  await request.response.addStream(file.openRead());
  await request.response.close();
}

Future<void> _proxyHotwords(HttpRequest request) async {
  const allowedHosts = {
    'gitee.com',
    'www.gitee.com',
    'api.github.com',
    'raw.githubusercontent.com',
    'cdn.jsdelivr.net',
  };
  final value = request.uri.queryParameters['url'] ?? '';
  final remote = Uri.tryParse(value);
  if (remote == null ||
      remote.scheme != 'https' ||
      !allowedHosts.contains(remote.host.toLowerCase())) {
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write('Unsupported hotword source.');
    await request.response.close();
    return;
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final upstreamRequest = await client.getUrl(remote);
    upstreamRequest.headers
      ..set(HttpHeaders.acceptHeader,
          'application/vnd.github.raw+json, application/json')
      ..set(HttpHeaders.userAgentHeader, 'qiuzhi-web/0.3.8');
    final upstream = await upstreamRequest.close();
    request.response.statusCode = upstream.statusCode;
    request.response.headers
      ..contentType = ContentType.json
      ..set('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
      ..set('Pragma', 'no-cache')
      ..set('Expires', '0');
    await request.response.addStream(upstream);
  } on Object catch (error) {
    request.response.statusCode = HttpStatus.badGateway;
    request.response.write('Hotword proxy failed: $error');
  } finally {
    client.close(force: true);
    await request.response.close();
  }
}

ContentType _contentType(String path) {
  final extension = path.toLowerCase().split('.').last;
  return switch (extension) {
    'html' => ContentType.html,
    'js' => ContentType('application', 'javascript', charset: 'utf-8'),
    'json' => ContentType.json,
    'css' => ContentType('text', 'css', charset: 'utf-8'),
    'png' => ContentType('image', 'png'),
    'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
    'svg' => ContentType('image', 'svg+xml'),
    'wasm' => ContentType('application', 'wasm'),
    'wav' => ContentType('audio', 'wav'),
    'woff' => ContentType('font', 'woff'),
    'woff2' => ContentType('font', 'woff2'),
    _ => ContentType.binary,
  };
}
