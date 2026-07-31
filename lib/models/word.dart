class Word {
  final int id;
  final String word;
  final String pinyin;
  final String field;
  final String difficulty;
  final String pack;
  final String definition;

  const Word({
    required this.id,
    required this.word,
    required this.pinyin,
    required this.field,
    required this.difficulty,
    required this.pack,
    required this.definition,
  });

  /// 从远程词库 JSON 解析（字段缺失时给合理默认值，保证不崩）。
  factory Word.fromJson(Map<String, dynamic> j) => Word(
        id: j['id'] is int ? j['id'] : (j['id']?.hashCode ?? 0),
        word: (j['word'] ?? '').toString(),
        pinyin: (j['pinyin'] ?? '').toString(),
        field: (j['field'] ?? '通用').toString(),
        difficulty: (j['difficulty'] ?? '中').toString(),
        pack: (j['pack'] ?? '').toString(),
        definition: (j['definition'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'pinyin': pinyin,
        'field': field,
        'difficulty': difficulty,
        'pack': pack,
        'definition': definition,
      };
}
