import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/coding_tools_datasource_io.dart';
import '../models/directory_entry.dart';
import 'coding_tools_repository.dart';

part 'coding_tools_repository_impl.g.dart';

@Riverpod(keepAlive: true)
CodingToolsRepository codingToolsRepository(Ref ref) =>
    CodingToolsRepositoryImpl(datasource: CodingToolsDatasourceIo());

class CodingToolsRepositoryImpl implements CodingToolsRepository {
  CodingToolsRepositoryImpl({required CodingToolsDatasourceIo datasource}) : _ds = datasource;

  final CodingToolsDatasourceIo _ds;

  @override
  Future<String> readTextFile(String path) async {
    final bytes = await _ds.readFileBytes(path);
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw CodingToolNotTextEncodedException(path);
    }
  }

  @override
  Future<int> fileSizeBytes(String path) => _ds.fileSizeBytes(path);

  @override
  Future<bool> fileExists(String path) => _ds.fileExists(path);

  @override
  Future<bool> directoryExists(String path) => _ds.directoryExists(path);

  @override
  Future<List<DirectoryEntry>> listDirectory(String path, {required bool recursive}) =>
      _ds.listDirectoryEntries(path, recursive: recursive);
}
