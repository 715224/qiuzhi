import 'package:flutter_test/flutter_test.dart';
import 'package:qiuzhi/models/word.dart';
import 'package:qiuzhi/providers/app_state.dart';
import 'package:qiuzhi/theme/pixel_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corrupted local cache cannot block app startup', () async {
    SharedPreferences.setMockInitialValues({
      'remoteUrl': '',
      'selectedFields': '通用,不存在的领域',
      'difficulty': '中',
      'enabledPacks': '通用知识包',
      'favorites': <String>['bad-id', '2'],
      'history': '{broken json',
      'remoteWords': '[broken json',
    });

    final state = AppState();
    await state.load();

    expect(state.loaded, isTrue);
    expect(state.selectedFields, {'通用'});
    expect(state.favorites, {2});
    expect(state.history, isEmpty);
    expect(state.remoteWords, isEmpty);
  });

  test('粉色萌物主题可保存并恢复', () async {
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final state = AppState();
    await state.load();

    state.setVisualTheme(AppVisualTheme.pinkMascot);
    await Future<void>.delayed(Duration.zero);

    final restored = AppState();
    await restored.load();
    expect(restored.visualTheme, AppVisualTheme.pinkMascot);
    expect(restored.usesPinkMascot, isTrue);
  });

  test('热词分类方式可保存并恢复', () async {
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final state = AppState();
    await state.load();

    state.setHotwordGrouping(HotwordGrouping.type);
    await Future<void>.delayed(Duration.zero);

    final restored = AppState();
    await restored.load();
    expect(restored.hotwordGrouping, HotwordGrouping.type);
  });

  test('词条编辑和自定义词包可保存', () async {
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final state = AppState();
    await state.load();
    final original = state.wordById(1)!;

    state.saveWordEdit(
      original: original,
      word: '熵（已编辑）',
      pinyin: original.pinyin,
      field: original.field,
      difficulty: original.difficulty,
      pack: original.pack,
      definition: original.definition,
      simpleExplanation: '编辑后的一句话解释。',
      lifeAnalogy: '编辑后的生活类比。',
      practicalApplication: '编辑后的实际应用。',
      commonMisconception: '编辑后的常见误区。',
    );
    state.saveWordEdit(
      word: '自定义测试词',
      pinyin: 'zì dìng yì',
      field: '通用',
      difficulty: '中',
      pack: '我的词包',
      definition: '用于验证自定义词包保存的测试词条。',
    );
    await Future<void>.delayed(Duration.zero);

    final restored = AppState();
    await restored.load();
    expect(restored.wordById(1)!.word, '熵（已编辑）');
    expect(restored.wordById(1)!.simpleExplanation, '编辑后的一句话解释。');
    expect(restored.managedPackNames, contains('我的词包'));
    expect(restored.wordsInPack('我的词包').single.word, '自定义测试词');
  });

  test('AI 批量词条按词包和词名去重保存', () async {
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final state = AppState();
    await state.load();
    const first = Word(
      id: 9001,
      word: '机会成本',
      pinyin: 'jī huì chéng běn',
      field: '通用',
      difficulty: '中',
      pack: '经济学原理',
      definition: '第一版解释。',
    );
    final second = first.copyWith(id: 9002, definition: '更新后的解释。');

    await state.addCustomWords([first, second]);

    expect(state.wordsInPack('经济学原理'), hasLength(1));
    expect(state.wordsInPack('经济学原理').single.definition, '更新后的解释。');
    expect(state.enabledPacks, contains('经济学原理'));
  });

  test('菜鸟教程三级词包逐级包含且档位互斥', () async {
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final state = AppState();
    await state.load();

    final level1 = state.wordsInPack(AppState.runoobPackNames[0]);
    final level2 = state.wordsInPack(AppState.runoobPackNames[1]);
    final level3 = state.wordsInPack(AppState.runoobPackNames[2]);
    expect(level1, hasLength(78));
    expect(level2, hasLength(199));
    expect(level3, hasLength(286));
    expect(
      level3.map((word) => word.category).toSet(),
      containsAll(['算法与数据结构', '代码语法', '常用函数']),
    );
    expect(
      level3.singleWhere((word) => word.word == '动态规划（DP）').definition,
      contains('典型写法'),
    );
    final storedRunoobWords = state.allWords
        .where((word) => AppState.runoobPackNames.contains(word.pack))
        .toList();
    expect(
      storedRunoobWords.map((word) => word.word).toSet(),
      hasLength(storedRunoobWords.length),
    );
    expect(
      level3.singleWhere((word) => word.word == 'JavaScript 可选链').definition,
      contains('user.profile?.name'),
    );
    expect(
      level2.map((word) => word.word).toSet(),
      containsAll(level1.map((word) => word.word)),
    );
    expect(
      level3.map((word) => word.word).toSet(),
      containsAll(level2.map((word) => word.word)),
    );
    expect(state.enabledPacks, contains(AppState.runoobPackNames.first));

    state.togglePack(AppState.runoobPackNames[1]);
    expect(state.enabledPacks, contains(AppState.runoobPackNames[1]));
    expect(
      state.enabledPacks.intersection(AppState.runoobPackNames.toSet()),
      hasLength(1),
    );
  });

  test('北京时间中午十二点切换热词周期', () {
    expect(
      AppState.hotwordPeriodFor(DateTime.utc(2026, 8, 1, 3, 59)),
      '2026-07-31',
    );
    expect(
      AppState.hotwordPeriodFor(DateTime.utc(2026, 8, 1, 4, 0)),
      '2026-08-01',
    );
    expect(
      AppState.hotwordPeriodFor(DateTime.utc(2026, 8, 2, 3, 59)),
      '2026-08-01',
    );
  });

  test('每日目标支持连续学习多个不重复词条', () async {
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final state = AppState();
    await state.load();
    state.setDailyGoal(3);

    final plan = state.getTodayWords();
    expect(plan, hasLength(3));
    expect(plan.map((word) => word.id).toSet(), hasLength(3));
    expect(state.todayCompletedCount, 0);
    expect(state.isDoneToday(), isFalse);

    for (var index = 0; index < plan.length; index++) {
      final current = state.getTodayWord();
      expect(current, isNotNull);
      state.saveToday(
        word: current!,
        userExplanation: '测试解释',
        secondsSpent: 60,
      );
      expect(state.todayCompletedCount, index + 1);
    }

    expect(state.isDoneToday(), isTrue);
    expect(state.totalExperience, 93);
    expect(state.level, 2);
    expect(state.experienceIntoLevel, 13);
    expect(state.experienceToNextLevel, 105);
    await Future<void>.delayed(Duration.zero);
    final restored = AppState();
    await restored.load();
    expect(restored.dailyGoal, 3);
    expect(restored.todayCompletedCount, 3);
  });

  test('经验值按难度和专注时间计算且奖励有上限', () {
    HistoryRecord record(String difficulty, int seconds) => HistoryRecord(
          date: '2026-08-01',
          wordId: 1,
          wordText: '测试',
          field: '通用',
          difficulty: difficulty,
          pack: '测试包',
          userExplanation: '',
          definition: '',
          secondsSpent: seconds,
          done: true,
        );

    expect(AppState.experienceFor(record('低', 0)), 20);
    expect(AppState.experienceFor(record('中', 5 * 60)), 35);
    expect(AppState.experienceFor(record('高', 30 * 60)), 60);
  });

  test('清空学习记录后保留目标主题和自定义词包', () async {
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final state = AppState();
    await state.load();
    state.setDailyGoal(3);
    state.setVisualTheme(AppVisualTheme.pinkMascot);
    state.toggleFavorite(1);
    state.saveToday(
      word: state.wordById(1)!,
      userExplanation: '待清空的学习记录',
      secondsSpent: 60,
    );
    state.saveWordEdit(
      word: '保留的自定义词',
      pinyin: 'bǎo liú',
      field: '通用',
      difficulty: '中',
      pack: '保留词包',
      definition: '清空学习记录后仍应存在。',
    );

    await state.clearLearningData();
    final restored = AppState();
    await restored.load();

    expect(restored.history, isEmpty);
    expect(restored.favorites, isEmpty);
    expect(restored.totalExperience, 0);
    expect(restored.level, 1);
    expect(restored.dailyGoal, 3);
    expect(restored.visualTheme, AppVisualTheme.pinkMascot);
    expect(restored.wordsInPack('保留词包').single.word, '保留的自定义词');
  });
}
