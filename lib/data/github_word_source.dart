import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';

/// 从 GitHub 或任意公开 JSON 地址拉取远程词库。
class GithubWordSource {
  static const _timeout = Duration(seconds: 15);

  /// 拉取并解析远程词库。
  ///
  /// GitHub 地址会按 jsDelivr CDN → GitHub API → Raw 的顺序尝试，
  /// 避免部分网络无法解析 raw.githubusercontent.com 时完全不可用。
  static Future<List<Word>> fetch(
    String input, {
    http.Client? client,
    String? requiredPublishedDate,
  }) async {
    final candidates = candidateUris(input);
    Object? lastError;

    for (final uri in candidates) {
      try {
        final response = await (client == null
                ? http.get(uri, headers: _headersFor(uri))
                : client.get(uri, headers: _headersFor(uri)))
            .timeout(_timeout);
        if (response.statusCode == 404) {
          lastError = '文件不存在：$uri';
          continue;
        }
        if (response.statusCode != 200) {
          lastError = '${uri.host} 返回 HTTP ${response.statusCode}';
          continue;
        }

        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is! List) {
          lastError = '词库格式应为 JSON 数组';
          continue;
        }

        final words = data
            .whereType<Map<String, dynamic>>()
            .map(Word.fromJson)
            .where((word) => word.word.isNotEmpty)
            .toList();
        if (words.isEmpty) {
          lastError = '词库中没有可用名词';
          continue;
        }
        final requiredDate = requiredPublishedDate?.trim() ?? '';
        if (requiredDate.isNotEmpty &&
            !words.any((word) => word.publishedDate == requiredDate)) {
          final dates = words
              .map((word) => word.publishedDate)
              .where((date) => date.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final latest = dates.isEmpty ? '日期未知' : dates.last;
          lastError = '$uri 仍是旧缓存（最新 $latest，需要 $requiredDate）';
          continue;
        }
        return words;
      } catch (error) {
        lastError = error;
      }
    }

    final detail =
        lastError?.toString().replaceFirst('Exception: ', '') ?? '没有找到可用的词库文件';
    throw Exception('无法读取远程词库（已尝试 CDN、GitHub API 和 Raw）：$detail');
  }

  /// 将用户输入转换为可直接请求的候选地址。
  static List<Uri> candidateUris(String input) {
    var value = input.trim();
    if (value.isEmpty) throw const FormatException('请填写词库地址');
    if (!value.contains('://')) value = 'https://$value';

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('地址格式不正确');
    }
    if (uri.scheme != 'https') {
      throw const FormatException('为安全起见，词库地址必须为 https');
    }

    final host = uri.host.toLowerCase();
    if (_isPrivateOrLocalhost(host)) {
      throw const FormatException('不支持访问内网或本机地址');
    }
    if (host == 'raw.githubusercontent.com') {
      final rawParts =
          uri.pathSegments.where((part) => part.isNotEmpty).toList();
      if (rawParts.length >= 4) {
        return _githubFileCandidates(
          rawParts[0],
          rawParts[1],
          rawParts[2],
          rawParts.sublist(3).join('/'),
        );
      }
      return [uri];
    }
    if (host != 'github.com' && host != 'www.github.com') return [uri];

    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) {
      throw const FormatException('GitHub 地址需要包含用户名和仓库名');
    }

    final owner = parts[0];
    final repository = parts[1].replaceFirst(RegExp(r'\.git$'), '');

    // GitHub 文件页：https://github.com/user/repo/blob/branch/path/file.json
    if (parts.length >= 5 && parts[2] == 'blob') {
      return _githubFileCandidates(
        owner,
        repository,
        parts[3],
        parts.sublist(4).join('/'),
      );
    }

    // 仓库主页：优先每日推送专用目录，并兼容旧的根目录文件。
    const files = [
      ('master', 'daily_hotwords/library.json'),
      ('main', 'daily_hotwords/library.json'),
      ('master', 'daily_hotwords/words.json'),
      ('main', 'daily_hotwords/words.json'),
      ('main', 'words.json'),
      ('main', 'words.example.json'),
      ('master', 'words.json'),
      ('master', 'words.example.json'),
    ];

    // GitHub API 能直接读取分支最新内容，优先于可能缓存旧 master 的 CDN；
    // Raw 放在最后，兼容部分网络无法解析 raw.githubusercontent.com 的情况。
    return [
      for (final file in files) ...[
        _apiUri(owner, repository, file.$1, file.$2),
        _jsDelivrUri(owner, repository, file.$1, file.$2),
      ],
      for (final file in files) _rawUri(owner, repository, file.$1, file.$2),
    ];
  }

  static bool _isPrivateOrLocalhost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h == '127.0.0.1' || h == '::1' || h == '0.0.0.0') {
      return true;
    }
    if (h.startsWith('10.') ||
        h.startsWith('192.168.') ||
        h.startsWith('169.254.')) {
      return true;
    }
    if (h.startsWith('172.')) {
      final parts = h.split('.');
      if (parts.length >= 2) {
        final n = int.tryParse(parts[1]);
        if (n != null && n >= 16 && n <= 31) return true;
      }
    }
    return false;
  }

  static List<Uri> _githubFileCandidates(
    String owner,
    String repository,
    String branch,
    String path,
  ) {
    return [
      _apiUri(owner, repository, branch, path),
      _jsDelivrUri(owner, repository, branch, path),
      _rawUri(owner, repository, branch, path),
    ];
  }

  static Map<String, String> _headersFor(Uri uri) {
    if (uri.host.toLowerCase() == 'api.github.com') {
      return const {
        'Accept': 'application/vnd.github.raw+json',
        'User-Agent': 'qiuzhi-app',
        'Cache-Control': 'no-cache',
      };
    }
    return const {'Cache-Control': 'no-cache'};
  }

  static Uri _jsDelivrUri(
    String owner,
    String repository,
    String branch,
    String path,
  ) {
    return Uri.https(
      'cdn.jsdelivr.net',
      '/gh/$owner/$repository@$branch/$path',
    );
  }

  static Uri _apiUri(
    String owner,
    String repository,
    String branch,
    String path,
  ) {
    return Uri.https(
      'api.github.com',
      '/repos/$owner/$repository/contents/$path',
      {'ref': branch},
    );
  }

  static Uri _rawUri(
    String owner,
    String repository,
    String branch,
    String path,
  ) {
    return Uri.https(
      'raw.githubusercontent.com',
      '/$owner/$repository/$branch/$path',
    );
  }
}
