import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qiuzhi/services/ai_book_service.dart';

void main() {
  test('AI 接口地址可兼容 base URL、v1 和完整地址', () {
    expect(
      const AiModelConfig(
        endpoint: 'https://example.com',
        model: 'demo',
      ).chatCompletionsUrl,
      'https://example.com/v1/chat/completions',
    );
    expect(
      const AiModelConfig(
        endpoint: 'https://example.com/v1',
        model: 'demo',
      ).chatCompletionsUrl,
      'https://example.com/v1/chat/completions',
    );
  });

  test('模型 JSON 结果可生成带四段详解的分级自定义词', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer secret');
      final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      expect(requestBody['model'], 'test-model');
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'words': [
                    {
                      'word': '机会成本',
                      'pinyin': 'jī huì chéng běn',
                      'field': '通用',
                      'category': '经济',
                      'difficulty': '中',
                      'definition': '选择一种方案时放弃的最佳替代方案的价值。',
                      'simpleExplanation': '选了一个，就会失去另一个最好的选择。',
                      'lifeAnalogy': '晚上看电影，就放弃了同一时间读书。',
                      'practicalApplication': '帮助比较时间和金钱的不同用法。',
                      'commonMisconception': '它不只是实际花出去的钱。'
                    }
                  ]
                })
              }
            }
          ]
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final words = await AiBookService(client: client).extractBook(
      config: const AiModelConfig(
        endpoint: 'https://example.com/v1',
        model: 'test-model',
        apiKey: 'secret',
        chunkSize: 12000,
      ),
      bookText: List.filled(20, '这是一段用于解释经济选择与机会成本的书籍正文。').join(),
      packName: '经济学原理',
    );

    expect(words, hasLength(1));
    expect(words.single.pack, '经济学原理');
    expect(words.single.difficulty, '中');
    expect(words.single.simpleExplanation, isNotEmpty);
    expect(words.single.lifeAnalogy, isNotEmpty);
    expect(words.single.practicalApplication, isNotEmpty);
    expect(words.single.commonMisconception, isNotEmpty);
  });
}
