import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word.dart';
import '../providers/app_state.dart';
import '../services/ai_book_service.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'ai_model_settings_screen.dart';
import 'word_detail_screen.dart';
import 'word_pack_manager_screen.dart';

class AiBookImportScreen extends StatefulWidget {
  const AiBookImportScreen({super.key});

  @override
  State<AiBookImportScreen> createState() => _AiBookImportScreenState();
}

class _AiBookImportScreenState extends State<AiBookImportScreen> {
  final _textController = TextEditingController();
  final _packController = TextEditingController(text: 'AI书籍词包');
  AiModelConfig? _config;
  List<Word> _words = [];
  String _sourceName = '';
  String? _error;
  var _loadingConfig = true;
  var _processing = false;
  var _saving = false;
  var _confirmedUpload = false;
  var _completedChunks = 0;
  var _totalChunks = 1;
  var _extractedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AiBookService.loadConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _loadingConfig = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _packController.dispose();
    super.dispose();
  }

  Future<void> _pickBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    try {
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) throw const FileSystemException('无法读取所选文件');
      final text = utf8.decode(bytes, allowMalformed: true);
      if (!mounted) return;
      final baseName = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      setState(() {
        _sourceName = file.name;
        _textController.text = text;
        if (_packController.text == 'AI书籍词包') {
          _packController.text = '书籍 · $baseName';
        }
        _words = [];
        _error = null;
      });
    } catch (error) {
      _show('读取文件失败：$error', error: true);
    }
  }

  Future<void> _configureModel() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiModelSettingsScreen()),
    );
    await _loadConfig();
  }

  Future<void> _process() async {
    final config = _config;
    final packName = _packController.text.trim();
    if (config == null || !config.isReady) {
      _show('请先配置 AI 接口地址和模型名称。', error: true);
      return;
    }
    if (packName.isEmpty) {
      _show('请填写词包名称。', error: true);
      return;
    }
    if (_textController.text.trim().length < 50) {
      _show('请导入 TXT/Markdown 书籍或粘贴正文。', error: true);
      return;
    }
    if (!_confirmedUpload) {
      _show('请先确认允许把正文发送到所配置的模型服务。', error: true);
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
      _words = [];
      _completedChunks = 0;
      _totalChunks = 1;
      _extractedCount = 0;
    });
    try {
      final words = await AiBookService().extractBook(
        config: config,
        bookText: _textController.text,
        packName: packName,
        onProgress: (completed, total, extracted) {
          if (!mounted) return;
          setState(() {
            _completedChunks = completed;
            _totalChunks = total;
            _extractedCount = extracted;
          });
        },
      );
      if (!mounted) return;
      setState(() => _words = words);
      if (words.isEmpty) {
        _show('模型完成了分析，但没有返回符合格式的词条。', error: true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
      _show('处理失败：$error', error: true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _savePack() async {
    if (_words.isEmpty || _saving) return;
    setState(() => _saving = true);
    final saved = await context.read<AppState>().addCustomWords(_words);
    if (!mounted) return;
    setState(() => _saving = false);
    _show('已保存 $saved 个词到“${_packController.text.trim()}”。');
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WordPackManagerScreen()),
    );
  }

  void _show(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? context.pixelPalette.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    final config = _config;
    final progress = _totalChunks == 0
        ? 0.0
        : (_completedChunks / _totalChunks).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('AI 书籍词包')),
      body: _loadingConfig
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 24, 100),
              children: [
                PixelPanel(
                  color:
                      config?.isReady == true ? palette.softest : palette.soft,
                  child: Row(
                    children: [
                      Icon(
                        config?.isReady == true
                            ? Icons.smart_toy_outlined
                            : Icons.warning_amber_rounded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              config?.isReady == true
                                  ? '当前模型：${config!.model}'
                                  : '尚未配置 AI 模型',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              config?.isReady == true
                                  ? config!.chatCompletionsUrl
                                  : '先配置接口才能分析全书',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: palette.muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _processing ? null : _configureModel,
                        child: const Text('设置'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _packController,
                  enabled: !_processing,
                  decoration: const InputDecoration(
                    labelText: '自定义词包名称 *',
                    hintText: '例如：经济学原理',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _processing ? null : _pickBook,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _sourceName.isEmpty ? '选择 TXT / Markdown 书籍' : _sourceName,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '目前支持 UTF-8 的 .txt 和 .md；也可以直接在下方粘贴正文。',
                  style: TextStyle(color: palette.muted, fontSize: 10),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  enabled: !_processing,
                  minLines: 6,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: '书籍正文',
                    hintText: '粘贴正文，AI 会逐段覆盖整本书……',
                    helperText: _textController.text.isEmpty
                        ? null
                        : '已读取 ${_textController.text.length} 个字符',
                  ),
                  onChanged: (_) => setState(() => _words = []),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmedUpload,
                  onChanged: _processing
                      ? null
                      : (value) =>
                          setState(() => _confirmedUpload = value ?? false),
                  title: const Text(
                    '我确认正文可以发送给所配置的模型服务',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                if (_processing) ...[
                  PixelPanel(
                    color: palette.softest,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '正在分析第 $_completedChunks / $_totalChunks 段',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text(
                          '已提取并去重 $_extractedCount 个词。请保持 App 在前台；全书越长，请求次数越多。',
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _process,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('分析全书并生成分级词包'),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '× $_error',
                    style: TextStyle(color: palette.danger, fontSize: 11),
                  ),
                ],
                if (_words.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  PixelPageTitle(
                    title: '生成结果',
                    subtitle: 'AI VOCABULARY PREVIEW',
                    trailing: PixelTag('${_words.length} 词', filled: true),
                  ),
                  const SizedBox(height: 12),
                  _DifficultySummary(words: _words),
                  const SizedBox(height: 12),
                  ..._words.map(
                    (word) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: PixelPanel(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WordDetailScreen(word: word),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                PixelTag(word.difficulty, filled: true),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        word.word,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        word.definition,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: _words.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: palette.white,
                  border: Border(top: BorderSide(color: palette.ink, width: 2)),
                ),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _savePack,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.library_add_outlined),
                  label: Text('保存为自定义词包（${_words.length} 词）'),
                ),
              ),
            ),
    );
  }
}

class _DifficultySummary extends StatelessWidget {
  final List<Word> words;

  const _DifficultySummary({required this.words});

  @override
  Widget build(BuildContext context) {
    int count(String difficulty) =>
        words.where((word) => word.difficulty == difficulty).length;
    return Row(
      children: ['低', '中', '高']
          .map(
            (difficulty) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 7),
                child: PixelPanel(
                  shadow: false,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        '${count(difficulty)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('$difficulty 难度',
                          style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
