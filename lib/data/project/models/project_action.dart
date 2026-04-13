import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_action.freezed.dart';
part 'project_action.g.dart';

@freezed
abstract class ProjectAction with _$ProjectAction {
  const factory ProjectAction({required String name, required String command}) = _ProjectAction;

  factory ProjectAction.fromJson(Map<String, dynamic> json) => _$ProjectActionFromJson(json);
}
