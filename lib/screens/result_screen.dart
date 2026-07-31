import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/app_state.dart';

/// 结果对比页：把自己写的解释与标准定义并列，直观看到差距。
class ResultScreen extends StatelessWidget {
  final Word word;
  final String userExplanation;
  final int secondsSpent;
  final bool review; // true=复习历史，不再重复保存

  const ResultScreen({
    super.key,
    required this.word,
    required this.userExplanation,
    required this.secondsSpent,
    this.review = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final favorited = app.isFavorite(word.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(review ? '今日对照' : '对照结果'),
        centerTitle: true,
        automaticallyImplyLeading: review, // 复习时允许返回
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  word.pinyin,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${word.field} · ${word.difficulty} · ${word.pack}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _panel(
                    context,
                    title: '你的解释',
                    body: userExplanation.isEmpty ? '（未填写）' : userExplanation,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  _panel(
                    context,
                    title: '标准定义',
                    body: word.definition,
                    color: const Color(0xFF4CAF82),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '小提示：先别急着改答案。看看哪里说不准、哪里漏了，明天换一个词继续练。',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      app.toggleFavorite(word.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            app.isFavorite(word.id) ? '已收藏' : '已取消收藏',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      favorited ? Icons.star : Icons.star_border,
                      color: favorited
                          ? Colors.amber
                          : Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(favorited ? '已收藏' : '收藏'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (!review) {
                        app.saveToday(
                          word: word,
                          userExplanation: userExplanation,
                          secondsSpent: secondsSpent,
                        );
                      }
                      // 回到首页（清空导航栈）
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/today',
                        (route) => false,
                      );
                    },
                    child: const Text('完成，回首页'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}
