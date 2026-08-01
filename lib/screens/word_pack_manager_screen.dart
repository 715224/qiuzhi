import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word.dart';
import '../providers/app_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'word_detail_screen.dart';
import 'vocabulary_search_screen.dart';

class WordPackManagerScreen extends StatelessWidget {
  const WordPackManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final packs = app.managedPackNames;
    final palette = context.pixelPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('词包管理'),
        actions: [
          IconButton(
            tooltip: '搜索词汇与词包',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const VocabularySearchScreen(),
              ),
            ),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 24, 96),
          itemCount: packs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pack = packs[index];
            final words = app.wordsInPack(pack);
            return PixelPanel(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WordPackDetailScreen(pack: pack),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        color: palette.accent,
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pack,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${words.length} 个词条 · 点击查看与编辑',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 15),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _WordEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新增词条'),
      ),
    );
  }
}

class WordPackDetailScreen extends StatelessWidget {
  final String pack;

  const WordPackDetailScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final words = app.wordsInPack(pack);
    final palette = context.pixelPalette;

    return Scaffold(
      appBar: AppBar(title: Text(pack)),
      body: words.isEmpty
          ? const PixelEmptyState(
              title: '词包为空',
              message: '可以通过下方按钮添加新词条。',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 24, 96),
              itemCount: words.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final word = words[index];
                return PixelPanel(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              word.word,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '编辑词条',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _WordEditorScreen(word: word),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      if (word.pinyin.isNotEmpty)
                        Text(
                          word.pinyin,
                          style: TextStyle(color: palette.muted, fontSize: 11),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        word.definition,
                        style: const TextStyle(fontSize: 12, height: 1.55),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PixelTag(word.field),
                          PixelTag(word.difficulty),
                          if (app.isCustomWord(word.id))
                            const PixelTag('自定义', filled: true),
                          if (app.isWordEdited(word.id))
                            const PixelTag('已编辑', filled: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WordDetailScreen(word: word),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book_outlined, size: 17),
                        label: const Text('查看详细解释'),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _WordEditorScreen(defaultPack: pack),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('添加到词包'),
      ),
    );
  }
}

class _WordEditorScreen extends StatefulWidget {
  final Word? word;
  final String? defaultPack;

  const _WordEditorScreen({this.word, this.defaultPack});

  @override
  State<_WordEditorScreen> createState() => _WordEditorScreenState();
}

class _WordEditorScreenState extends State<_WordEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _wordController;
  late final TextEditingController _pinyinController;
  late final TextEditingController _packController;
  late final TextEditingController _definitionController;
  late final TextEditingController _dateController;
  late final TextEditingController _categoryController;
  late final TextEditingController _simpleExplanationController;
  late final TextEditingController _lifeAnalogyController;
  late final TextEditingController _practicalApplicationController;
  late final TextEditingController _commonMisconceptionController;
  late String _field;
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    final word = widget.word;
    _wordController = TextEditingController(text: word?.word ?? '');
    _pinyinController = TextEditingController(text: word?.pinyin ?? '');
    _packController = TextEditingController(
      text: word?.pack ?? widget.defaultPack ?? '自定义词包',
    );
    _definitionController = TextEditingController(text: word?.definition ?? '');
    _dateController = TextEditingController(text: word?.publishedDate ?? '');
    _categoryController = TextEditingController(text: word?.category ?? '');
    _simpleExplanationController =
        TextEditingController(text: word?.simpleExplanation ?? '');
    _lifeAnalogyController =
        TextEditingController(text: word?.lifeAnalogy ?? '');
    _practicalApplicationController =
        TextEditingController(text: word?.practicalApplication ?? '');
    _commonMisconceptionController =
        TextEditingController(text: word?.commonMisconception ?? '');
    _field = word?.field ?? '通用';
    _difficulty = word?.difficulty ?? '中';
  }

  @override
  void dispose() {
    _wordController.dispose();
    _pinyinController.dispose();
    _packController.dispose();
    _definitionController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _simpleExplanationController.dispose();
    _lifeAnalogyController.dispose();
    _practicalApplicationController.dispose();
    _commonMisconceptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fields = {...app.allFields, _field}.toList();
    final difficulties = {...app.allDifficulties, _difficulty}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.word == null ? '新增词条' : '编辑词条'),
        actions: [
          if (widget.word != null && app.isWordEdited(widget.word!.id))
            TextButton(
              onPressed: () {
                app.restoreWord(widget.word!.id);
                Navigator.of(context).pop();
              },
              child: const Text('恢复原始'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            TextFormField(
              controller: _wordController,
              decoration: const InputDecoration(labelText: '词名 *'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pinyinController,
              decoration: const InputDecoration(labelText: '拼音'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _packController,
              decoration: const InputDecoration(labelText: '所属词包 *'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _field,
                    decoration: const InputDecoration(labelText: '领域'),
                    items: fields
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _field = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(labelText: '难度'),
                    items: difficulties
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _difficulty = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: '热词类型',
                hintText: '例如：科技、财经、心理',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: '发布日期',
                hintText: 'YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _definitionController,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(labelText: '定义 *'),
              validator: _required,
            ),
            const SizedBox(height: 18),
            const Text(
              '详细页内容',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              '以下内容留空时，App 会用标准解释生成兼容内容。',
              style: TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _simpleExplanationController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '一句话解释'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lifeAnalogyController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '生活类比'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _practicalApplicationController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '实际应用'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commonMisconceptionController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '常见误区'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存词条'),
            ),
            const SizedBox(height: 8),
            const Text(
              '修改保存在本机，远程刷新时会保留你的编辑。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? '这一项不能为空' : null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().saveWordEdit(
          original: widget.word,
          word: _wordController.text,
          pinyin: _pinyinController.text,
          field: _field,
          difficulty: _difficulty,
          pack: _packController.text,
          definition: _definitionController.text,
          publishedDate: _dateController.text,
          category: _categoryController.text,
          simpleExplanation: _simpleExplanationController.text,
          lifeAnalogy: _lifeAnalogyController.text,
          practicalApplication: _practicalApplicationController.text,
          commonMisconception: _commonMisconceptionController.text,
        );
    Navigator.of(context).pop();
  }
}
