import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/filesystem_datasource.dart';
import '../datasource/filesystem_datasource_io.dart';
import 'filesystem_repository.dart';

part 'filesystem_repository_impl.g.dart';

@Riverpod(keepAlive: true)
FilesystemRepository filesystemRepository(Ref ref) => FilesystemRepositoryImpl(ref.watch(filesystemDatasourceProvider));

class FilesystemRepositoryImpl implements FilesystemRepository {
  FilesystemRepositoryImpl(this._ds);

  final FilesystemDatasource _ds;

  @override
  Future<List<FileNode>> listDirectory(String dirPath) => _ds.listDirectory(dirPath);

  @override
  Future<String> readFile(String filePath) => _ds.readFile(filePath);

  @override
  Future<void> writeFile(String filePath, String content) => _ds.writeFile(filePath, content);

  @override
  Future<void> createFile(String filePath) => _ds.createFile(filePath);

  @override
  Future<void> createDirectory(String dirPath) => _ds.createDirectory(dirPath);

  @override
  Future<void> deleteFile(String filePath) => _ds.deleteFile(filePath);

  @override
  Future<void> renameFile(String oldPath, String newPath) => _ds.renameFile(oldPath, newPath);

  @override
  Stream<dynamic> watchDirectory(String dirPath) => _ds.watchDirectory(dirPath);

  @override
  String detectLanguage(String filePath) => _ds.detectLanguage(filePath);
}
