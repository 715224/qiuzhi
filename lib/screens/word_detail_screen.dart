import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/word.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';

/// 词条的费曼式详细解释页。列表中的标准解释保持原样，本页补充四种理解角度。
class WordDetailScreen extends StatelessWidget {
  final Word word;

  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Scaffold(
      appBar: AppBar(title: const Text('词语详解')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 24, 30),
          children: [
            PixelPanel(
              color: palette.softest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      PixelTag(word.difficulty, filled: true),
                    ],
                  ),
                  if (word.pinyin.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.pinyin,
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PixelTag(
                          word.category.isEmpty ? word.field : word.category),
                      PixelTag(word.pack),
                      if (word.publishedDate.isNotEmpty)
                        PixelTag(word.publishedDate),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PixelPanel(
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '标准解释',
                    style: TextStyle(
                      color: palette.accentDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(word.definition, style: const TextStyle(height: 1.65)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              number: '01',
              title: '一句话解释',
              subtitle: '小学生也能听懂',
              icon: Icons.lightbulb_outline,
              text: word.resolvedSimpleExplanation,
            ),
            const SizedBox(height: 12),
            _DetailSection(
              number: '02',
              title: '生活类比',
              subtitle: '用熟悉的场景立刻联想',
              icon: Icons.home_outlined,
              text: word.resolvedLifeAnalogy,
            ),
            const SizedBox(height: 12),
            _DetailSection(
              number: '03',
              title: '实际应用',
              subtitle: '日常生活和工作中怎么用',
              icon: Icons.build_outlined,
              text: word.resolvedPracticalApplication,
            ),
            const SizedBox(height: 12),
            _DetailSection(
              number: '04',
              title: '常见误区',
              subtitle: '最容易理解错的地方',
              icon: Icons.warning_amber_rounded,
              text: word.resolvedCommonMisconception,
            ),
            if (word.sourceUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(word.sourceUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('打开对应教程'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String text;

  const _DetailSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Semantics(
      label: '$title：$text',
      child: PixelPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  color: palette.accent,
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: palette.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: palette.accentDark, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(fontSize: 14, height: 1.7)),
          ],
        ),
      ),
    );
  }
}
