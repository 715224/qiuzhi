import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/word.dart';
import '../screens/explain_screen.dart';

/// 番茄钟锁屏：深色全屏，环形进度，15 分钟专注思考。
/// 不显示任何答案，仅一个低调的「提前结束」按钮。
class FocusScreen extends StatefulWidget {
  final Word word;
  final int minutes;

  const FocusScreen({super.key, required this.word, this.minutes = 15});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _remaining;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.minutes * 60;
    _remaining = _totalSeconds;
    // 进入沉浸模式，隐藏状态栏/导航栏，强化「锁屏」感
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining > 0) {
        setState(() => _remaining--);
        if (_remaining == 0) _onFinish();
      }
    });
  }

  void _onFinish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _exitImmersive();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ExplainScreen(
            word: widget.word,
            secondsSpent: _totalSeconds,
          ),
        ),
      );
    }
  }

  void _exitImmersive() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _confirmExit() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提前结束？'),
        content: const Text('专注还没结束，提前结束将进入解释环节（不计入满分专注）。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('继续专注'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              _finished = true;
              _timer?.cancel();
              final spent = _totalSeconds - _remaining;
              _exitImmersive();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ExplainScreen(
                    word: widget.word,
                    secondsSpent: spent,
                  ),
                ),
              );
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              '正在思考',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.word.word,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // 环形进度 + 大计时
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF7C9CFF)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _clock,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '专注思考，不要查答案',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // 低调的退出按钮
            TextButton(
              onPressed: _confirmExit,
              child: Text(
                '提前结束',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
