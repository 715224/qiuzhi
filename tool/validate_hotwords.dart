import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final root = Directory('daily_hotwords');
  if (!root.existsSync()) {
    stderr.writeln('找不到 daily_hotwords 目录。');
    exitCode = 1;
    return;
  }

  final errors = <String>[];
  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (!lower.endsWith('.json') && !lower.endsWith('.md')) continue;

    String contents;
    try {
      contents = await entity.readAsString(encoding: utf8);
    } on FormatException catch (error) {
      errors.add('${entity.path}: 不是有效的 UTF-8（$error）');
      continue;
    }

    if (contents.contains('\uFFFD')) {
      errors.add('${entity.path}: 含有 Unicode 替换符号 U+FFFD（�）');
    }
    if (!lower.endsWith('.json')) continue;

    try {
      final decoded = jsonDecode(contents);
      if (decoded is List) {
        final ids = <Object?>{};
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          final id = item['id'];
          if (id != null && !ids.add(id)) {
            errors.add('${entity.path}: ID $id 重复');
          }
        }
      }
    } on FormatException catch (error) {
      errors.add('${entity.path}: JSON 无法解析（$error）');
    }
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('× $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('✓ 每日热词 UTF-8、JSON 与重复 ID 校验通过。');
}
