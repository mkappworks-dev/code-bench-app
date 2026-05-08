import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';

part 'app_database.g.dart';

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
  TextColumn get toolEventsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get providerId => text().nullable()();
  TextColumn get modelId => text().nullable()();

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

@DataClassName('McpServerRow')
class McpServers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get transport => text()();
  TextColumn get command => text().nullable()();
  TextColumn get args => text().withDefault(const Constant('[]'))();
  TextColumn get env => text().withDefault(const Constant('{}'))();
  TextColumn get url => text().nullable()();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

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

  Future<void> deleteMessage(String sessionId, String id) =>
      (delete(chatMessages)..where((t) => t.id.equals(id) & t.sessionId.equals(sessionId))).go();

  /// Deletes [ids] from [sessionId] in a single transaction so a failure
  /// midway leaves no orphaned rows (e.g. interrupted markers without their
  /// parent user message).
  Future<void> deleteMessages(String sessionId, List<String> ids) async {
    if (ids.isEmpty) return;
    await transaction(() async {
      await (delete(chatMessages)..where((t) => t.id.isIn(ids) & t.sessionId.equals(sessionId))).go();
    });
  }

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

  Stream<List<ChatSessionRow>> watchArchivedSessionsByProject(String projectId) =>
      (select(chatSessions)
            ..where((t) => t.projectId.equals(projectId) & t.isArchived.equals(true))
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

  /// Deletes every session belonging to [projectId] (archived AND active) and
  /// their messages, in a single transaction so a mid-call failure leaves no
  /// orphans. Used by `removeProject` to fully clean up before the project row
  /// itself is dropped.
  Future<void> deleteSessionsByProject(String projectId) async {
    await transaction(() async {
      final ids = await ((select(
        chatSessions,
      )..where((t) => t.projectId.equals(projectId))).map((row) => row.sessionId)).get();
      if (ids.isEmpty) return;
      await (delete(chatMessages)..where((t) => t.sessionId.isIn(ids))).go();
      await (delete(chatSessions)..where((t) => t.projectId.equals(projectId))).go();
    });
  }

  /// Archives every active session for [projectId] in a single transaction so
  /// a mid-call failure leaves no half-archived state. Returns the IDs that
  /// were archived (callers use these to clear active-session pointers).
  Future<List<String>> archiveActiveSessionsByProject(String projectId) async {
    return transaction(() async {
      final ids = await ((select(
        chatSessions,
      )..where((t) => t.projectId.equals(projectId) & t.isArchived.equals(false))).map((row) => row.sessionId)).get();
      if (ids.isEmpty) return ids;
      await (update(
        chatSessions,
      )..where((t) => t.sessionId.isIn(ids))).write(const ChatSessionsCompanion(isArchived: Value(true)));
      return ids;
    });
  }

  /// Permanently deletes every active session for [projectId] (and their
  /// messages) in a single transaction. Archived sessions are left untouched.
  /// Returns the IDs that were deleted.
  Future<List<String>> deleteActiveSessionsByProject(String projectId) async {
    return transaction(() async {
      final ids = await ((select(
        chatSessions,
      )..where((t) => t.projectId.equals(projectId) & t.isArchived.equals(false))).map((row) => row.sessionId)).get();
      if (ids.isEmpty) return ids;
      await (delete(chatMessages)..where((t) => t.sessionId.isIn(ids))).go();
      await (delete(chatSessions)..where((t) => t.sessionId.isIn(ids))).go();
      return ids;
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

@DriftAccessor(tables: [McpServers])
class McpDao extends DatabaseAccessor<AppDatabase> with _$McpDaoMixin {
  McpDao(super.db);

  Stream<List<McpServerRow>> watchAll() =>
      (select(mcpServers)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<List<McpServerRow>> getAll() => (select(mcpServers)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<List<McpServerRow>> getEnabled() =>
      (select(mcpServers)
            ..where((t) => t.enabled.equals(1))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> upsert(McpServersCompanion companion) => into(mcpServers).insertOnConflictUpdate(companion);

  Future<void> deleteById(String id) => (delete(mcpServers)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(mcpServers).go();
}

@DriftDatabase(
  tables: [ChatSessions, ChatMessages, WorkspaceProjects, McpServers],
  daos: [SessionDao, ProjectDao, McpDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      sLog('[AppDatabase] migrating schema $from -> $to');
      if (from < 2) {
        await m.addColumn(chatMessages, chatMessages.providerId);
        await m.addColumn(chatMessages, chatMessages.modelId);
      }
    },
    // Downgrade guard: Drift skips onUpgrade when the on-disk schema is newer than the build, which would crash later with "column not found".
    beforeOpen: (details) async {
      final stored = details.versionBefore;
      if (stored != null && stored > details.versionNow) {
        sLog('[AppDatabase] db schema (v$stored) is ahead of code (v${details.versionNow}) — refusing to run');
        throw StateError(
          'Database schema (v$stored) is newer than this build (v${details.versionNow}). '
          'Update the app, or remove the local db to start fresh.',
        );
      }
    },
  );
}

QueryExecutor _openConnection() {
  // The DB lives in ~/Library/Application Support/<bundle-id>/, not ~/Documents.
  // Non-sandboxed macOS resolves getApplicationDocumentsDirectory() to the
  // user-visible Documents folder, which is TCC-gated and kills the process
  // when NSDocumentsFolderUsageDescription is absent.
  return driftDatabase(
    name: 'code_bench',
    native: DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
  );
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
