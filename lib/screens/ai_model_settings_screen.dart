import 'package:flutter/material.dart';

import '../services/ai_book_service.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';

class AiModelSettingsScreen extends StatefulWidget {
  const AiModelSettingsScreen({super.key});

  @override
  State<AiModelSettingsScreen> createState() => _AiModelSettingsScreenState();
}

class _AiModelSettingsScreenState extends State<AiModelSettingsScreen> {
  final _endpoint = TextEditingController();
  final _model = TextEditingController();
  final _apiKey = TextEditingController();
  var _chunkSize = 6000;
  var _maxTerms = 20;
  var _loading = true;
  var _testing = false;
  var _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await AiBookService.loadConfig();
    if (!mounted) return;
    setState(() {
      _endpoint.text = config.endpoint;
      _model.text = config.model;
      _apiKey.text = config.apiKey;
      _chunkSize = config.chunkSize;
      _maxTerms = config.maxTermsPerChunk;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  AiModelConfig get _config => AiModelConfig(
        endpoint: _endpoint.text,
        model: _model.text,
        apiKey: _apiKey.text,
        chunkSize: _chunkSize,
        maxTermsPerChunk: _maxTerms,
      );

  Future<void> _save({bool showMessage = true}) async {
    if (!_config.isReady) {
      _message('接口地址和模型名称不能为空。', error: true);
      return;
    }
    try {
      await AiBookService.saveConfig(_config);
      if (showMessage) _message('AI 模型设置已保存。');
    } catch (error) {
      _message('保存失败：$error', error: true);
    }
  }

  Future<void> _test() async {
    if (!_config.isReady || _testing) return;
    setState(() => _testing = true);
    try {
      await _save(showMessage: false);
      final reply = await AiBookService().testConnection(_config);
      _message('连接成功：${reply.isEmpty ? '模型已响应' : reply}');
    } catch (error) {
      _message('连接失败：$error', error: true);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _message(String text, {bool error = false}) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('AI 模型设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 24, 30),
              children: [
                PixelPanel(
                  color: palette.softest,
                  child: const Text(
                    '支持 OpenAI 兼容的 Chat Completions 接口。可填写官方服务、兼容平台或自己的本地模型地址。',
                    style: TextStyle(fontSize: 12, height: 1.6),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _endpoint,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: '接口地址 *',
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _model,
                  decoration: const InputDecoration(
                    labelText: '模型名称 *',
                    hintText: '填写服务商提供的模型 ID',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKey,
                  obscureText: _obscureKey,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: '本地模型不需要时可留空',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                      icon: Icon(
                        _obscureKey ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PixelPanel(
                  shadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '全书分段设置',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Text('每段字符数：$_chunkSize'),
                      Slider(
                        value: _chunkSize.toDouble(),
                        min: 2000,
                        max: 12000,
                        divisions: 10,
                        label: '$_chunkSize',
                        onChanged: (value) =>
                            setState(() => _chunkSize = value.round()),
                      ),
                      Text('每段最多提取：$_maxTerms 个词'),
                      Slider(
                        value: _maxTerms.toDouble(),
                        min: 5,
                        max: 50,
                        divisions: 9,
                        label: '$_maxTerms',
                        onChanged: (value) =>
                            setState(() => _maxTerms = value.round()),
                      ),
                      Text(
                        '更小的分段和更多词会提高覆盖率，也会增加请求次数与模型费用。',
                        style: TextStyle(color: palette.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testing ? null : _test,
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cable_outlined),
                        label: const Text('测试连接'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _save(),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('保存设置'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'API Key 使用系统安全存储保存在本机，不会写入书籍词包或远程热词文件。书籍正文会发送给你配置的模型服务商，请确认内容允许上传。',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }
}
