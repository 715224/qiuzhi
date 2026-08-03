class Word {
  final int id;
  final String word;
  final String pinyin;
  final String field;
  final String difficulty;
  final String pack;
  final String definition;
  final String publishedDate;
  final String category;
  final String simpleExplanation;
  final String lifeAnalogy;
  final String practicalApplication;
  final String commonMisconception;
  final String sourceUrl;

  const Word({
    required this.id,
    required this.word,
    required this.pinyin,
    required this.field,
    required this.difficulty,
    required this.pack,
    required this.definition,
    this.publishedDate = '',
    this.category = '',
    this.simpleExplanation = '',
    this.lifeAnalogy = '',
    this.practicalApplication = '',
    this.commonMisconception = '',
    this.sourceUrl = '',
  });

  /// 从远程词库 JSON 解析（字段缺失时给合理默认值，保证不崩）。
  factory Word.fromJson(Map<String, dynamic> j) {
    final wordStr = _repairKnownEncodingDamage((j['word'] ?? '').toString());
    final packStr = _repairKnownEncodingDamage((j['pack'] ?? '').toString());
    final rawId = j['id'];
    int id;
    if (rawId is int) {
      id = rawId;
    } else if (rawId is num) {
      id = rawId.toInt();
    } else if (rawId is String && int.tryParse(rawId) != null) {
      id = int.parse(rawId);
    } else if (rawId == null || rawId == 0) {
      // 缺失 id：基于 word+pack 生成稳定 id，避免多条都落到 0 互相覆盖。
      id = '$wordStr\u0000$packStr'.hashCode;
    } else {
      id = rawId.hashCode;
    }
    final field = _repairKnownEncodingDamage((j['field'] ?? '通用').toString());
    return Word(
      id: id,
      word: wordStr,
      pinyin: _repairKnownEncodingDamage((j['pinyin'] ?? '').toString()),
      field: field,
      difficulty:
          _repairKnownEncodingDamage((j['difficulty'] ?? '中').toString()),
      pack: packStr,
      definition: _repairKnownEncodingDamage(
        (j['definition'] ?? '').toString(),
      ),
      publishedDate: (j['publishedDate'] ?? _dateFromId(id)).toString(),
      category: _repairKnownEncodingDamage(
        (j['category'] ?? field).toString(),
      ),
      simpleExplanation: _repairKnownEncodingDamage(
        (j['simpleExplanation'] ?? '').toString(),
      ),
      lifeAnalogy: _repairKnownEncodingDamage(
        (j['lifeAnalogy'] ?? '').toString(),
      ),
      practicalApplication: _repairKnownEncodingDamage(
        (j['practicalApplication'] ?? '').toString(),
      ),
      commonMisconception: _repairKnownEncodingDamage(
        (j['commonMisconception'] ?? '').toString(),
      ),
      sourceUrl: (j['sourceUrl'] ?? '').toString(),
    );
  }

  /// 修复旧版热词缓存中已经确认的 UTF-8 损坏片段，让已安装版本升级后
  /// 即使暂时离线也不会继续显示替换符号。
  static String _repairKnownEncodingDamage(String value) => value
      .replaceAll('��康', '健康')
      .replaceAll('��经', '财经')
      .replaceAll('折扣��把', '折扣价，把')
      .replaceAll('堆细��，', '堆细节，')
      .replaceAll('交��一段', '交易一段');

  static String _dateFromId(int id) {
    final value = id.toString();
    if (value.length < 8) return '';
    final year = value.substring(0, 4);
    final month = value.substring(4, 6);
    final day = value.substring(6, 8);
    if (int.tryParse(year) == null ||
        int.tryParse(month) == null ||
        int.tryParse(day) == null) {
      return '';
    }
    return '$year-$month-$day';
  }

  Word copyWith({
    int? id,
    String? word,
    String? pinyin,
    String? field,
    String? difficulty,
    String? pack,
    String? definition,
    String? publishedDate,
    String? category,
    String? simpleExplanation,
    String? lifeAnalogy,
    String? practicalApplication,
    String? commonMisconception,
    String? sourceUrl,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      pinyin: pinyin ?? this.pinyin,
      field: field ?? this.field,
      difficulty: difficulty ?? this.difficulty,
      pack: pack ?? this.pack,
      definition: definition ?? this.definition,
      publishedDate: publishedDate ?? this.publishedDate,
      category: category ?? this.category,
      simpleExplanation: simpleExplanation ?? this.simpleExplanation,
      lifeAnalogy: lifeAnalogy ?? this.lifeAnalogy,
      practicalApplication: practicalApplication ?? this.practicalApplication,
      commonMisconception: commonMisconception ?? this.commonMisconception,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }

  String get resolvedSimpleExplanation =>
      simpleExplanation.trim().isNotEmpty ? simpleExplanation : definition;

  String get resolvedLifeAnalogy => lifeAnalogy.trim().isNotEmpty
      ? lifeAnalogy
      : '可以把“$word”想成生活中的一种规则或工具：$definition';

  String get resolvedPracticalApplication =>
      practicalApplication.trim().isNotEmpty
          ? practicalApplication
          : '它常用于理解或处理与“$field”相关的问题，掌握后能更准确地判断、表达和应用这个概念。';

  String get resolvedCommonMisconception =>
      commonMisconception.trim().isNotEmpty
          ? commonMisconception
          : '不要只记住名称，也不要把它套用到所有场景；应结合定义中的条件和边界来判断。';

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'pinyin': pinyin,
        'field': field,
        'difficulty': difficulty,
        'pack': pack,
        'definition': definition,
        if (publishedDate.isNotEmpty) 'publishedDate': publishedDate,
        if (category.isNotEmpty) 'category': category,
        if (simpleExplanation.isNotEmpty)
          'simpleExplanation': simpleExplanation,
        if (lifeAnalogy.isNotEmpty) 'lifeAnalogy': lifeAnalogy,
        if (practicalApplication.isNotEmpty)
          'practicalApplication': practicalApplication,
        if (commonMisconception.isNotEmpty)
          'commonMisconception': commonMisconception,
        if (sourceUrl.isNotEmpty) 'sourceUrl': sourceUrl,
      };
}
