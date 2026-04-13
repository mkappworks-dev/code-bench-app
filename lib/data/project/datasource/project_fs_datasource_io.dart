import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'project_fs_datasource.dart';

part 'project_fs_datasource_io.g.dart';

@Riverpod(keepAlive: true)
ProjectFsDatasource projectFsDatasource(Ref ref) => ProjectFsDatasourceIo();

class ProjectFsDatasourceIo implements ProjectFsDatasource {
  @override
  bool exists(String path) => Directory(path).existsSync();

  @override
  Future<void> createDirectory(String path) => Directory(path).create(recursive: true);
}
