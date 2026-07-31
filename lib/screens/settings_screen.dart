import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// 设置页（我的）：领域选择、难度选择、词库包开关、每日热词（GitHub 远程）、每日提醒。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 用当前已配置地址预填输入框（仅首次）
    final app = Provider.of<AppState>(context, listen: false);
    if (_urlController.text.isEmpty) {
      _urlController.text = app.remoteUrl.isNotEmpty
          ? app.remoteUrl
          : 'https://raw.githubusercontent.com/用户名/仓库名/main/words.json';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

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
            onPressed: () =>
                app.setAllFields(app.selectedFields.length != app.allFields.length),
            child: Text(
                app.selectedFields.length == app.allFields.length ? '全不选' : '全选'),
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
        ...app.displayPacks.map((p) {
          final on = app.enabledPacks.contains(p);
          final count = app.packCount(p);
          final isRemote = p == AppState.remotePackName;
          return SwitchListTile(
            title: Text(p),
            subtitle: Text(isRemote
                ? 'GitHub 远程 · $count 个名词'
                : '$count 个名词'),
            value: on,
            onChanged: (_) => app.togglePack(p),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
        const Divider(height: 32),
        // —— 每日热词（GitHub 远程）——
        const _SectionTitle('每日热词（GitHub 远程）'),
        const SizedBox(height: 6),
        Text(
          '填入一个 GitHub raw 的 words.json 地址，App 每次打开会静默拉取最新热词并缓存到本地（断网也能用）。配合 WorkBuddy 自动化每日推送即可实现每日更新。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'words.json 的 GitHub raw 地址',
            hintText: 'https://raw.githubusercontent.com/.../words.json',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: app.remoteRefreshing || !app.hasRemoteConfig
                  ? null
                  : () => app.refreshRemote(),
              child: const Text('立即刷新'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RemoteStatus(app: app),
        const SizedBox(height: 16),
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
}

/// 远程词库状态展示
class _RemoteStatus extends StatelessWidget {
  final AppState app;
  const _RemoteStatus({required this.app});

  @override
  Widget build(BuildContext context) {
    if (!app.hasRemoteConfig) {
      return const Text('尚未配置远程词库地址。', style: TextStyle(fontSize: 13));
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
          Text('正在拉取最新热词…', style: TextStyle(fontSize: 13)),
        ],
      );
    }
    if (app.remoteError != null) {
      return Text(
        '拉取失败：${app.remoteError}（已使用本地缓存）',
        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error),
      );
    }
    if (app.remoteUpdatedAt != null) {
      final n = app.remoteWords.length;
      final t = _fmt(app.remoteUpdatedAt!);
      return Text(
        '最近更新：$t，共 $n 个热词。',
        style: TextStyle(fontSize: 13, color: Colors.green.shade700),
      );
    }
    return const Text('已配置，等待首次拉取。', style: TextStyle(fontSize: 13));
  }

  String _fmt(DateTime d) {
    final p = (int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
  }
}

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
