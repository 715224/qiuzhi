import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word.dart';
import '../providers/app_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'word_detail_screen.dart';
import 'word_pack_manager_screen.dart';

class VocabularySearchScreen extends StatefulWidget {
  const VocabularySearchScreen({super.key});

  @override
  State<VocabularySearchScreen> createState() => _VocabularySearchScreenState();
}

class _VocabularySearchScreenState extends State<VocabularySearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final palette = context.pixelPalette;
    final query = _searchController.text.trim().toLowerCase();
    final packs = app.managedPackNames.where((pack) {
      if (query.isEmpty) return true;
      return pack.toLowerCase().contains(query);
    }).toList();
    final words = query.isEmpty
        ? <Word>[]
        : app.allWords.where((word) => _matchesWord(word, query)).toList()
      ..sort((a, b) {
        final aStarts = a.word.toLowerCase().startsWith(query);
        final bStarts = b.word.toLowerCase().startsWith(query);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
        return a.word.compareTo(b.word);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('搜索词汇与词包')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 24, 12),
              child: TextField(
                key: const Key('vocabulary-search-field'),
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: '搜索词包、词名、拼音或解释',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空',
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 24, 10),
              child: Row(
                children: [
                  PixelTag('${packs.length} 个词包', filled: query.isEmpty),
                  const SizedBox(width: 7),
                  PixelTag('${words.length} 个词汇', filled: query.isNotEmpty),
                ],
              ),
            ),
            Expanded(
              child: query.isNotEmpty && packs.isEmpty && words.isEmpty
                  ? const PixelEmptyState(
                      title: '没有找到结果',
                      message: '可以尝试词名、拼音、词包名称或解释中的关键词。',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 2, 24, 30),
                      children: [
                        if (packs.isNotEmpty) ...[
                          const PixelSectionTitle('词汇包', index: 'PACK'),
                          const SizedBox(height: 10),
                          ...packs.map(
                            (pack) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: PixelPanel(
                                padding: EdgeInsets.zero,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WordPackDetailScreen(pack: pack),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(13),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          color: palette.accent,
                                          child: const Icon(
                                            Icons.inventory_2_outlined,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pack,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${app.packCount(pack)} 个词 · 点击查看',
                                                style: TextStyle(
                                                  color: palette.muted,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 19,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (query.isEmpty) ...[
                          const SizedBox(height: 8),
                          PixelPanel(
                            shadow: false,
                            color: palette.softest,
                            child: const Text(
                              '输入关键词后会同时搜索所有词包中的词名、拼音、分类和解释。',
                              style: TextStyle(fontSize: 11, height: 1.55),
                            ),
                          ),
                        ],
                        if (words.isNotEmpty) ...[
                          if (packs.isNotEmpty) const SizedBox(height: 12),
                          const PixelSectionTitle('词汇', index: 'WORD'),
                          const SizedBox(height: 10),
                          ...words.map(
                            (word) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: PixelPanel(
                                padding: EdgeInsets.zero,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WordDetailScreen(word: word),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(13),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                word.word,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            PixelTag(
                                              word.difficulty,
                                              filled: true,
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.chevron_right,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                        if (word.pinyin.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            word.pinyin,
                                            style: TextStyle(
                                              color: palette.muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          word.definition,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            height: 1.45,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        PixelTag(word.pack),
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
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesWord(Word word, String query) {
    return [
      word.word,
      word.pinyin,
      word.definition,
      word.simpleExplanation,
      word.category,
      word.field,
      word.pack,
    ].any((value) => value.toLowerCase().contains(query));
  }
}
