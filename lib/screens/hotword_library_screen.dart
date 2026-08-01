import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word.dart';
import '../providers/app_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'word_detail_screen.dart';

/// 累计型热词库：支持按发布日期或热词类型分组浏览。
class HotwordLibraryScreen extends StatelessWidget {
  const HotwordLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final palette = context.pixelPalette;
    final groups = _groupWords(app.remoteWords, app.hotwordGrouping);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: PixelPageTitle(
                title: '热词库',
                subtitle: 'DAILY HOTWORD LIBRARY',
                trailing: PixelTag('${app.remoteWords.length} 词', filled: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 24, 12),
              child: PixelPanel(
                color: palette.softest,
                padding: const EdgeInsets.all(8),
                shadow: false,
                child: Row(
                  children: HotwordGrouping.values.map((grouping) {
                    final selected = app.hotwordGrouping == grouping;
                    return Expanded(
                      child: InkWell(
                        onTap: () => app.setHotwordGrouping(grouping),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? palette.accent : palette.white,
                            border: Border.all(
                              color: selected ? palette.ink : palette.line,
                              width: selected ? 2 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                grouping == HotwordGrouping.time
                                    ? Icons.calendar_month_outlined
                                    : Icons.category_outlined,
                                size: 17,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                grouping.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: app.remoteWords.isEmpty
                  ? _EmptyHotwordLibrary(app: app)
                  : RefreshIndicator(
                      onRefresh: app.refreshRemote,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 2, 24, 26),
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return _HotwordGroup(
                            title: group.key,
                            words: group.value,
                            initiallyExpanded: index == 0,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static List<MapEntry<String, List<Word>>> _groupWords(
    List<Word> words,
    HotwordGrouping grouping,
  ) {
    final grouped = <String, List<Word>>{};
    for (final word in words) {
      final key = grouping == HotwordGrouping.time
          ? (word.publishedDate.isEmpty ? '日期未知' : word.publishedDate)
          : (word.category.isEmpty ? word.field : word.category);
      grouped.putIfAbsent(key, () => []).add(word);
    }
    final entries = grouped.entries.toList();
    if (grouping == HotwordGrouping.time) {
      entries.sort((a, b) => b.key.compareTo(a.key));
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }
    return entries;
  }
}

class _HotwordGroup extends StatelessWidget {
  final String title;
  final List<Word> words;
  final bool initiallyExpanded;

  const _HotwordGroup({
    required this.title,
    required this.words,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return PixelPanel(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: palette.accentDark,
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${words.length} 个热词',
          style: TextStyle(color: palette.muted, fontSize: 10),
        ),
        children: [
          for (var index = 0; index < words.length; index++) ...[
            _HotwordRow(word: words[index]),
            if (index != words.length - 1)
              Divider(height: 18, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _HotwordRow extends StatelessWidget {
  final Word word;

  const _HotwordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WordDetailScreen(word: word)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    word.word,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PixelTag(word.difficulty, filled: word.difficulty == '高'),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 19),
              ],
            ),
            if (word.pinyin.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                word.pinyin,
                style: TextStyle(color: palette.muted, fontSize: 10),
              ),
            ],
            const SizedBox(height: 7),
            Text(
              word.definition,
              style: const TextStyle(fontSize: 12, height: 1.55),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PixelTag(word.category.isEmpty ? word.field : word.category),
                if (word.publishedDate.isNotEmpty) PixelTag(word.publishedDate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHotwordLibrary extends StatelessWidget {
  final AppState app;

  const _EmptyHotwordLibrary({required this.app});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const ThemeMascot(size: 118, variant: 1),
        const SizedBox(height: 16),
        const Text(
          '热词库还是空的',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          app.hasRemoteConfig
              ? '下拉或点击下方按钮，读取最新的每日热词。'
              : '先在「我的」中配置 GitHub 热词仓库地址。',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (app.hasRemoteConfig)
          FilledButton.icon(
            onPressed: app.remoteRefreshing ? null : app.refreshRemote,
            icon: const Icon(Icons.refresh),
            label: Text(app.remoteRefreshing ? '正在刷新…' : '刷新热词库'),
          ),
      ],
    );
  }
}
