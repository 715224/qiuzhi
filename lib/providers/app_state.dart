import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../data/word_bank.dart';
import '../data/github_word_source.dart';
import '../theme/pixel_theme.dart';

enum HotwordGrouping { time, type }

extension HotwordGroupingInfo on HotwordGrouping {
  String get label => this == HotwordGrouping.time ? '按时间' : '按类型';
}

/// 全局应用状态：领域 / 难度 / 词库包筛选、每日名词、历史、收藏。
/// 持久化到 SharedPreferences。
class AppState extends ChangeNotifier {
  // —— 可选项（与词库保持一致，新增包后在此扩展）——
  final List<String> allFields = ['通用', '物理', '哲学', '心理学', '工程测量'];
  final List<String> allDifficulties = ['低', '中', '高'];

  /// 远程「每日热词」词库包名（与 GitHub 拉取的 pack 字段对应）。
  static const String remotePackName = '每日热词';
  static const String defaultRemoteUrl = 'https://github.com/715224/qiuzhi';
  static const List<String> runoobPackNames = [
    '菜鸟教程词汇包·一级（基础）',
    '菜鸟教程词汇包·二级（进阶）',
    '菜鸟教程词汇包·三级（完整）',
  ];

  // 词库包（从词库自动汇总，便于设置页展示与开关）
  late final List<String> allPacks;

  // —— 运行时状态 ——
  Set<String> _selectedFields = {'通用', '物理', '哲学', '心理学', '工程测量'};
  String _difficulty = '中';
  int _dailyGoal = 1;
  Set<String> _enabledPacks = {};
  Set<int> _favorites = {};
  Map<String, HistoryRecord> _history = {};
  bool _loaded = false;
  String? _storageError;
  AppVisualTheme _visualTheme = AppVisualTheme.cyanPixel;
  HotwordGrouping _hotwordGrouping = HotwordGrouping.time;

  // —— 远程词库（从 GitHub 拉取，本地缓存）——
  String _remoteUrl = defaultRemoteUrl;
  List<Word> _remoteWords = [];
  Map<int, Word> _wordOverrides = {};
  List<Word> _customWords = [];
  List<Word> _bundledPackWords = [];
  DateTime? _remoteUpdatedAt;
  String? _remoteError;
  bool _remoteRefreshing = false;
  String _lastHotwordPeriod = '';

  AppState() {
    allPacks = wordBank.map((w) => w.pack).toSet().toList();
    _enabledPacks = allPacks.toSet(); // 默认全开
  }

  // —— 只读访问 ——
  Set<String> get selectedFields => _selectedFields;
  String get difficulty => _difficulty;
  int get dailyGoal => _dailyGoal;
  Set<String> get enabledPacks => _enabledPacks;
  Set<int> get favorites => _favorites;
  Map<String, HistoryRecord> get history => _history;
  bool get loaded => _loaded;
  String? get storageError => _storageError;
  AppVisualTheme get visualTheme => _visualTheme;
  bool get usesPinkMascot => _visualTheme == AppVisualTheme.pinkMascot;
  HotwordGrouping get hotwordGrouping => _hotwordGrouping;

  void setVisualTheme(AppVisualTheme theme) {
    if (_visualTheme == theme) return;
    _visualTheme = theme;
    _save();
    notifyListeners();
  }

  void setHotwordGrouping(HotwordGrouping grouping) {
    if (_hotwordGrouping == grouping) return;
    _hotwordGrouping = grouping;
    _save();
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    final normalized = goal.clamp(1, 20);
    if (_dailyGoal == normalized) return;
    _dailyGoal = normalized;
    _save();
    notifyListeners();
  }

  // —— 远程词库只读访问 ——
  String get remoteUrl => _remoteUrl;
  List<Word> get remoteWords => _applyWordEdits(_remoteWords);
  DateTime? get remoteUpdatedAt => _remoteUpdatedAt;
  String? get remoteError => _remoteError;
  bool get remoteRefreshing => _remoteRefreshing;
  bool get hasRemoteConfig => _remoteUrl.trim().isNotEmpty;
  String get currentHotwordPeriod => hotwordPeriodFor(DateTime.now());
  bool get hotwordRefreshDue =>
      hasRemoteConfig && _lastHotwordPeriod != currentHotwordPeriod;

  /// 北京时间每天 12:00 切换热词日；中午前仍属于前一日周期。
  static String hotwordPeriodFor(DateTime instant) {
    final china = instant.toUtc().add(const Duration(hours: 8));
    final periodDate =
        china.hour < 12 ? china.subtract(const Duration(days: 1)) : china;
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${periodDate.year}-${pad(periodDate.month)}-${pad(periodDate.day)}';
  }

  /// 设置页展示的包列表：本地包 + 远程包。
  List<String> get displayPacks => managedPackNames;

  List<String> get managedPackNames {
    final packs = allWords
        .map((word) => word.pack.trim())
        .where((pack) => pack.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return packs;
  }

  List<Word> wordsInPack(String pack) {
    final selectedLevel = runoobPackNames.indexOf(pack);
    final words = allWords.where((word) {
      if (selectedLevel < 0) return word.pack == pack;
      final wordLevel = runoobPackNames.indexOf(word.pack);
      return wordLevel >= 0 && wordLevel <= selectedLevel;
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return words;
  }

  /// 菜鸟教程词汇只保存一次：选择二/三级时，逻辑上同时包含更低级词汇。
  bool isWordInEnabledPack(Word word) {
    final wordLevel = runoobPackNames.indexOf(word.pack);
    if (wordLevel < 0) return _enabledPacks.contains(word.pack);
    final selectedLevel = runoobPackNames.indexWhere(_enabledPacks.contains);
    return selectedLevel >= wordLevel;
  }

  /// 某个包的名词数量（含远程包）。
  int packCount(String pack) {
    return wordsInPack(pack).length;
  }

  bool isWordEdited(int id) => _wordOverrides.containsKey(id);
  bool isCustomWord(int id) => _customWords.any((word) => word.id == id);

  /// 将 AI 或其他批量来源生成的词条一次性写入自定义词包。
  /// 同一词包内同名词会更新，不会产生重复项。
  Future<int> addCustomWords(List<Word> words) async {
    if (words.isEmpty) return 0;
    final touched = <String>{};
    for (final word in words) {
      final pack = word.pack.trim();
      final name = word.word.trim();
      if (pack.isEmpty || name.isEmpty || word.definition.trim().isEmpty) {
        continue;
      }
      final index = _customWords.indexWhere(
        (item) => item.pack == pack && item.word == name,
      );
      final normalized = word.copyWith(word: name, pack: pack);
      if (index >= 0) {
        _customWords[index] = normalized.copyWith(id: _customWords[index].id);
      } else {
        _customWords.add(normalized);
      }
      _enabledPacks.add(pack);
      touched.add('$pack\u0000$name');
    }
    if (touched.isNotEmpty) {
      await _save();
      notifyListeners();
    }
    return touched.length;
  }

  void saveWordEdit({
    Word? original,
    required String word,
    required String pinyin,
    required String field,
    required String difficulty,
    required String pack,
    required String definition,
    String publishedDate = '',
    String category = '',
    String simpleExplanation = '',
    String lifeAnalogy = '',
    String practicalApplication = '',
    String commonMisconception = '',
  }) {
    final normalizedPack = pack.trim();
    final edited = Word(
      id: original?.id ?? DateTime.now().microsecondsSinceEpoch,
      word: word.trim(),
      pinyin: pinyin.trim(),
      field: field,
      difficulty: difficulty,
      pack: normalizedPack,
      definition: definition.trim(),
      publishedDate: publishedDate.trim(),
      category: category.trim().isEmpty ? field : category.trim(),
      simpleExplanation: simpleExplanation.trim(),
      lifeAnalogy: lifeAnalogy.trim(),
      practicalApplication: practicalApplication.trim(),
      commonMisconception: commonMisconception.trim(),
      sourceUrl: original?.sourceUrl ?? '',
    );

    final customIndex = _customWords.indexWhere((item) => item.id == edited.id);
    if (customIndex >= 0) {
      _customWords[customIndex] = edited;
    } else if (original == null) {
      // 同包同名已存在则更新，避免重复词条。
      final dupIndex = _customWords.indexWhere(
        (item) => item.pack == edited.pack && item.word == edited.word,
      );
      if (dupIndex >= 0) {
        _customWords[dupIndex] = edited.copyWith(id: _customWords[dupIndex].id);
      } else {
        _customWords.add(edited);
      }
    } else {
      _wordOverrides[edited.id] = edited;
    }
    _enabledPacks.add(normalizedPack);
    _save();
    notifyListeners();
  }

  void restoreWord(int id) {
    if (_wordOverrides.remove(id) != null) {
      _save();
      notifyListeners();
    }
  }

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
    if (runoobPackNames.contains(pack)) {
      final wasEnabled = _enabledPacks.contains(pack);
      _enabledPacks.removeAll(runoobPackNames);
      if (!wasEnabled) _enabledPacks.add(pack);
      _save();
      notifyListeners();
      return;
    }
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
    _enabledPacks = on ? managedPackNames.toSet() : {};
    if (on) {
      _enabledPacks.removeAll(runoobPackNames);
      _enabledPacks.add(runoobPackNames.last);
    }
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
    return todayCompletedCount >= todayTargetCount;
  }

  List<HistoryRecord> todayRecords() {
    final today = _todayKey();
    return _history.values
        .where((record) => record.date == today && record.done)
        .toList(growable: false);
  }

  int get todayCompletedCount => todayRecords().length;
  int get todayTargetCount => getTodayWords().length;

  int get totalExperience => _history.values
      .where((record) => record.done)
      .fold(0, (total, record) => total + experienceFor(record));

  static int experienceFor(HistoryRecord record) {
    final difficultyXp = switch (record.difficulty) {
      '高' => 45,
      '中' => 30,
      _ => 20,
    };
    final focusBonus = (record.secondsSpent ~/ 60).clamp(0, 15);
    return difficultyXp + focusBonus;
  }

  int get level {
    var remaining = totalExperience;
    var current = 1;
    while (remaining >= experienceNeededForLevel(current)) {
      remaining -= experienceNeededForLevel(current);
      current++;
    }
    return current;
  }

  int get experienceIntoLevel {
    var remaining = totalExperience;
    var current = 1;
    while (remaining >= experienceNeededForLevel(current)) {
      remaining -= experienceNeededForLevel(current);
      current++;
    }
    return remaining;
  }

  int get experienceToNextLevel => experienceNeededForLevel(level);
  double get levelProgress => experienceIntoLevel / experienceToNextLevel;

  static int experienceNeededForLevel(int level) => 80 + (level - 1) * 25;

  String get levelTitle {
    final current = level;
    if (current >= 20) return '思想大师';
    if (current >= 15) return '求知达人';
    if (current >= 10) return '知识行者';
    if (current >= 6) return '概念猎手';
    if (current >= 3) return '探索学徒';
    return '求知新芽';
  }

  HistoryRecord? todayRecord() {
    final records = todayRecords();
    return records.isEmpty ? null : records.last;
  }

  void saveToday({
    required Word word,
    required String userExplanation,
    required int secondsSpent,
  }) {
    final today = _todayKey();
    String? existing;
    for (final entry in _history.entries) {
      if (entry.value.date == today && entry.value.wordId == word.id) {
        existing = entry.key;
        break;
      }
    }
    final key = existing ?? '$today#${word.id}';
    _history[key] = HistoryRecord(
      date: today,
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
      return allWords.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // —— 每日名词（按日期确定性抽取）——
  /// 所有可用名词：本地词库 + 已拉取的远程词库。
  List<Word> get allWords => _applyWordEdits([
        ...wordBank,
        ..._bundledPackWords,
        ..._remoteWords,
        ..._customWords,
      ]);

  Word? getTodayWord() {
    final plan = getTodayWords();
    if (plan.isEmpty) return null;
    final records = todayRecords();
    if (records.length >= plan.length && records.isNotEmpty) {
      return wordById(records.last.wordId) ?? plan.last;
    }
    final completedIds = records.map((record) => record.wordId).toSet();
    return plan.firstWhere(
      (word) => !completedIds.contains(word.id),
      orElse: () => plan.last,
    );
  }

  List<Word> getTodayWords() {
    var eligible = allWords
        .where((w) =>
            _selectedFields.contains(w.field) &&
            w.difficulty == _difficulty &&
            isWordInEnabledPack(w))
        .toList();

    // 兜底：当前筛选下无词，放宽难度
    if (eligible.isEmpty) {
      eligible = allWords
          .where((w) =>
              _selectedFields.contains(w.field) && isWordInEnabledPack(w))
          .toList();
    }
    // 词数不足时从全库补齐，保证每日目标可完成。
    if (eligible.length < _dailyGoal) {
      final ids = eligible.map((word) => word.id).toSet();
      eligible.addAll(allWords.where((word) => ids.add(word.id)));
    }
    if (eligible.isEmpty) eligible = List.from(allWords);
    if (eligible.isEmpty) return const []; // 词库全空，避免除零崩溃

    final dayIndex = _daysSinceEpoch(DateTime.now());
    final start = dayIndex % eligible.length;
    final count = _dailyGoal < eligible.length ? _dailyGoal : eligible.length;
    return List.generate(
      count,
      (index) => eligible[(start + index) % eligible.length],
      growable: false,
    );
  }

  // —— 远程词库配置与刷新 ——
  void setRemoteUrl(String url) {
    _remoteUrl = url.trim();
    _lastHotwordPeriod = '';
    if (_remoteUrl.isNotEmpty) _enabledPacks.add(remotePackName); // 启用即默认勾选
    _save();
    notifyListeners();
    // 配置后立即拉取一次
    unawaited(refreshRemote());
  }

  /// 从 GitHub 拉取最新热词；失败则保留上一次缓存（断网可用）。
  Future<void> refreshRemote() async {
    if (_remoteUrl.trim().isEmpty || _remoteRefreshing) return;
    _remoteRefreshing = true;
    _remoteError = null;
    notifyListeners();
    try {
      final expectedPeriod = currentHotwordPeriod;
      final words = await GithubWordSource.fetch(
        _remoteUrl,
        requiredPublishedDate: expectedPeriod,
      );
      final merged = <int, Word>{
        for (final word in _remoteWords) word.id: word,
      };
      for (final word in words) {
        final cached = merged[word.id];
        merged[word.id] = cached == null ? word : _mergeHotword(cached, word);
      }
      _remoteWords = merged.values.toList()
        ..sort((a, b) {
          final byDate = b.publishedDate.compareTo(a.publishedDate);
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        });
      _remoteUpdatedAt = DateTime.now();
      // 只有远端确实包含当前北京时间周期的数据，才停止当天自动重试。
      _lastHotwordPeriod = expectedPeriod;
      _remoteError = null;
    } catch (e) {
      _remoteError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _remoteRefreshing = false;
      _save();
      notifyListeners();
    }
  }

  /// App 启动或重新进入前台时调用。同一中午周期只自动更新一次。
  Future<void> refreshRemoteIfDue() async {
    if (!_loaded || !hotwordRefreshDue || _remoteRefreshing) return;
    await refreshRemote();
  }

  // —— 持久化 ——
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _storageError = null;

      try {
        final bundled = await rootBundle.loadString(
          'assets/word_packs/runoob.json',
        );
        _bundledPackWords = (jsonDecode(bundled) as List)
            .whereType<Map<String, dynamic>>()
            .map(Word.fromJson)
            .where((word) => word.word.isNotEmpty && word.pack.isNotEmpty)
            .toList();
      } catch (_) {
        _bundledPackWords = [];
      }

      final fields = prefs.getString('selectedFields');
      if (fields != null) {
        _selectedFields = fields
            .split(',')
            .where((field) => allFields.contains(field))
            .toSet();
      }

      final diff = prefs.getString('difficulty');
      if (diff != null && allDifficulties.contains(diff)) _difficulty = diff;

      _dailyGoal = (prefs.getInt('dailyGoal') ?? 1).clamp(1, 20);

      final visualTheme = prefs.getString('visualTheme');
      _visualTheme = AppVisualTheme.values.firstWhere(
        (theme) => theme.storageValue == visualTheme,
        orElse: () => AppVisualTheme.cyanPixel,
      );

      final hotwordGrouping = prefs.getString('hotwordGrouping');
      _hotwordGrouping = HotwordGrouping.values.firstWhere(
        (grouping) => grouping.name == hotwordGrouping,
        orElse: () => HotwordGrouping.time,
      );

      final packs = prefs.getString('enabledPacks');
      if (packs != null) {
        _enabledPacks = packs.split(',').where((e) => e.isNotEmpty).toSet();
      } else if (_bundledPackWords.isNotEmpty) {
        _enabledPacks.add(runoobPackNames.first);
      }

      final favs = prefs.getStringList('favorites');
      if (favs != null) {
        _favorites = favs.map(int.tryParse).whereType<int>().toSet();
      }

      final histRaw = prefs.getString('history');
      if (histRaw != null && histRaw.isNotEmpty) {
        try {
          _history = HistoryRecord.fromJsonString(histRaw);
        } on FormatException {
          _history = {};
        } on TypeError {
          _history = {};
        }
      }

      // 远程词库配置 + 上次缓存（断网也能用）。
      final remoteUrl = prefs.getString('remoteUrl');
      if (remoteUrl != null) _remoteUrl = remoteUrl;
      _lastHotwordPeriod = prefs.getString('lastHotwordPeriod') ?? '';

      final remoteRaw = prefs.getString('remoteWords');
      if (remoteRaw != null && remoteRaw.isNotEmpty) {
        try {
          _remoteWords = (jsonDecode(remoteRaw) as List)
              .whereType<Map<String, dynamic>>()
              .map(Word.fromJson)
              .where((word) => word.word.isNotEmpty)
              .toList();
        } on FormatException {
          _remoteWords = [];
        } on TypeError {
          _remoteWords = [];
        }
      }

      // 首次安装或尚未成功联网时，先载入随 APK 发布的热词总库。
      if (remoteRaw == null) {
        try {
          final bundled = await rootBundle.loadString(
            'daily_hotwords/library.json',
          );
          _remoteWords = (jsonDecode(bundled) as List)
              .whereType<Map<String, dynamic>>()
              .map(Word.fromJson)
              .where((word) => word.word.isNotEmpty)
              .toList();
        } catch (_) {
          // 内置库仅是离线保障，读取失败不能阻断 App 启动。
        }
      }

      final remoteAt = prefs.getString('remoteUpdatedAt');
      if (remoteAt != null && remoteAt.isNotEmpty) {
        _remoteUpdatedAt = DateTime.tryParse(remoteAt);
      }

      final overridesRaw = prefs.getString('wordOverrides');
      if (overridesRaw != null && overridesRaw.isNotEmpty) {
        try {
          _wordOverrides = {
            for (final item in (jsonDecode(overridesRaw) as List)
                .whereType<Map<String, dynamic>>()
                .map(Word.fromJson))
              item.id: item,
          };
        } catch (_) {
          _wordOverrides = {};
        }
      }

      final customRaw = prefs.getString('customWords');
      if (customRaw != null && customRaw.isNotEmpty) {
        try {
          _customWords = (jsonDecode(customRaw) as List)
              .whereType<Map<String, dynamic>>()
              .map(Word.fromJson)
              .where((word) => word.word.isNotEmpty && word.pack.isNotEmpty)
              .toList();
        } catch (_) {
          _customWords = [];
        }
      }
    } catch (error) {
      // 使用构造函数中的默认设置继续运行，绝不能阻断 Flutter 首帧。
      _storageError = error.toString();
    } finally {
      _loaded = true;
      notifyListeners();
    }

    // 按北京时间中午分界静默刷新；失败不记周期，下次进入继续重试。
    unawaited(refreshRemoteIfDue());
  }

  Future<void>? _saveInFlight;

  /// 串行化持久化，避免并发写入造成字段互相覆盖的竞态。
  Future<void> _save() {
    final next = (_saveInFlight == null
        ? _doSave()
        : _saveInFlight!.then((_) => _doSave()));
    _saveInFlight = next;
    next.whenComplete(() {
      if (identical(_saveInFlight, next)) _saveInFlight = null;
    });
    return next;
  }

  Future<void> _doSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedFields', _selectedFields.join(','));
      await prefs.setString('difficulty', _difficulty);
      await prefs.setInt('dailyGoal', _dailyGoal);
      await prefs.setString('visualTheme', _visualTheme.storageValue);
      await prefs.setString('hotwordGrouping', _hotwordGrouping.name);
      await prefs.setString('enabledPacks', _enabledPacks.join(','));
      await prefs.setStringList(
          'favorites', _favorites.map((e) => e.toString()).toList());
      await prefs.setString('history', HistoryRecord.toJsonString(_history));
      await prefs.setString('remoteUrl', _remoteUrl);
      await prefs.setString('remoteWords',
          jsonEncode(_remoteWords.map((w) => w.toJson()).toList()));
      await prefs.setString(
          'remoteUpdatedAt', _remoteUpdatedAt?.toIso8601String() ?? '');
      await prefs.setString('lastHotwordPeriod', _lastHotwordPeriod);
      await prefs.setString(
        'wordOverrides',
        jsonEncode(_wordOverrides.values.map((word) => word.toJson()).toList()),
      );
      await prefs.setString(
        'customWords',
        jsonEncode(_customWords.map((word) => word.toJson()).toList()),
      );
      _storageError = null;
    } catch (error) {
      _storageError = error.toString();
    }
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

  Word _mergeHotword(Word cached, Word incoming) {
    final incomingHasSpecificCategory =
        incoming.category.isNotEmpty && incoming.category != incoming.field;
    return Word(
      id: incoming.id,
      word: incoming.word.isNotEmpty ? incoming.word : cached.word,
      pinyin: incoming.pinyin.isNotEmpty ? incoming.pinyin : cached.pinyin,
      field: incoming.field.isNotEmpty ? incoming.field : cached.field,
      difficulty: incoming.difficulty.isNotEmpty
          ? incoming.difficulty
          : cached.difficulty,
      pack: incoming.pack.isNotEmpty ? incoming.pack : cached.pack,
      definition: incoming.definition.isNotEmpty
          ? incoming.definition
          : cached.definition,
      publishedDate: incoming.publishedDate.isNotEmpty
          ? incoming.publishedDate
          : cached.publishedDate,
      category: incomingHasSpecificCategory
          ? incoming.category
          : (cached.category.isNotEmpty ? cached.category : incoming.category),
      simpleExplanation: incoming.simpleExplanation.isNotEmpty
          ? incoming.simpleExplanation
          : cached.simpleExplanation,
      lifeAnalogy: incoming.lifeAnalogy.isNotEmpty
          ? incoming.lifeAnalogy
          : cached.lifeAnalogy,
      practicalApplication: incoming.practicalApplication.isNotEmpty
          ? incoming.practicalApplication
          : cached.practicalApplication,
      commonMisconception: incoming.commonMisconception.isNotEmpty
          ? incoming.commonMisconception
          : cached.commonMisconception,
      sourceUrl:
          incoming.sourceUrl.isNotEmpty ? incoming.sourceUrl : cached.sourceUrl,
    );
  }

  List<Word> _applyWordEdits(Iterable<Word> source) {
    return source
        .map((word) => _wordOverrides[word.id] ?? word)
        .toList(growable: false);
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
        date: (j['date'] ?? '').toString(),
        wordId: j['wordId'] is int
            ? j['wordId'] as int
            : (int.tryParse('${j['wordId']}') ?? 0),
        wordText: (j['wordText'] ?? '').toString(),
        field: (j['field'] ?? '').toString(),
        difficulty: (j['difficulty'] ?? '').toString(),
        pack: (j['pack'] ?? '').toString(),
        userExplanation: (j['userExplanation'] ?? '').toString(),
        definition: (j['definition'] ?? '').toString(),
        secondsSpent: j['secondsSpent'] is int
            ? j['secondsSpent'] as int
            : (int.tryParse('${j['secondsSpent']}') ?? 0),
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
    final out = <String, HistoryRecord>{};
    raw.forEach((k, v) {
      // 逐条解析：单条损坏仅跳过该条，不影响其余历史。
      if (v is Map<String, dynamic>) {
        try {
          out[k] = HistoryRecord.fromJson(v);
        } catch (_) {
          // 跳过损坏记录
        }
      }
    });
    return out;
  }

  static String toJsonString(Map<String, HistoryRecord> map) {
    final out = map.map((k, v) => MapEntry(k, v.toJson()));
    return jsonEncode(out);
  }
}
