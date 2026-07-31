import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// 设置页（我的）：领域选择、难度选择、词库包开关、每日提醒。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('学习领域'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: app.allFields.map((f) {
            final on = app.selectedFields.contains(f);
            return FilterChip(
              label: Text(f),
              selected: on,
              onSelected: (_) => app.toggleField(f),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => app.setAllFields(app.selectedFields.length != app.allFields.length),
            child: Text(app.selectedFields.length == app.allFields.length ? '全不选' : '全选'),
          ),
        ),
        const Divider(height: 32),
        const _SectionTitle('抽取难度'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: app.allDifficulties
              .map((d) => ButtonSegment(value: d, label: Text(d)))
              .toList(),
          selected: {app.difficulty},
          onSelectionChanged: (s) => app.setDifficulty(s.first),
        ),
        const SizedBox(height: 6),
        Text(
          '每天从选中领域、选中难度的词库确定性抽取一个名词。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: 32),
        const _SectionTitle('词库包'),
        const SizedBox(height: 8),
        ...app.allPacks.map((p) {
          final on = app.enabledPacks.contains(p);
          final count = _packCount(p);
          return SwitchListTile(
            title: Text(p),
            subtitle: Text('$count 个名词'),
            value: on,
            onChanged: (_) => app.togglePack(p),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
        const Divider(height: 32),
        const _SectionTitle('每日提醒'),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('每天固定时间提醒求知'),
          subtitle: const Text('后续版本接入系统通知（flutter_local_notifications）'),
          value: false,
          onChanged: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('提醒功能将在接入通知后开启，敬请期待。')),
            );
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        const _AboutCard(),
      ],
    );
  }

  int _packCount(String pack) {
    // 复用词库统计，避免循环依赖
    return _packCounts[pack] ?? 0;
  }
}

// 词库包名词数量（与 word_bank 保持一致的静态汇总）
const Map<String, int> _packCounts = {
  '通用知识包': 9,
  '哲学包': 4,
  '心理学术语包': 6,
  '工程测量术语包': 5,
};

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('关于求知', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '每天一个名词，15 分钟专注思考，写下自己的解释，再对照标准定义。'
              '用费曼学习法，把「见过」变成「真懂」。',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      );
}
