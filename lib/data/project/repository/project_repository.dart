import '../../../data/models/project.dart';
import '../../../data/models/project_action.dart';

abstract interface class ProjectRepository {
  Stream<List<Project>> watchAllProjects();
  Future<Project> addExistingFolder(String directoryPath);
  Future<Project> createNewFolder(String parentPath, String folderName);
  Future<void> removeProject(String projectId);
  Future<void> updateProjectActions(String projectId, List<ProjectAction> actions);
  Future<void> refreshProjectStatuses();
  Future<void> refreshProjectStatus(String projectId);
  Future<void> relocateProject(String projectId, String newPath);
  Future<void> deleteAllProjects();
}
