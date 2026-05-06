import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_info.freezed.dart';

@freezed
abstract class UpdateInfo with _$UpdateInfo {
  const factory UpdateInfo({
    required String version,
    required String releaseNotes,
    required String downloadUrl,
    required DateTime publishedAt,
  }) = _UpdateInfo;
}
