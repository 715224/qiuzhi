import 'package:flutter/material.dart';
import '../models/word.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'result_screen.dart';

/// 解释输入页：先自己解释，再对照标准答案。
class ExplainScreen extends StatefulWidget {
  final Word word;
  final int secondsSpent;

  const ExplainScreen({
    super.key,
    required this.word,
    required this.secondsSpent,
  });

  @override
  State<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends State<ExplainScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先写点什么吧，哪怕只有一句话')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          word: widget.word,
          userExplanation: text,
          secondsSpent: widget.secondsSpent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Scaffold(
      appBar: AppBar(title: const Text('输出解释')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelPanel(
                color: palette.soft,
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      color: palette.accent,
                      child: const Icon(Icons.edit_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.word.word,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.word.pinyin,
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PixelTag('${widget.secondsSpent ~/ 60} MIN'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const PixelSectionTitle('用自己的话说明', index: '02'),
              const SizedBox(height: 8),
              Text(
                '想象你正在讲给一个完全不懂的人听。',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '例如：「${widget.word.word}」大概是……',
                  ),
                  style: const TextStyle(fontSize: 15, height: 1.65),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('对照标准解释'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
