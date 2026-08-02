import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'word_pack_manager_screen.dart';
import 'ai_book_import_screen.dart';
import 'ai_model_settings_screen.dart';
import 'vocabulary_search_screen.dart';

/// 我的：领域、难度、词库与远程热词配置。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();

  Future<void> _confirmClearLearningData(AppState app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.pixelPalette;
        return AlertDialog(
          title: const Text('清空全部学习记录？'),
          content: const Text(
            '这会删除所有学习历史、今日进度、经验等级和收藏，且无法恢复。每日目标、主题、词包和自定义词汇会保留。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.danger,
                foregroundColor: palette.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('确认清空'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await app.clearLearningData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('全部学习记录已清空')),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppState>();
    if (_urlController.text.isEmpty) {
      _urlController.text = app.remoteUrl.isNotEmpty
          ? app.remoteUrl
          : 'https://github.com/715224/qiuzhi';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final palette = context.pixelPalette;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 24, 28),
          children: [
            const PixelPageTitle(
              title: '我的设置',
              subtitle: 'PLAYER SETTINGS',
              trailing: PixelTag('LV.01', filled: true),
            ),
            const SizedBox(height: 18),
            PixelPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('本地学习档案', index: 'SAVE'),
                  const SizedBox(height: 10),
                  Text(
                    '学习进度、每日目标、收藏、设置和自定义词包会自动保存在当前浏览器。关闭网页或重启电脑后，再用同一入口打开即可继续。',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PixelTag('已学习 ${app.history.length} 词', filled: true),
                      PixelTag('已收藏 ${app.favorites.length} 词'),
                      PixelTag('目标 ${app.dailyGoal} 词/天'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '提示：清除浏览器网站数据会删除本地档案。',
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.danger,
                        side: BorderSide(color: palette.danger, width: 2),
                      ),
                      onPressed: app.history.isEmpty && app.favorites.isEmpty
                          ? null
                          : () => _confirmClearLearningData(app),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('清空全部学习记录'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              color: context.pixelPalette.softest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('界面主题', index: '00'),
                  const SizedBox(height: 10),
                  const Text(
                    '选择你喜欢的求知伙伴，主题会自动保存。',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: AppVisualTheme.values.map((theme) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: theme == AppVisualTheme.cyanPixel ? 8 : 0,
                          ),
                          child: _ThemeChoiceCard(
                            theme: theme,
                            selected: app.visualTheme == theme,
                            onTap: () => app.setVisualTheme(theme),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              color: palette.softest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('AI 书籍词包', index: '05'),
                  const SizedBox(height: 9),
                  Text(
                    '设置自己的 AI 模型，导入整本 TXT/Markdown。App 会分段提取值得学习的词汇，自动分为低、中、高难度，并生成四段详解。',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AiModelSettingsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.settings_suggest_outlined),
                          label: const Text('模型设置'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AiBookImportScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.auto_stories_outlined),
                          label: const Text('导入书籍'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '生成后保存为普通自定义词包，可参与首页抽词，也能继续查看和编辑。',
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              color: palette.softest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('每日学习目标', index: '01'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: app.dailyGoal <= 1
                            ? null
                            : () => app.setDailyGoal(app.dailyGoal - 1),
                        child: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${app.dailyGoal}',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '个词 / 天',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: app.dailyGoal >= 20
                            ? null
                            : () => app.setDailyGoal(app.dailyGoal + 1),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    children: [1, 3, 5, 10, 20]
                        .map(
                          (goal) => ChoiceChip(
                            label: Text('$goal 个'),
                            selected: app.dailyGoal == goal,
                            onSelected: (_) => app.setDailyGoal(goal),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '每完成一个词会自动进入下一个，达到目标后才算今日完成。',
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('学习领域', index: '02'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: app.allFields.map((field) {
                      return FilterChip(
                        label: Text(field),
                        selected: app.selectedFields.contains(field),
                        onSelected: (_) => app.toggleField(field),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 7),
                  TextButton(
                    onPressed: () => app.setAllFields(
                      app.selectedFields.length != app.allFields.length,
                    ),
                    child: Text(
                        app.selectedFields.length == app.allFields.length
                            ? '[ 全不选 ]'
                            : '[ 全选 ]'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              color: palette.softest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('抽取难度', index: '03'),
                  const SizedBox(height: 12),
                  Row(
                    children: app.allDifficulties.map((difficulty) {
                      final selected = app.difficulty == difficulty;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: InkWell(
                            onTap: () => app.setDifficulty(difficulty),
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    selected ? palette.accent : palette.white,
                                border: Border.all(
                                  color: palette.ink,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                difficulty,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '每天从所选领域与难度中抽取一个名词。',
                    style: TextStyle(color: palette.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('词库包', index: '04'),
                  const SizedBox(height: 5),
                  ...app.displayPacks.map((pack) {
                    final remote = pack == AppState.remotePackName;
                    return SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        pack,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        remote
                            ? 'GitHub 远程 · ${app.packCount(pack)} 个名词'
                            : '${app.packCount(pack)} 个名词',
                        style: const TextStyle(fontSize: 10),
                      ),
                      value: app.enabledPacks.contains(pack),
                      onChanged: (_) => app.togglePack(pack),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WordPackManagerScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('查看与编辑词包'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VocabularySearchScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('搜索词汇与词包'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              color: palette.softest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelSectionTitle('远程热词', index: '06'),
                  const SizedBox(height: 9),
                  Text(
                    '可直接填写 GitHub 仓库主页、文件页或 Raw 地址。以北京时间每天中午 12:00 为分界，进入 App 时自动更新一次。',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'GITHUB 仓库或 JSON 地址',
                      hintText: 'https://github.com/用户名/仓库名',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: app.remoteRefreshing
                              ? null
                              : () {
                                  app.setRemoteUrl(_urlController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已应用，正在拉取…')),
                                  );
                                },
                          child: const Text('应用并刷新'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: app.remoteRefreshing || !app.hasRemoteConfig
                            ? null
                            : app.refreshRemote,
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _RemoteStatus(app: app),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PixelPanel(
              shadow: false,
              borderColor: palette.line,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABOUT / 关于求知',
                    style: TextStyle(
                      color: palette.accentDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '每天一个名词，15 分钟专注思考。用自己的语言解释，再对照标准定义。',
                    style: TextStyle(fontSize: 12, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('每日提醒',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('通知功能将在后续版本开放'),
                    value: false,
                    onChanged: (_) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('提醒功能将在后续版本开放。')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  final AppVisualTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoiceCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final previewPalette = theme == AppVisualTheme.pinkMascot
        ? PixelPalette.pink
        : PixelPalette.cyan;
    return Semantics(
      button: true,
      selected: selected,
      label: theme.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 116,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: previewPalette.soft,
            border: Border.all(
              color: selected ? previewPalette.accentDark : previewPalette.line,
              width: selected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Expanded(
                child: theme == AppVisualTheme.pinkMascot
                    ? Image.asset(
                        'assets/pink_mascot/pink_mascot_pixel_02.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      )
                    : const PixelCat(size: 58),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_circle,
                        size: 14, color: previewPalette.accentDark),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      theme.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: previewPalette.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteStatus extends StatelessWidget {
  final AppState app;

  const _RemoteStatus({required this.app});

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    if (!app.hasRemoteConfig) {
      return const Text('□ 尚未配置远程词库', style: TextStyle(fontSize: 11));
    }
    if (app.remoteRefreshing) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('正在读取最新热词…', style: TextStyle(fontSize: 11)),
        ],
      );
    }
    if (app.remoteError != null) {
      return Text(
        '× 拉取失败：${app.remoteError}（使用本地缓存）',
        style: TextStyle(color: palette.danger, fontSize: 11),
      );
    }
    if (app.remoteUpdatedAt != null) {
      return Text(
        '■ 最近更新 ${_fmt(app.remoteUpdatedAt!)} · ${app.remoteWords.length} 词',
        style: TextStyle(color: palette.accentDark, fontSize: 11),
      );
    }
    return const Text('□ 已配置，等待首次拉取', style: TextStyle(fontSize: 11));
  }

  static String _fmt(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
  }
}
