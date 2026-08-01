import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/app_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'word_detail_screen.dart';

/// 结果对比页：自己的解释与标准定义并列展示。
class ResultScreen extends StatelessWidget {
  final Word word;
  final String userExplanation;
  final int secondsSpent;
  final bool review;

  const ResultScreen({
    super.key,
    required this.word,
    required this.userExplanation,
    required this.secondsSpent,
    this.review = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final palette = context.pixelPalette;
    final favorited = app.isFavorite(word.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(review ? '知识档案' : '对照结果'),
        automaticallyImplyLeading: review,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          child: Column(
            children: [
              PixelPanel(
                color: palette.soft,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.word,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            word.pinyin,
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PixelTag(word.difficulty, filled: true),
                        const SizedBox(height: 5),
                        Text(
                          '${secondsSpent ~/ 60}分${secondsSpent % 60}秒',
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  children: [
                    const PixelSectionTitle('对照学习', index: '03'),
                    const SizedBox(height: 12),
                    _AnswerPanel(
                      label: 'PLAYER / 你的解释',
                      body: userExplanation.isEmpty ? '（未填写）' : userExplanation,
                      color: palette.white,
                    ),
                    const SizedBox(height: 14),
                    _AnswerPanel(
                      label: 'GUIDE / 标准定义',
                      body: word.definition,
                      color: palette.soft,
                      highlighted: true,
                    ),
                    const SizedBox(height: 14),
                    PixelPanel(
                      shadow: false,
                      borderColor: palette.line,
                      color: palette.softest,
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 18, color: palette.accentDark),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              '先找出说不准和遗漏的部分。理解不是一次通关，而是不断刷新自己的解释。',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        PixelTag(word.field),
                        PixelTag(word.pack),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordDetailScreen(word: word),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined, size: 17),
                      label: const Text('查看词语详解'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        app.toggleFavorite(word.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(app.isFavorite(word.id)
                                ? '已收进收藏图鉴'
                                : '已移出收藏图鉴'),
                          ),
                        );
                      },
                      icon: Icon(favorited ? Icons.star : Icons.star_border),
                      label: Text(favorited ? '已收藏' : '收藏'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (!review) {
                          app.saveToday(
                            word: word,
                            userExplanation: userExplanation,
                            secondsSpent: secondsSpent,
                          );
                        }
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/today',
                          (route) => false,
                        );
                      },
                      child: const Text('完成 · 回首页'),
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

class _AnswerPanel extends StatelessWidget {
  final String label;
  final String body;
  final Color color;
  final bool highlighted;

  const _AnswerPanel({
    required this.label,
    required this.body,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return PixelPanel(
      color: color,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                color: highlighted ? palette.accent : palette.ink,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: highlighted ? palette.accentDark : palette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(body, style: const TextStyle(fontSize: 15, height: 1.65)),
        ],
      ),
    );
  }
}
