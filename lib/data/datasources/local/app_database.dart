import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

// ── Tables ──────────────────────────────────────────────────────────────────

@DataClassName('ChatSessionRow')
class ChatSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get title => text()();
  TextColumn get modelId => text()();
  TextColumn get providerId => text()();
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

@DataClassName('ChatMessageRow')
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(ChatSessions, #sessionId)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get codeBlocksJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkspaceProjectRow')
class WorkspaceProjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  BoolColumn get isGit => boolean().withDefault(const Constant(false))();
  TextColumn get currentBranch => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── DAOs ─────────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [ChatSessions, ChatMessages])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Stream<List<ChatSessionRow>> watchAllSessions() => (select(
        chatSessions,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<ChatSessionRow?> getSession(String sessionId) => (select(
        chatSessions,
      )..where((t) => t.sessionId.equals(sessionId)))
          .getSingleOrNull();

  Future<void> upsertSession(ChatSessionsCompanion session) =>
      into(chatSessions).insertOnConflictUpdate(session);

  Future<void> deleteSession(String sessionId) =>
      (delete(chatSessions)..where((t) => t.sessionId.equals(sessionId))).go();

  Future<List<ChatMessageRow>> getMessages(
    String sessionId, {
    int limit = 50,
    int offset = 0,
  }) =>
      (select(chatMessages)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
            ..limit(limit, offset: offset))
          .get();

  Future<void> insertMessage(ChatMessagesCompanion message) =>
      into(chatMessages).insert(message);

  Future<void> deleteSessionMessages(String sessionId) =>
      (delete(chatMessages)..where((t) => t.sessionId.equals(sessionId))).go();

  Stream<List<ChatSessionRow>> watchSessionsByProject(String projectId) =>
      (select(chatSessions)
            ..where((t) => t.projectId.equals(projectId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();
}

@DriftAccessor(tables: [WorkspaceProjects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Future<List<WorkspaceProjectRow>> getAllProjects() => (select(
        workspaceProjects,
      )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<WorkspaceProjectRow>> watchAllProjects() => (select(
        workspaceProjects,
      )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<WorkspaceProjectRow?> getProject(String id) => (select(
        workspaceProjects,
      )..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertProject(WorkspaceProjectsCompanion project) =>
      into(workspaceProjects).insertOnConflictUpdate(project);

  Future<void> deleteProject(String id) =>
      (delete(workspaceProjects)..where((t) => t.id.equals(id))).go();
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [ChatSessions, ChatMessages, WorkspaceProjects],
  daos: [SessionDao, ProjectDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            // Add projectId column to chat_sessions
            await migrator.addColumn(chatSessions, chatSessions.projectId);
            // Recreate workspace_projects with new schema
            await migrator.deleteTable('workspace_projects');
            await migrator.createTable(workspaceProjects);
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'code_bench');
}

// ── Provider ──────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
