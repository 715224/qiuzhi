import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/word.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'explain_screen.dart';

/// 像素风专注模式：15 分钟倒计时，不显示答案。
class FocusScreen extends StatefulWidget {
  final Word word;
  final int minutes;

  const FocusScreen({super.key, required this.word, this.minutes = 15});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late final int _totalSeconds;
  late int _remaining;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.minutes * 60;
    _remaining = _totalSeconds;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) return;
      setState(() => _remaining--);
      if (_remaining == 0) _finish(_totalSeconds);
    });
  }

  void _finish(int secondsSpent) {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _exitImmersive();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExplainScreen(
          word: widget.word,
          secondsSpent: secondsSpent,
        ),
      ),
    );
  }

  void _exitImmersive() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _confirmExit() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提前结束？'),
        content: const Text('现在结束会直接进入解释环节，本次专注时间仍会被记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续专注'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finish(_totalSeconds - _remaining);
            },
            child: const Text('结束'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _exitImmersive();
    super.dispose();
  }

  String get _clock {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - _remaining / _totalSeconds;
    final palette = context.pixelPalette;
    return Scaffold(
      backgroundColor: palette.accentDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PixelTag('FOCUS MODE', filled: true),
                  Text(
                    'NO. ${widget.word.id.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      color: palette.soft,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PixelPanel(
                color: palette.softest,
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                child: Column(
                  children: [
                    Text(
                      '正在思考',
                      style: TextStyle(
                        color: palette.accentDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.word.word,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _clock,
                      style: const TextStyle(
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PixelProgressBar(value: progress, segments: 10, height: 22),
                    const SizedBox(height: 14),
                    Text(
                      progress < .5 ? '让思绪慢慢加载…' : '答案正在脑海中成形',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '专注思考 · 不要查答案',
                style: TextStyle(
                  color: palette.soft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.white,
                    side: BorderSide(color: palette.soft, width: 2),
                  ),
                  onPressed: _confirmExit,
                  child: const Text('提前结束'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
