import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../screens/result_screen.dart';

/// 收藏页：列出用户收藏的词，点开查看标准定义与自己的解释。
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final ids = app.favorites.toList();

    if (ids.isEmpty) {
      return const Center(
        child: Text('还没有收藏。在对照结果页点「收藏」即可加入。'),
      );
    }

    final words = ids
        .map((id) => app.wordById(id))
        .where((w) => w != null)
        .cast<dynamic>()
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final word = words[i];
        final hasRecord = app.history.values
            .any((r) => r.wordId == word.id);
        final rec = hasRecord
            ? app.history.values.firstWhere((r) => r.wordId == word.id)
            : null;
        return ListTile(
          leading: const Icon(Icons.star, color: Colors.amber),
          title: Text(word.word, style: const TextStyle(fontSize: 17)),
          subtitle: Text('${word.field} · ${word.pack}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResultScreen(
                  word: word,
                  userExplanation: rec?.userExplanation ?? '',
                  secondsSpent: rec?.secondsSpent ?? 0,
                  review: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
