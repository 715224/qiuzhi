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
}
