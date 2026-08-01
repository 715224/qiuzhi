import 'package:flutter_test/flutter_test.dart';
import 'package:qiuzhi/models/word.dart';

void main() {
  test('旧热词可从 ID 推导发布日期并用领域作默认类型', () {
    final word = Word.fromJson({
      'id': 2026080101,
      'word': 'AI安全',
      'field': '通用',
      'pack': '每日热词',
    });

    expect(word.publishedDate, '2026-08-01');
    expect(word.category, '通用');
  });

  test('新热词保留显式日期和类型', () {
    final word = Word.fromJson({
      'id': 1,
      'word': '算力',
      'field': '通用',
      'publishedDate': '2026-08-01',
      'category': '科技',
    });

    expect(word.publishedDate, '2026-08-01');
    expect(word.category, '科技');
  });

  test('详细解释的四个字段可解析和序列化', () {
    final word = Word.fromJson({
      'id': 2,
      'word': '算力',
      'field': '通用',
      'definition': '标准解释不变。',
      'simpleExplanation': '一句话解释。',
      'lifeAnalogy': '生活类比。',
      'practicalApplication': '实际应用。',
      'commonMisconception': '常见误区。',
      'sourceUrl': 'https://www.runoob.com/',
    });

    expect(word.resolvedSimpleExplanation, '一句话解释。');
    expect(word.resolvedLifeAnalogy, '生活类比。');
    expect(word.toJson()['practicalApplication'], '实际应用。');
    expect(word.toJson()['commonMisconception'], '常见误区。');
    expect(word.toJson()['sourceUrl'], 'https://www.runoob.com/');
  });

  test('旧词没有详细字段时仍提供完整兼容内容', () {
    const word = Word(
      id: 3,
      word: '测试词',
      pinyin: '',
      field: '通用',
      difficulty: '中',
      pack: '测试',
      definition: '原有标准解释。',
    );

    expect(word.resolvedSimpleExplanation, '原有标准解释。');
    expect(word.resolvedLifeAnalogy, isNotEmpty);
    expect(word.resolvedPracticalApplication, isNotEmpty);
    expect(word.resolvedCommonMisconception, isNotEmpty);
  });
}
