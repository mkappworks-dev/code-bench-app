import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_file_scan_failure.freezed.dart';

@freezed
sealed class ProjectFileScanFailure with _$ProjectFileScanFailure {
  const factory ProjectFileScanFailure.scan(String message) = ProjectFileScanScan;
}
