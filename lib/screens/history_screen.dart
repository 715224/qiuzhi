import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'result_screen.dart';

/// 往期回顾：按日期倒序列出已完成思考的记录。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final palette = context.pixelPalette;
    final records = app.history.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: PixelPageTitle(
                title: '往期档案',
                subtitle: 'QUEST ARCHIVE',
                trailing: PixelTag('记忆库'),
              ),
            ),
            if (records.isEmpty)
              const Expanded(
                child: PixelEmptyState(
                  title: '档案还是空的',
                  message: '去「今日」完成第一次求知，\n这里会保存你的思考轨迹。',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 24, 24),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final rec = records[i].value;
                    return InkWell(
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
                      child: PixelPanel(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              color: palette.accent,
                              child: Text(
                                rec.wordText.isNotEmpty ? rec.wordText[0] : '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.wordText,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${rec.date} · ${rec.field}',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '专注 ${_fmt(rec.secondsSpent)}',
                                    style: TextStyle(
                                      color: palette.accentDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 15),
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

  static String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '${m}分${sec}秒' : '${sec}秒';
  }
}
