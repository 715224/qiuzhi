import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word.dart';

class AiModelConfig {
  final String endpoint;
  final String model;
  final String apiKey;
  final int chunkSize;
  final int maxTermsPerChunk;

  const AiModelConfig({
    required this.endpoint,
    required this.model,
    this.apiKey = '',
    this.chunkSize = 6000,
    this.maxTermsPerChunk = 20,
  });

  bool get isReady => endpoint.trim().isNotEmpty && model.trim().isNotEmpty;

  /// endpoint 是否指向本机（允许 http，用于本地模型）。
  bool get isLocalhostEndpoint {
    final uri = Uri.tryParse(endpoint.trim());
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  /// endpoint 是否为会被中间人窃听的非加密 http（本机地址除外）。
  bool get usesInsecureHttp {
    final uri = Uri.tryParse(endpoint.trim());
    return uri != null && uri.scheme == 'http' && !isLocalhostEndpoint;
  }

  String get chatCompletionsUrl {
    final value = endpoint.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.endsWith('/chat/completions')) return value;
    if (value.endsWith('/v1')) return '$value/chat/completions';
    return '$value/v1/chat/completions';
  }
}

typedef BookProgressCallback = void Function(
  int completedChunks,
  int totalChunks,
  int extractedWords,
);

class AiBookService {
  static const _secureStorage = FlutterSecureStorage();
  static const _apiKeyStorageKey = 'ai_model_api_key';

  final http.Client _client;

  AiBookService({http.Client? client}) : _client = client ?? http.Client();

  static Future<AiModelConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String apiKey = '';
    try {
      apiKey = await _secureStorage.read(key: _apiKeyStorageKey) ?? '';
    } catch (_) {
      // 某些不支持安全存储的测试或桌面环境仍允许打开设置页。
    }
    return AiModelConfig(
      endpoint:
          prefs.getString('aiModelEndpoint') ?? 'https://api.openai.com/v1',
      model: prefs.getString('aiModelName') ?? '',
      apiKey: apiKey,
      chunkSize: prefs.getInt('aiBookChunkSize') ?? 6000,
      maxTermsPerChunk: prefs.getInt('aiBookMaxTerms') ?? 20,
    );
  }

  static Future<void> saveConfig(AiModelConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiModelEndpoint', config.endpoint.trim());
    await prefs.setString('aiModelName', config.model.trim());
    await prefs.setInt('aiBookChunkSize', config.chunkSize);
    await prefs.setInt('aiBookMaxTerms', config.maxTermsPerChunk);
    await _secureStorage.write(
      key: _apiKeyStorageKey,
      value: config.apiKey.trim(),
    );
  }

  Future<String> testConnection(AiModelConfig config) async {
    final content = await _request(
      config,
      system: '你是一个接口连通性测试助手。只回复“连接成功”。',
      user: '请确认连接。',
    );
    return content.trim();
  }

  Future<List<Word>> extractBook({
    required AiModelConfig config,
    required String bookText,
    required String packName,
    BookProgressCallback? onProgress,
  }) async {
    if (!config.isReady) {
      throw const FormatException('请先填写接口地址和模型名称。');
    }
    final normalized = bookText.replaceAll('\u0000', '').trim();
    if (normalized.length < 50) {
      throw const FormatException('书籍内容太短，请导入完整 TXT/Markdown 或粘贴更多正文。');
    }

    final chunks = _splitText(normalized, config.chunkSize.clamp(2000, 12000));
    final collected = <String, Word>{};
    final baseId = DateTime.now().microsecondsSinceEpoch;

    for (var index = 0; index < chunks.length; index++) {
      final response = await _request(
        config,
        system: _systemPrompt(config.maxTermsPerChunk.clamp(5, 50)),
        user:
            '这是全书第 ${index + 1}/${chunks.length} 段。请分析本段：\n\n${chunks[index]}',
      );
      final objects = parseWordObjects(response);
      for (final object in objects) {
        final wordText = (object['word'] ?? '').toString().trim();
        final definition = (object['definition'] ?? '').toString().trim();
        if (wordText.isEmpty || definition.isEmpty) continue;
        final key = wordText.toLowerCase();
        collected.putIfAbsent(
          key,
          () => Word(
            id: baseId + collected.length,
            word: wordText,
            pinyin: (object['pinyin'] ?? '').toString().trim(),
            field: _normalizeField(object['field']),
            difficulty: _normalizeDifficulty(object['difficulty']),
            pack: packName.trim(),
            definition: definition,
            category: (object['category'] ?? '其他').toString().trim(),
            simpleExplanation:
                (object['simpleExplanation'] ?? '').toString().trim(),
            lifeAnalogy: (object['lifeAnalogy'] ?? '').toString().trim(),
            practicalApplication:
                (object['practicalApplication'] ?? '').toString().trim(),
            commonMisconception:
                (object['commonMisconception'] ?? '').toString().trim(),
          ),
        );
      }
      onProgress?.call(index + 1, chunks.length, collected.length);
    }

    final words = collected.values.toList()
      ..sort((a, b) {
        const order = {'低': 0, '中': 1, '高': 2};
        final byDifficulty =
            (order[a.difficulty] ?? 1).compareTo(order[b.difficulty] ?? 1);
        return byDifficulty != 0 ? byDifficulty : a.word.compareTo(b.word);
      });
    return words;
  }

  Future<String> _request(
    AiModelConfig config, {
    required String system,
    required String user,
  }) async {
    if (config.usesInsecureHttp) {
      throw const FormatException(
        '接口地址为 http 明文，API Key 会被窃听。请改用 https，或使用本机地址（localhost/127.0.0.1）。',
      );
    }
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (config.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey.trim()}';
    }
    final response = await _client
        .post(
          Uri.parse(config.chatCompletionsUrl),
          headers: headers,
          body: jsonEncode({
            'model': config.model.trim(),
            'temperature': 0.2,
            'messages': [
              {'role': 'system', 'content': system},
              {'role': 'user', 'content': user},
            ],
          }),
        )
        .timeout(const Duration(seconds: 120));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // 不把响应体拼进异常，避免网关回显请求头时泄露 API Key。
      throw Exception(
        '模型接口返回 HTTP ${response.statusCode}，请检查接口地址、模型名与 API Key。',
      );
    }
    final decoded = jsonDecode(
      kIsWeb ? response.body : utf8.decode(response.bodyBytes),
    );
    if (decoded is! Map) {
      throw const FormatException('模型响应格式异常。');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('模型响应中没有 choices。');
    }
    final first = choices.first;
    if (first is! Map) {
      throw const FormatException('模型响应中没有 message。');
    }
    final message = first['message'];
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('模型没有返回可读取的文本内容。');
    }
    return content;
  }

  static List<String> _splitText(String text, int chunkSize) {
    final chunks = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = (start + chunkSize).clamp(0, text.length);
      if (end < text.length) {
        final lowerBound = (end - 600).clamp(start, end);
        final candidates = ['\n\n', '。', '\n', '！', '？'];
        for (final marker in candidates) {
          final boundary = text.lastIndexOf(marker, end);
          if (boundary >= lowerBound) {
            end = boundary + marker.length;
            break;
          }
        }
      }
      chunks.add(text.substring(start, end).trim());
      start = end;
    }
    return chunks.where((chunk) => chunk.isNotEmpty).toList();
  }

  static List<Map<String, dynamic>> parseWordObjects(String content) {
    var cleaned = content.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^\x60\x60\x60(?:json)?\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s*\x60\x60\x60$'), '');
    final firstBrace = cleaned.indexOf('{');
    final firstBracket = cleaned.indexOf('[');
    final start =
        firstBracket >= 0 && (firstBrace < 0 || firstBracket < firstBrace)
            ? firstBracket
            : firstBrace;
    if (start > 0) cleaned = cleaned.substring(start);
    if (cleaned.startsWith('{')) {
      final end = cleaned.lastIndexOf('}');
      if (end >= 0) cleaned = cleaned.substring(0, end + 1);
    } else if (cleaned.startsWith('[')) {
      final end = cleaned.lastIndexOf(']');
      if (end >= 0) cleaned = cleaned.substring(0, end + 1);
    }
    final decoded = jsonDecode(cleaned);
    final dynamic list =
        decoded is List ? decoded : (decoded is Map ? decoded['words'] : null);
    if (list is! List) {
      throw const FormatException('模型结果不是 words 数组。');
    }
    return list
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  static String _normalizeField(dynamic value) {
    const allowed = {'通用', '物理', '哲学', '心理学', '工程测量'};
    final field = (value ?? '').toString().trim();
    return allowed.contains(field) ? field : '通用';
  }

  static String _normalizeDifficulty(dynamic value) {
    final difficulty = (value ?? '').toString().trim();
    if (difficulty == '低' || difficulty == '高') return difficulty;
    return '中';
  }

  static String _systemPrompt(int maxTerms) => '''
你是一名中文图书词汇编辑。请从给出的书籍片段中找出所有值得学习的术语、概念、专业词和理解难点，过滤人名、普通虚词和无学习价值的重复词。本段最多返回 $maxTerms 个，宁缺毋滥。

将每个词按理解门槛分为“低 / 中 / 高”，并输出严格 JSON，不要 Markdown，不要额外说明：
{"words":[{"word":"词语","pinyin":"带声调拼音","field":"通用","category":"类型","difficulty":"低","definition":"准确的标准解释","simpleExplanation":"一句小学生能听懂的话","lifeAnalogy":"一个具体生活类比","practicalApplication":"日常或工作中的用途","commonMisconception":"一个最常见误区"}]}

field 只能是：通用、物理、哲学、心理学、工程测量。
difficulty 只能是：低、中、高。
四段详解必须各自具体，不能只是重复 definition，也不能假装书中没有提供的事实一定为真。
''';
}
