import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  // Per-session settings (v6)
  TextColumn get systemPrompt => text().nullable()();
  TextColumn get mode => text().nullable()();
  TextColumn get effort => text().nullable()();
  TextColumn get permission => text().nullable()();

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
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get actionsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── DAOs ─────────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [ChatSessions, ChatMessages])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Stream<List<ChatSessionRow>> watchAllSessions() =>
      (select(chatSessions)
            ..where((t) => t.isArchived.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<ChatSessionRow?> getSession(String sessionId) =>
      (select(chatSessions)..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();

  Future<void> upsertSession(ChatSessionsCompanion session) => into(chatSessions).insertOnConflictUpdate(session);

  Future<void> updateSession(String sessionId, ChatSessionsCompanion companion) =>
      (update(chatSessions)..where((t) => t.sessionId.equals(sessionId))).write(companion);

  Future<void> deleteSession(String sessionId) =>
      (delete(chatSessions)..where((t) => t.sessionId.equals(sessionId))).go();

  Future<List<ChatMessageRow>> getMessages(String sessionId, {int limit = 50, int offset = 0}) =>
      (select(chatMessages)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
            ..limit(limit, offset: offset))
          .get();

  Future<void> insertMessage(ChatMessagesCompanion message) => into(chatMessages).insert(message);

  Future<void> deleteMessage(String id) => (delete(chatMessages)..where((t) => t.id.equals(id))).go();

  Future<void> deleteSessionMessages(String sessionId) =>
      (delete(chatMessages)..where((t) => t.sessionId.equals(sessionId))).go();

  Stream<List<ChatSessionRow>> watchSessionsByProject(String projectId) =>
      (select(chatSessions)
            ..where((t) => t.projectId.equals(projectId) & t.isArchived.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Stream<List<ChatSessionRow>> watchArchivedSessions() =>
      (select(chatSessions)
            ..where((t) => t.isArchived.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<void> archiveSession(String id) => (update(
    chatSessions,
  )..where((t) => t.sessionId.equals(id))).write(const ChatSessionsCompanion(isArchived: Value(true)));

  Future<void> unarchiveSession(String id) => (update(
    chatSessions,
  )..where((t) => t.sessionId.equals(id))).write(const ChatSessionsCompanion(isArchived: Value(false)));

  /// Wipes every chat session and message. Used by the debug "Wipe all data"
  /// action. Messages are deleted first to satisfy the FK onto ChatSessions.
  Future<void> deleteAllSessionsAndMessages() async {
    await transaction(() async {
      await delete(chatMessages).go();
      await delete(chatSessions).go();
    });
  }
}

@DriftAccessor(tables: [WorkspaceProjects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Future<List<WorkspaceProjectRow>> getAllProjects() =>
      (select(workspaceProjects)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Stream<List<WorkspaceProjectRow>> watchAllProjects() =>
      (select(workspaceProjects)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<WorkspaceProjectRow?> getProject(String id) =>
      (select(workspaceProjects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<WorkspaceProjectRow?> getProjectByPath(String path) =>
      (select(workspaceProjects)..where((t) => t.path.equals(path))).getSingleOrNull();

  Future<void> upsertProject(WorkspaceProjectsCompanion project) =>
      into(workspaceProjects).insertOnConflictUpdate(project);

  Future<void> updateProject(String id, WorkspaceProjectsCompanion companion) =>
      (update(workspaceProjects)..where((t) => t.id.equals(id))).write(companion);

  Future<void> deleteProject(String id) => (delete(workspaceProjects)..where((t) => t.id.equals(id))).go();

  /// Wipes every workspace project. Used by the "Wipe all data" action.
  Future<void> deleteAllProjects() => delete(workspaceProjects).go();
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [ChatSessions, ChatMessages, WorkspaceProjects], daos: [SessionDao, ProjectDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 6) {
        await m.addColumn(chatSessions, chatSessions.systemPrompt);
        await m.addColumn(chatSessions, chatSessions.mode);
        await m.addColumn(chatSessions, chatSessions.effort);
        await m.addColumn(chatSessions, chatSessions.permission);
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
