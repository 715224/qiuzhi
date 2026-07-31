import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../screens/result_screen.dart';

/// 往期回顾：按日期倒序列出已完成思考的记录。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final records = app.history.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // 最新在前

    if (records.isEmpty) {
      return const Center(
        child: Text('还没有记录，去「今日」完成第一次求知吧。'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final rec = records[i].value;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
            child: Text(
              rec.wordText.isNotEmpty ? rec.wordText[0] : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(rec.wordText, style: const TextStyle(fontSize: 17)),
          subtitle: Text('${rec.date} · ${rec.field} · 专注 ${_fmt(rec.secondsSpent)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final word = app.wordById(rec.wordId);
            if (word != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultScreen(
                    word: word,
                    userExplanation: rec.userExplanation,
                    secondsSpent: rec.secondsSpent,
                    review: true,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '${m}分${sec}秒' : '${sec}秒';
  }
}
