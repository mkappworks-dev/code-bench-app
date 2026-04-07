import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/filesystem/filesystem_service.dart';

part 'editor_notifier.g.dart';

class OpenFile {
  OpenFile({
    required this.path,
    required this.content,
    this.isDirty = false,
    this.language = 'plaintext',
    this.isReadOnly = false,
    this.label,
  });

  final String path;
  String content;
  bool isDirty;
  final String language;
  final bool isReadOnly;
  final String? label; // e.g. "[GitHub] filename"

  String get displayName => label ?? path.split('/').last;

  OpenFile copyWith({String? content, bool? isDirty, bool? isReadOnly}) {
    return OpenFile(
      path: path,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
      language: language,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      label: label,
    );
  }
}

@Riverpod(keepAlive: true)
class EditorTabs extends _$EditorTabs {
  @override
  List<OpenFile> build() => [];

  void openFile(OpenFile file) {
    // Don't open duplicates
    if (state.any((f) => f.path == file.path)) {
      return;
    }
    state = [...state, file];
  }

  void closeFile(String path) {
    state = state.where((f) => f.path != path).toList();
    // If we closed the active tab, move to previous
    if (ref.read(activeFilePathProvider) == path) {
      final newActive = state.isNotEmpty ? state.last.path : null;
      ref.read(activeFilePathProvider.notifier).set(newActive);
    }
  }

  void updateContent(String path, String content) {
    state = state.map((f) {
      if (f.path == path) {
        return f.copyWith(content: content, isDirty: true);
      }
      return f;
    }).toList();
  }

  void markSaved(String path) {
    state = state.map((f) {
      if (f.path == path) return f.copyWith(isDirty: false);
      return f;
    }).toList();
  }
}

@Riverpod(keepAlive: true)
class ActiveFilePath extends _$ActiveFilePath {
  @override
  String? build() => null;

  void set(String? path) => state = path;
}

@Riverpod(keepAlive: true)
class WorkingDirectory extends _$WorkingDirectory {
  @override
  String? build() => null;

  void set(String? path) => state = path;
}

@riverpod
Future<void> saveFile(Ref ref, String path) async {
  final tabs = ref.read(editorTabsProvider);
  final file = tabs.firstWhere((f) => f.path == path);
  final fs = ref.read(filesystemServiceProvider);
  await fs.writeFile(path, file.content);
  ref.read(editorTabsProvider.notifier).markSaved(path);
}
