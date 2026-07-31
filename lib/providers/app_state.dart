import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../data/word_bank.dart';

/// 全局应用状态：领域 / 难度 / 词库包筛选、每日名词、历史、收藏。
/// 持久化到 SharedPreferences。
class AppState extends ChangeNotifier {
  // —— 可选项（与词库保持一致，新增包后在此扩展）——
  final List<String> allFields = ['通用', '物理', '哲学', '心理学', '工程测量'];
  final List<String> allDifficulties = ['低', '中', '高'];

  // 词库包（从词库自动汇总，便于设置页展示与开关）
  late final List<String> allPacks;

  // —— 运行时状态 ——
  Set<String> _selectedFields = {'通用', '物理', '哲学', '心理学', '工程测量'};
  String _difficulty = '中';
  Set<String> _enabledPacks = {};
  Set<int> _favorites = {};
  Map<String, HistoryRecord> _history = {};
  bool _loaded = false;

  AppState() {
    allPacks = wordBank.map((w) => w.pack).toSet().toList();
    _enabledPacks = allPacks.toSet(); // 默认全开
  }

  // —— 只读访问 ——
  Set<String> get selectedFields => _selectedFields;
  String get difficulty => _difficulty;
  Set<String> get enabledPacks => _enabledPacks;
  Set<int> get favorites => _favorites;
  Map<String, HistoryRecord> get history => _history;
  bool get loaded => _loaded;

  // —— 调整筛选 ——
  void toggleField(String field) {
    if (_selectedFields.contains(field)) {
      _selectedFields.remove(field);
    } else {
      _selectedFields.add(field);
    }
    _save();
    notifyListeners();
  }

  void setDifficulty(String diff) {
    _difficulty = diff;
    _save();
    notifyListeners();
  }

  void togglePack(String pack) {
    if (_enabledPacks.contains(pack)) {
      _enabledPacks.remove(pack);
    } else {
      _enabledPacks.add(pack);
    }
    _save();
    notifyListeners();
  }

  void setAllFields(bool on) {
    _selectedFields = on ? allFields.toSet() : {};
    _save();
    notifyListeners();
  }

  void setAllPacks(bool on) {
    _enabledPacks = on ? allPacks.toSet() : {};
    _save();
    notifyListeners();
  }

  // —— 收藏 ——
  bool isFavorite(int id) => _favorites.contains(id);

  void toggleFavorite(int id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    _save();
    notifyListeners();
  }

  // —— 历史 ——
  bool isDoneToday() {
    final key = _todayKey();
    return _history.containsKey(key) && _history[key]!.done;
  }

  HistoryRecord? todayRecord() => _history[_todayKey()];

  void saveToday({
    required Word word,
    required String userExplanation,
    required int secondsSpent,
  }) {
    final key = _todayKey();
    _history[key] = HistoryRecord(
      date: key,
      wordId: word.id,
      wordText: word.word,
      field: word.field,
      difficulty: word.difficulty,
      pack: word.pack,
      userExplanation: userExplanation,
      definition: word.definition,
      secondsSpent: secondsSpent,
      done: true,
    );
    _save();
    notifyListeners();
  }

  Word? wordById(int id) {
    try {
      return wordBank.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // —— 每日名词（按日期确定性抽取）——
  Word getTodayWord() {
    var eligible = wordBank
        .where((w) =>
            _selectedFields.contains(w.field) &&
            w.difficulty == _difficulty &&
            _enabledPacks.contains(w.pack))
        .toList();

    // 兜底：当前筛选下无词，放宽难度
    if (eligible.isEmpty) {
      eligible = wordBank
          .where((w) =>
              _selectedFields.contains(w.field) && _enabledPacks.contains(w.pack))
          .toList();
    }
    // 仍为空：用全库，保证永远有词
    if (eligible.isEmpty) eligible = List.from(wordBank);

    final dayIndex = _daysSinceEpoch(DateTime.now());
    final idx = dayIndex % eligible.length;
    return eligible[idx];
  }

  // —— 持久化 ——
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final fields = prefs.getString('selectedFields');
    if (fields != null) _selectedFields = fields.split(',').where((e) => e.isNotEmpty).toSet();
    final diff = prefs.getString('difficulty');
    if (diff != null && allDifficulties.contains(diff)) _difficulty = diff;
    final packs = prefs.getString('enabledPacks');
    if (packs != null) _enabledPacks = packs.split(',').where((e) => e.isNotEmpty).toSet();
    final favs = prefs.getStringList('favorites');
    if (favs != null) _favorites = favs.map((e) => int.parse(e)).toSet();
    final histRaw = prefs.getString('history');
    if (histRaw != null) {
      _history = HistoryRecord.fromJsonString(histRaw);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFields', _selectedFields.join(','));
    await prefs.setString('difficulty', _difficulty);
    await prefs.setString('enabledPacks', _enabledPacks.join(','));
    await prefs.setStringList('favorites', _favorites.map((e) => e.toString()).toList());
    await prefs.setString('history', HistoryRecord.toJsonString(_history));
  }

  // —— 工具 ——
  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  int _daysSinceEpoch(DateTime d) {
    final epoch = DateTime(d.year, d.month, d.day);
    return epoch.difference(DateTime(2020, 1, 1)).inDays;
  }
}

/// 一条历史记录：某天对某个词的思考与对照。
class HistoryRecord {
  final String date;
  final int wordId;
  final String wordText;
  final String field;
  final String difficulty;
  final String pack;
  final String userExplanation;
  final String definition;
  final int secondsSpent;
  final bool done;

  HistoryRecord({
    required this.date,
    required this.wordId,
    required this.wordText,
    required this.field,
    required this.difficulty,
    required this.pack,
    required this.userExplanation,
    required this.definition,
    required this.secondsSpent,
    required this.done,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> j) => HistoryRecord(
        date: j['date'],
        wordId: j['wordId'],
        wordText: j['wordText'],
        field: j['field'],
        difficulty: j['difficulty'],
        pack: j['pack'],
        userExplanation: j['userExplanation'] ?? '',
        definition: j['definition'] ?? '',
        secondsSpent: j['secondsSpent'] ?? 0,
        done: j['done'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'wordId': wordId,
        'wordText': wordText,
        'field': field,
        'difficulty': difficulty,
        'pack': pack,
        'userExplanation': userExplanation,
        'definition': definition,
        'secondsSpent': secondsSpent,
        'done': done,
      };

  static Map<String, HistoryRecord> fromJsonString(String s) {
    final Map<String, dynamic> raw = (jsonDecode(s) as Map<String, dynamic>);
    return raw.map((k, v) => MapEntry(k, HistoryRecord.fromJson(v)));
  }

  static String toJsonString(Map<String, HistoryRecord> map) {
    final out = map.map((k, v) => MapEntry(k, v.toJson()));
    return jsonEncode(out);
  }
}
