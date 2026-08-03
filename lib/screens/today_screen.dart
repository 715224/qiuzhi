import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'focus_screen.dart';
import 'result_screen.dart';
import 'word_detail_screen.dart';

/// 今日名词页：像素风每日任务面板。
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with TickerProviderStateMixin {
  final _random = Random();
  bool _drawing = false;
  int? _revealedWordId;
  Word? _rollingWord;

  /// 抽取时吉祥物晃动动画控制器。
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // 用 sine 波形驱动左右晃动 + 轻微旋转，循环播放更自然。
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _drawWord(AppState app) async {
    if (_drawing) return;
    final target = app.getTodayWord();
    if (target == null) return; // 词库为空，无法抽取
    final pool = app.allWords
        .where(
          (word) =>
              app.selectedFields.contains(word.field) &&
              app.isWordInEnabledPack(word),
        )
        .toList();
    if (pool.isEmpty) pool.add(target);

    // 启动晃动动画 + 滚动音效
    _shakeController.repeat();
    try {
      SoundService.instance.playDrawRoll();
    } catch (_) {}

    setState(() {
      _drawing = true;
      _rollingWord = pool[_random.nextInt(pool.length)];
    });

    const frames = 22;
    for (var frame = 0; frame < frames; frame++) {
      await Future<void>.delayed(
        Duration(milliseconds: 45 + frame * 5),
      );
      if (!mounted) return;
      setState(() {
        _rollingWord =
            frame == frames - 1 ? target : pool[_random.nextInt(pool.length)];
      });
    }

    // 停止晃动动画 + 滚动音效，播放揭晓音效
    _shakeController.stop();
    _shakeController.value = 0;
    try {
      SoundService.instance.stopDrawRoll();
    } catch (_) {}
    try {
      SoundService.instance.playReveal();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _drawing = false;
      _revealedWordId = target.id;
      _rollingWord = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final palette = context.pixelPalette;
    final word = app.getTodayWord();
    if (word == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '词库为空，请在「我的」中开启词包或导入远程词库后再来。',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }
    final done = app.isDoneToday();
    final record = app.todayRecord();
    final completed = app.todayCompletedCount;
    final target = app.todayTargetCount;
    final progress = target == 0 ? 0.0 : completed / target;
    final revealed = done || _revealedWordId == word.id;
    final displayWord = _drawing ? (_rollingWord ?? word) : word;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelPageTitle(
                title: '求知',
                subtitle: done ? 'DAILY QUEST · CLEAR' : 'DAILY QUEST · READY',
                trailing: _TodayPlanButton(
                  completed: completed,
                  target: target,
                  onTap: () => _showTodayPlan(context),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        _LevelPanel(
                          app: app,
                          onTap: () => _showLevelGuide(context),
                        ),
                        const SizedBox(height: 12),
                        _RangePanel(
                          app: app,
                          onTap: () => _showRangeSheet(context),
                        ),
                        const SizedBox(height: 16),
                        _AnimatedMascot(
                          drawing: _drawing,
                          shakeAnimation: _shakeAnimation,
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 90),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Text(
                            _drawing
                                ? displayWord.word
                                : (revealed ? word.word : '???'),
                            key: ValueKey(
                              _drawing
                                  ? displayWord.id
                                  : (revealed ? word.id : -1),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 44,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _drawing
                              ? '词库检索中 · 正在抽取'
                              : (revealed ? word.pinyin : '点击下方按钮抽取今日词语'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _drawing
                              ? '候选词快速滚动中，请稍候…'
                              : done
                                  ? '今日 $target 个词已全部完成，随时回来温习'
                                  : (revealed
                                      ? '已抽取第 ${completed + 1} 个，今日目标 $target 个'
                                      : '等待抽取第 ${completed + 1} 个，今日目标 $target 个'),
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_drawing)
                          const PixelTag('抽取动画进行中', filled: true)
                        else if (revealed) ...[
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            alignment: WrapAlignment.center,
                            children: [
                              PixelTag(
                                word.field,
                                icon: Icons.category_outlined,
                              ),
                              PixelTag(
                                word.difficulty,
                                icon: Icons.signal_cellular_alt,
                              ),
                              PixelTag(
                                word.pack,
                                icon: Icons.inventory_2_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WordDetailScreen(word: word),
                              ),
                            ),
                            icon:
                                const Icon(Icons.menu_book_outlined, size: 17),
                            label: const Text('查看详细解释'),
                          ),
                        ] else
                          PixelPanel(
                            shadow: false,
                            color: palette.softest,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            child: const Text(
                              '词名、难度和词包将在抽取结束后揭晓',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              PixelPanel(
                color: palette.softest,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '今日求知进度',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: palette.accentDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    PixelProgressBar(
                      value: progress,
                      segments: target.clamp(1, 10),
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _drawing
                            ? null
                            : () {
                                if (!revealed) {
                                  _drawWord(app);
                                } else if (done && record != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ResultScreen(
                                        word:
                                            app.wordById(record.wordId) ?? word,
                                        userExplanation: record.userExplanation,
                                        secondsSpent: record.secondsSpent,
                                        review: true,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FocusScreen(word: word),
                                    ),
                                  );
                                }
                              },
                        icon: Icon(
                          _drawing
                              ? Icons.hourglass_top
                              : (!revealed
                                  ? Icons.casino_outlined
                                  : (done ? Icons.replay : Icons.play_arrow)),
                        ),
                        label: Text(
                          _drawing
                              ? '正在抽取…'
                              : (!revealed
                                  ? '点击抽取第 ${completed + 1} 个词'
                                  : (done
                                      ? '复习今日最后一词'
                                      : '开始第 ${completed + 1} 个词')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  void _showRangeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Consumer<AppState>(
        builder: (context, app, _) {
          final palette = context.pixelPalette;
          return FractionallySizedBox(
            heightFactor: .82,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const PixelSectionTitle('抽词范围', index: 'SET'),
                const SizedBox(height: 18),
                const Text(
                  '学习领域',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: app.allFields
                      .map(
                        (field) => FilterChip(
                          label: Text(field),
                          selected: app.selectedFields.contains(field),
                          onSelected: (_) => app.toggleField(field),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  '难度等级',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: app.allDifficulties.map((difficulty) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              difficulty,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          selected: app.difficulty == difficulty,
                          onSelected: (_) => app.setDifficulty(difficulty),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  '参与抽取的词包',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: app.displayPacks
                      .map(
                        (pack) => FilterChip(
                          label: Text('$pack · ${app.packCount(pack)}'),
                          selected: app.enabledPacks.contains(pack),
                          onSelected: (_) => app.togglePack(pack),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                PixelPanel(
                  shadow: false,
                  color: palette.softest,
                  borderColor: palette.line,
                  child: Text(
                    '当前将从 ${app.selectedFields.length} 个领域、${app.enabledPacks.length} 个词包中抽取${app.difficulty}难度词条。',
                    style: const TextStyle(fontSize: 11, height: 1.5),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('完成设置'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLevelGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        final app = context.read<AppState>();
        final palette = context.pixelPalette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PixelSectionTitle('等级与经验', index: 'XP'),
              const SizedBox(height: 16),
              Text(
                'LV.${app.level}  ${app.levelTitle}  ·  累计 ${app.totalExperience} XP',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text('每完成一个词：低难度 +20 XP，中难度 +30 XP，高难度 +45 XP。'),
              const SizedBox(height: 6),
              const Text('专注时间每分钟额外 +1 XP，每词最多奖励 15 XP。'),
              const SizedBox(height: 12),
              Text(
                '升级需求从 80 XP 开始，每级递增 25 XP。',
                style: TextStyle(color: palette.muted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  PixelTag('LV.1 求知新芽'),
                  PixelTag('LV.3 探索学徒'),
                  PixelTag('LV.6 概念猎手'),
                  PixelTag('LV.10 知识行者'),
                  PixelTag('LV.15 求知达人'),
                  PixelTag('LV.20 思想大师'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTodayPlan(BuildContext context) {
    final pageNavigator = Navigator.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Consumer<AppState>(
        builder: (context, app, _) {
          final plan = app.getTodayWords();
          final records = app.todayRecords();
          final completed = {
            for (final record in records) record.wordId: record
          };
          final currentId = app.isDoneToday() ? null : app.getTodayWord()?.id;
          return FractionallySizedBox(
            heightFactor: .78,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: PixelPageTitle(
                    title: '今日词单',
                    subtitle: 'TODAY WORD PLAN',
                    trailing: PixelTag(
                      '${app.todayCompletedCount}/${app.todayTargetCount}',
                      filled: app.isDoneToday(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 24, 24),
                    itemCount: plan.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final word = plan[index];
                      final record = completed[word.id];
                      final isCurrent = word.id == currentId;
                      final isRevealed =
                          isCurrent && _revealedWordId == word.id;
                      final canOpen = record != null || isRevealed;
                      return PixelPanel(
                        shadow: isCurrent,
                        color: isCurrent
                            ? context.pixelPalette.soft
                            : context.pixelPalette.white,
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                          onTap: !canOpen
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  pageNavigator.push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WordDetailScreen(word: word),
                                    ),
                                  );
                                },
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                color: record != null
                                    ? context.pixelPalette.accent
                                    : context.pixelPalette.softest,
                                child: record != null
                                    ? const Icon(Icons.check, size: 18)
                                    : Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record != null || isRevealed
                                          ? word.word
                                          : (isCurrent ? '待抽取词语' : '未解锁词语'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${word.field} · ${word.difficulty} · ${word.pack}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.pixelPalette.muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PixelTag(
                                record != null
                                    ? '已完成'
                                    : (isRevealed
                                        ? '已抽取'
                                        : (isCurrent ? '待抽取' : '未解锁')),
                                filled: isRevealed || record != null,
                              ),
                              if (canOpen) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodayPlanButton extends StatelessWidget {
  final int completed;
  final int target;
  final VoidCallback onTap;

  const _TodayPlanButton({
    required this.completed,
    required this.target,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: palette.soft,
          border: Border.all(color: palette.ink, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.list_alt_outlined, size: 15),
            const SizedBox(width: 4),
            Text(
              '$completed/$target',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

/// 抽取时带流畅晃动动画的吉祥物组件。
/// 组合左右摇摆 + 轻微旋转 + 弹性缩放，营造抽卡摇晃感。
class _AnimatedMascot extends StatelessWidget {
  final bool drawing;
  final Animation<double> shakeAnimation;

  const _AnimatedMascot({
    required this.drawing,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        // sine 波驱动：0→1→0 循环，产生 -1..1 的摆动值
        final t = shakeAnimation.value;
        final sine = sin(t * pi * 2); // -1..1

        // 抽取中：左右平移 ±10px + 旋转 ±0.12rad + 轻微缩放脉冲
        // 静止：全部归零
        final dx = drawing ? sine * 10.0 : 0.0;
        final angle = drawing ? sine * 0.12 : 0.0;
        final scale = drawing ? 1.0 + (1 - sine.abs()) * 0.08 : 1.0;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: const ThemeMascot(size: 116, variant: 2),
    );
  }
}

class _LevelPanel extends StatelessWidget {
  final AppState app;
  final VoidCallback onTap;

  const _LevelPanel({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return PixelPanel(
      shadow: false,
      color: palette.softest,
      borderColor: palette.line,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  PixelTag('LV.${app.level}', filled: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      app.levelTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${app.experienceIntoLevel}/${app.experienceToNextLevel} XP',
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 15),
                ],
              ),
              const SizedBox(height: 8),
              PixelProgressBar(
                value: app.levelProgress,
                segments: 10,
                height: 9,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangePanel extends StatelessWidget {
  final AppState app;
  final VoidCallback onTap;

  const _RangePanel({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return PixelPanel(
      padding: EdgeInsets.zero,
      shadow: false,
      borderColor: palette.line,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.tune, size: 19, color: palette.accentDark),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '抽词范围 · 点击调整',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${app.selectedFields.length} 领域 · ${app.difficulty}难度 · ${app.enabledPacks.length} 词包',
                      style: TextStyle(color: palette.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 13),
            ],
          ),
        ),
      ),
    );
  }
}
