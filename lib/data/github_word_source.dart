import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';

/// 从 GitHub raw 地址拉取远程词库。
/// 约定 words.json 为 Word 数组：[{id, word, pinyin, field, difficulty, pack, definition}, ...]
class GithubWordSource {
  /// 拉取并解析远程词库。失败直接抛异常，由调用方决定如何回退。
  static Future<List<Word>> fetch(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('GitHub 返回 HTTP ${res.statusCode}');
    }
    final dynamic data = jsonDecode(res.body);
    if (data is! List) {
      throw Exception('词库格式应为 JSON 数组');
    }
    return data
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
