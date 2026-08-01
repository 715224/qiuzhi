import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/app_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'result_screen.dart';

/// 收藏页：列出用户收藏的词。
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final palette = context.pixelPalette;
    final words = app.favorites
        .map(app.wordById)
        .whereType<Word>()
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: PixelPageTitle(
                title: '收藏图鉴',
                subtitle: 'KNOWLEDGE COLLECTION',
                trailing: PixelTag('${words.length} 枚', filled: true),
              ),
            ),
            if (words.isEmpty)
              const Expanded(
                child: PixelEmptyState(
                  title: '还没有收藏',
                  message: '在对照结果页点亮星星，\n把喜欢的名词收进图鉴。',
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 24, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.14,
                  ),
                  itemCount: words.length,
                  itemBuilder: (context, i) {
                    final word = words[i];
                    final records = app.history.values
                        .where((r) => r.wordId == word.id)
                        .toList();
                    final rec = records.isEmpty ? null : records.first;
                    return InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            word: word,
                            userExplanation: rec?.userExplanation ?? '',
                            secondsSpent: rec?.secondsSpent ?? 0,
                            review: true,
                          ),
                        ),
                      ),
                      child: PixelPanel(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Icon(Icons.star,
                                  size: 18, color: palette.accentDark),
                            ),
                            const Spacer(),
                            Text(
                              word.word,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              word.field,
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
