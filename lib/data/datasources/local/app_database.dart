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
  TextColumn get localPath => text().nullable()();
  TextColumn get repositoryId => text().nullable()();
  TextColumn get activeBranch => text().nullable()();
  TextColumn get sessionIdsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

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
}

@DriftAccessor(tables: [WorkspaceProjects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Future<List<WorkspaceProjectRow>> getAllProjects() => (select(
        workspaceProjects,
      )..orderBy([(t) => OrderingTerm.desc(t.lastOpenedAt)]))
          .get();

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
  int get schemaVersion => 1;
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
