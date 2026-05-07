// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$SessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChatSessionsTable get chatSessions => attachedDatabase.chatSessions;
  $ChatMessagesTable get chatMessages => attachedDatabase.chatMessages;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db.attachedDatabase, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db.attachedDatabase, _db.chatMessages);
}

mixin _$ProjectDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspaceProjectsTable get workspaceProjects => attachedDatabase.workspaceProjects;
  ProjectDaoManager get managers => ProjectDaoManager(this);
}

class ProjectDaoManager {
  final _$ProjectDaoMixin _db;
  ProjectDaoManager(this._db);
  $$WorkspaceProjectsTableTableManager get workspaceProjects =>
      $$WorkspaceProjectsTableTableManager(_db.attachedDatabase, _db.workspaceProjects);
}

mixin _$McpDaoMixin on DatabaseAccessor<AppDatabase> {
  $McpServersTable get mcpServers => attachedDatabase.mcpServers;
  McpDaoManager get managers => McpDaoManager(this);
}

class McpDaoManager {
  final _$McpDaoMixin _db;
  McpDaoManager(this._db);
  $$McpServersTableTableManager get mcpServers => $$McpServersTableTableManager(_db.attachedDatabase, _db.mcpServers);
}

class $ChatSessionsTable extends ChatSessions with TableInfo<$ChatSessionsTable, ChatSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _systemPromptMeta = const VerificationMeta('systemPrompt');
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
    'system_prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effortMeta = const VerificationMeta('effort');
  @override
  late final GeneratedColumn<String> effort = GeneratedColumn<String>(
    'effort',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _permissionMeta = const VerificationMeta('permission');
  @override
  late final GeneratedColumn<String> permission = GeneratedColumn<String>(
    'permission',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    title,
    modelId,
    providerId,
    projectId,
    createdAt,
    updatedAt,
    isPinned,
    isArchived,
    systemPrompt,
    mode,
    effort,
    permission,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ChatSessionRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta, sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta, modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(_providerIdMeta, providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta, projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta, isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(_isArchivedMeta, isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('system_prompt')) {
      context.handle(_systemPromptMeta, systemPrompt.isAcceptableOrUnknown(data['system_prompt']!, _systemPromptMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(_modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    }
    if (data.containsKey('effort')) {
      context.handle(_effortMeta, effort.isAcceptableOrUnknown(data['effort']!, _effortMeta));
    }
    if (data.containsKey('permission')) {
      context.handle(_permissionMeta, permission.isAcceptableOrUnknown(data['permission']!, _permissionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  ChatSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSessionRow(
      sessionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      modelId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      providerId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      projectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}project_id']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isPinned: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      isArchived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      systemPrompt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}system_prompt']),
      mode: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}mode']),
      effort: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}effort']),
      permission: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}permission']),
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }
}

class ChatSessionRow extends DataClass implements Insertable<ChatSessionRow> {
  final String sessionId;
  final String title;
  final String modelId;
  final String providerId;
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;
  final String? systemPrompt;
  final String? mode;
  final String? effort;
  final String? permission;
  const ChatSessionRow({
    required this.sessionId,
    required this.title,
    required this.modelId,
    required this.providerId,
    this.projectId,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.isArchived,
    this.systemPrompt,
    this.mode,
    this.effort,
    this.permission,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['title'] = Variable<String>(title);
    map['model_id'] = Variable<String>(modelId);
    map['provider_id'] = Variable<String>(providerId);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || systemPrompt != null) {
      map['system_prompt'] = Variable<String>(systemPrompt);
    }
    if (!nullToAbsent || mode != null) {
      map['mode'] = Variable<String>(mode);
    }
    if (!nullToAbsent || effort != null) {
      map['effort'] = Variable<String>(effort);
    }
    if (!nullToAbsent || permission != null) {
      map['permission'] = Variable<String>(permission);
    }
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      sessionId: Value(sessionId),
      title: Value(title),
      modelId: Value(modelId),
      providerId: Value(providerId),
      projectId: projectId == null && nullToAbsent ? const Value.absent() : Value(projectId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      systemPrompt: systemPrompt == null && nullToAbsent ? const Value.absent() : Value(systemPrompt),
      mode: mode == null && nullToAbsent ? const Value.absent() : Value(mode),
      effort: effort == null && nullToAbsent ? const Value.absent() : Value(effort),
      permission: permission == null && nullToAbsent ? const Value.absent() : Value(permission),
    );
  }

  factory ChatSessionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSessionRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      title: serializer.fromJson<String>(json['title']),
      modelId: serializer.fromJson<String>(json['modelId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      systemPrompt: serializer.fromJson<String?>(json['systemPrompt']),
      mode: serializer.fromJson<String?>(json['mode']),
      effort: serializer.fromJson<String?>(json['effort']),
      permission: serializer.fromJson<String?>(json['permission']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'title': serializer.toJson<String>(title),
      'modelId': serializer.toJson<String>(modelId),
      'providerId': serializer.toJson<String>(providerId),
      'projectId': serializer.toJson<String?>(projectId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isArchived': serializer.toJson<bool>(isArchived),
      'systemPrompt': serializer.toJson<String?>(systemPrompt),
      'mode': serializer.toJson<String?>(mode),
      'effort': serializer.toJson<String?>(effort),
      'permission': serializer.toJson<String?>(permission),
    };
  }

  ChatSessionRow copyWith({
    String? sessionId,
    String? title,
    String? modelId,
    String? providerId,
    Value<String?> projectId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    Value<String?> systemPrompt = const Value.absent(),
    Value<String?> mode = const Value.absent(),
    Value<String?> effort = const Value.absent(),
    Value<String?> permission = const Value.absent(),
  }) => ChatSessionRow(
    sessionId: sessionId ?? this.sessionId,
    title: title ?? this.title,
    modelId: modelId ?? this.modelId,
    providerId: providerId ?? this.providerId,
    projectId: projectId.present ? projectId.value : this.projectId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    systemPrompt: systemPrompt.present ? systemPrompt.value : this.systemPrompt,
    mode: mode.present ? mode.value : this.mode,
    effort: effort.present ? effort.value : this.effort,
    permission: permission.present ? permission.value : this.permission,
  );
  ChatSessionRow copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSessionRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      title: data.title.present ? data.title.value : this.title,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      providerId: data.providerId.present ? data.providerId.value : this.providerId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isArchived: data.isArchived.present ? data.isArchived.value : this.isArchived,
      systemPrompt: data.systemPrompt.present ? data.systemPrompt.value : this.systemPrompt,
      mode: data.mode.present ? data.mode.value : this.mode,
      effort: data.effort.present ? data.effort.value : this.effort,
      permission: data.permission.present ? data.permission.value : this.permission,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionRow(')
          ..write('sessionId: $sessionId, ')
          ..write('title: $title, ')
          ..write('modelId: $modelId, ')
          ..write('providerId: $providerId, ')
          ..write('projectId: $projectId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('mode: $mode, ')
          ..write('effort: $effort, ')
          ..write('permission: $permission')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    title,
    modelId,
    providerId,
    projectId,
    createdAt,
    updatedAt,
    isPinned,
    isArchived,
    systemPrompt,
    mode,
    effort,
    permission,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSessionRow &&
          other.sessionId == this.sessionId &&
          other.title == this.title &&
          other.modelId == this.modelId &&
          other.providerId == this.providerId &&
          other.projectId == this.projectId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isPinned == this.isPinned &&
          other.isArchived == this.isArchived &&
          other.systemPrompt == this.systemPrompt &&
          other.mode == this.mode &&
          other.effort == this.effort &&
          other.permission == this.permission);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSessionRow> {
  final Value<String> sessionId;
  final Value<String> title;
  final Value<String> modelId;
  final Value<String> providerId;
  final Value<String?> projectId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isPinned;
  final Value<bool> isArchived;
  final Value<String?> systemPrompt;
  final Value<String?> mode;
  final Value<String?> effort;
  final Value<String?> permission;
  final Value<int> rowid;
  const ChatSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.title = const Value.absent(),
    this.modelId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.mode = const Value.absent(),
    this.effort = const Value.absent(),
    this.permission = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    required String sessionId,
    required String title,
    required String modelId,
    required String providerId,
    this.projectId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.mode = const Value.absent(),
    this.effort = const Value.absent(),
    this.permission = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       title = Value(title),
       modelId = Value(modelId),
       providerId = Value(providerId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ChatSessionRow> custom({
    Expression<String>? sessionId,
    Expression<String>? title,
    Expression<String>? modelId,
    Expression<String>? providerId,
    Expression<String>? projectId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isPinned,
    Expression<bool>? isArchived,
    Expression<String>? systemPrompt,
    Expression<String>? mode,
    Expression<String>? effort,
    Expression<String>? permission,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (title != null) 'title': title,
      if (modelId != null) 'model_id': modelId,
      if (providerId != null) 'provider_id': providerId,
      if (projectId != null) 'project_id': projectId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isArchived != null) 'is_archived': isArchived,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (mode != null) 'mode': mode,
      if (effort != null) 'effort': effort,
      if (permission != null) 'permission': permission,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? title,
    Value<String>? modelId,
    Value<String>? providerId,
    Value<String?>? projectId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isPinned,
    Value<bool>? isArchived,
    Value<String?>? systemPrompt,
    Value<String?>? mode,
    Value<String?>? effort,
    Value<String?>? permission,
    Value<int>? rowid,
  }) {
    return ChatSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      modelId: modelId ?? this.modelId,
      providerId: providerId ?? this.providerId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      mode: mode ?? this.mode,
      effort: effort ?? this.effort,
      permission: permission ?? this.permission,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (effort.present) {
      map['effort'] = Variable<String>(effort.value);
    }
    if (permission.present) {
      map['permission'] = Variable<String>(permission.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('title: $title, ')
          ..write('modelId: $modelId, ')
          ..write('providerId: $providerId, ')
          ..write('projectId: $projectId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('mode: $mode, ')
          ..write('effort: $effort, ')
          ..write('permission: $permission, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES chat_sessions (session_id)'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeBlocksJsonMeta = const VerificationMeta('codeBlocksJson');
  @override
  late final GeneratedColumn<String> codeBlocksJson = GeneratedColumn<String>(
    'code_blocks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _toolEventsJsonMeta = const VerificationMeta('toolEventsJson');
  @override
  late final GeneratedColumn<String> toolEventsJson = GeneratedColumn<String>(
    'tool_events_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    role,
    content,
    codeBlocksJson,
    toolEventsJson,
    timestamp,
    providerId,
    modelId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessageRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta, sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(_roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('code_blocks_json')) {
      context.handle(
        _codeBlocksJsonMeta,
        codeBlocksJson.isAcceptableOrUnknown(data['code_blocks_json']!, _codeBlocksJsonMeta),
      );
    }
    if (data.containsKey('tool_events_json')) {
      context.handle(
        _toolEventsJsonMeta,
        toolEventsJson.isAcceptableOrUnknown(data['tool_events_json']!, _toolEventsJsonMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta, timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(_providerIdMeta, providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta));
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta, modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      role: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      codeBlocksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_blocks_json'],
      )!,
      toolEventsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_events_json'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      providerId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}provider_id']),
      modelId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}model_id']),
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String codeBlocksJson;
  final String toolEventsJson;
  final DateTime timestamp;
  final String? providerId;
  final String? modelId;
  const ChatMessageRow({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.codeBlocksJson,
    required this.toolEventsJson,
    required this.timestamp,
    this.providerId,
    this.modelId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['code_blocks_json'] = Variable<String>(codeBlocksJson);
    map['tool_events_json'] = Variable<String>(toolEventsJson);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      role: Value(role),
      content: Value(content),
      codeBlocksJson: Value(codeBlocksJson),
      toolEventsJson: Value(toolEventsJson),
      timestamp: Value(timestamp),
      providerId: providerId == null && nullToAbsent ? const Value.absent() : Value(providerId),
      modelId: modelId == null && nullToAbsent ? const Value.absent() : Value(modelId),
    );
  }

  factory ChatMessageRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      codeBlocksJson: serializer.fromJson<String>(json['codeBlocksJson']),
      toolEventsJson: serializer.fromJson<String>(json['toolEventsJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      modelId: serializer.fromJson<String?>(json['modelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'codeBlocksJson': serializer.toJson<String>(codeBlocksJson),
      'toolEventsJson': serializer.toJson<String>(toolEventsJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'providerId': serializer.toJson<String?>(providerId),
      'modelId': serializer.toJson<String?>(modelId),
    };
  }

  ChatMessageRow copyWith({
    String? id,
    String? sessionId,
    String? role,
    String? content,
    String? codeBlocksJson,
    String? toolEventsJson,
    DateTime? timestamp,
    Value<String?> providerId = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
  }) => ChatMessageRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    role: role ?? this.role,
    content: content ?? this.content,
    codeBlocksJson: codeBlocksJson ?? this.codeBlocksJson,
    toolEventsJson: toolEventsJson ?? this.toolEventsJson,
    timestamp: timestamp ?? this.timestamp,
    providerId: providerId.present ? providerId.value : this.providerId,
    modelId: modelId.present ? modelId.value : this.modelId,
  );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      codeBlocksJson: data.codeBlocksJson.present ? data.codeBlocksJson.value : this.codeBlocksJson,
      toolEventsJson: data.toolEventsJson.present ? data.toolEventsJson.value : this.toolEventsJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      providerId: data.providerId.present ? data.providerId.value : this.providerId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('codeBlocksJson: $codeBlocksJson, ')
          ..write('toolEventsJson: $toolEventsJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, role, content, codeBlocksJson, toolEventsJson, timestamp, providerId, modelId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.codeBlocksJson == this.codeBlocksJson &&
          other.toolEventsJson == this.toolEventsJson &&
          other.timestamp == this.timestamp &&
          other.providerId == this.providerId &&
          other.modelId == this.modelId);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> codeBlocksJson;
  final Value<String> toolEventsJson;
  final Value<DateTime> timestamp;
  final Value<String?> providerId;
  final Value<String?> modelId;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.codeBlocksJson = const Value.absent(),
    this.toolEventsJson = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required String role,
    required String content,
    this.codeBlocksJson = const Value.absent(),
    this.toolEventsJson = const Value.absent(),
    required DateTime timestamp,
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       role = Value(role),
       content = Value(content),
       timestamp = Value(timestamp);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? codeBlocksJson,
    Expression<String>? toolEventsJson,
    Expression<DateTime>? timestamp,
    Expression<String>? providerId,
    Expression<String>? modelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (codeBlocksJson != null) 'code_blocks_json': codeBlocksJson,
      if (toolEventsJson != null) 'tool_events_json': toolEventsJson,
      if (timestamp != null) 'timestamp': timestamp,
      if (providerId != null) 'provider_id': providerId,
      if (modelId != null) 'model_id': modelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? role,
    Value<String>? content,
    Value<String>? codeBlocksJson,
    Value<String>? toolEventsJson,
    Value<DateTime>? timestamp,
    Value<String?>? providerId,
    Value<String?>? modelId,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      codeBlocksJson: codeBlocksJson ?? this.codeBlocksJson,
      toolEventsJson: toolEventsJson ?? this.toolEventsJson,
      timestamp: timestamp ?? this.timestamp,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (codeBlocksJson.present) {
      map['code_blocks_json'] = Variable<String>(codeBlocksJson.value);
    }
    if (toolEventsJson.present) {
      map['tool_events_json'] = Variable<String>(toolEventsJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('codeBlocksJson: $codeBlocksJson, ')
          ..write('toolEventsJson: $toolEventsJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspaceProjectsTable extends WorkspaceProjects with TableInfo<$WorkspaceProjectsTable, WorkspaceProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspaceProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _actionsJsonMeta = const VerificationMeta('actionsJson');
  @override
  late final GeneratedColumn<String> actionsJson = GeneratedColumn<String>(
    'actions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, path, createdAt, sortOrder, actionsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_projects';
  @override
  VerificationContext validateIntegrity(Insertable<WorkspaceProjectRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('actions_json')) {
      context.handle(_actionsJsonMeta, actionsJson.isAcceptableOrUnknown(data['actions_json']!, _actionsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceProjectRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      actionsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}actions_json'])!,
    );
  }

  @override
  $WorkspaceProjectsTable createAlias(String alias) {
    return $WorkspaceProjectsTable(attachedDatabase, alias);
  }
}

class WorkspaceProjectRow extends DataClass implements Insertable<WorkspaceProjectRow> {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final int sortOrder;
  final String actionsJson;
  const WorkspaceProjectRow({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.sortOrder,
    required this.actionsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    map['actions_json'] = Variable<String>(actionsJson);
    return map;
  }

  WorkspaceProjectsCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceProjectsCompanion(
      id: Value(id),
      name: Value(name),
      path: Value(path),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
      actionsJson: Value(actionsJson),
    );
  }

  factory WorkspaceProjectRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceProjectRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      actionsJson: serializer.fromJson<String>(json['actionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'actionsJson': serializer.toJson<String>(actionsJson),
    };
  }

  WorkspaceProjectRow copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    int? sortOrder,
    String? actionsJson,
  }) => WorkspaceProjectRow(
    id: id ?? this.id,
    name: name ?? this.name,
    path: path ?? this.path,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
    actionsJson: actionsJson ?? this.actionsJson,
  );
  WorkspaceProjectRow copyWithCompanion(WorkspaceProjectsCompanion data) {
    return WorkspaceProjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      actionsJson: data.actionsJson.present ? data.actionsJson.value : this.actionsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceProjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('actionsJson: $actionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, path, createdAt, sortOrder, actionsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceProjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.path == this.path &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder &&
          other.actionsJson == this.actionsJson);
}

class WorkspaceProjectsCompanion extends UpdateCompanion<WorkspaceProjectRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> path;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  final Value<String> actionsJson;
  final Value<int> rowid;
  const WorkspaceProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.actionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceProjectsCompanion.insert({
    required String id,
    required String name,
    required String path,
    required DateTime createdAt,
    this.sortOrder = const Value.absent(),
    this.actionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       path = Value(path),
       createdAt = Value(createdAt);
  static Insertable<WorkspaceProjectRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? path,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
    Expression<String>? actionsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (actionsJson != null) 'actions_json': actionsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? path,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
    Value<String>? actionsJson,
    Value<int>? rowid,
  }) {
    return WorkspaceProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      actionsJson: actionsJson ?? this.actionsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (actionsJson.present) {
      map['actions_json'] = Variable<String>(actionsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('actionsJson: $actionsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $McpServersTable extends McpServers with TableInfo<$McpServersTable, McpServerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $McpServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transportMeta = const VerificationMeta('transport');
  @override
  late final GeneratedColumn<String> transport = GeneratedColumn<String>(
    'transport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commandMeta = const VerificationMeta('command');
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _argsMeta = const VerificationMeta('args');
  @override
  late final GeneratedColumn<String> args = GeneratedColumn<String>(
    'args',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _envMeta = const VerificationMeta('env');
  @override
  late final GeneratedColumn<String> env = GeneratedColumn<String>(
    'env',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, transport, command, args, env, url, enabled, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mcp_servers';
  @override
  VerificationContext validateIntegrity(Insertable<McpServerRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('transport')) {
      context.handle(_transportMeta, transport.isAcceptableOrUnknown(data['transport']!, _transportMeta));
    } else if (isInserting) {
      context.missing(_transportMeta);
    }
    if (data.containsKey('command')) {
      context.handle(_commandMeta, command.isAcceptableOrUnknown(data['command']!, _commandMeta));
    }
    if (data.containsKey('args')) {
      context.handle(_argsMeta, args.isAcceptableOrUnknown(data['args']!, _argsMeta));
    }
    if (data.containsKey('env')) {
      context.handle(_envMeta, env.isAcceptableOrUnknown(data['env']!, _envMeta));
    }
    if (data.containsKey('url')) {
      context.handle(_urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta, enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  McpServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return McpServerRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      transport: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transport'])!,
      command: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}command']),
      args: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}args'])!,
      env: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}env'])!,
      url: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}url']),
      enabled: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}enabled'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $McpServersTable createAlias(String alias) {
    return $McpServersTable(attachedDatabase, alias);
  }
}

class McpServerRow extends DataClass implements Insertable<McpServerRow> {
  final String id;
  final String name;
  final String transport;
  final String? command;
  final String args;
  final String env;
  final String? url;
  final int enabled;
  final int sortOrder;
  const McpServerRow({
    required this.id,
    required this.name,
    required this.transport,
    this.command,
    required this.args,
    required this.env,
    this.url,
    required this.enabled,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['transport'] = Variable<String>(transport);
    if (!nullToAbsent || command != null) {
      map['command'] = Variable<String>(command);
    }
    map['args'] = Variable<String>(args);
    map['env'] = Variable<String>(env);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['enabled'] = Variable<int>(enabled);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  McpServersCompanion toCompanion(bool nullToAbsent) {
    return McpServersCompanion(
      id: Value(id),
      name: Value(name),
      transport: Value(transport),
      command: command == null && nullToAbsent ? const Value.absent() : Value(command),
      args: Value(args),
      env: Value(env),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      enabled: Value(enabled),
      sortOrder: Value(sortOrder),
    );
  }

  factory McpServerRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return McpServerRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      transport: serializer.fromJson<String>(json['transport']),
      command: serializer.fromJson<String?>(json['command']),
      args: serializer.fromJson<String>(json['args']),
      env: serializer.fromJson<String>(json['env']),
      url: serializer.fromJson<String?>(json['url']),
      enabled: serializer.fromJson<int>(json['enabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'transport': serializer.toJson<String>(transport),
      'command': serializer.toJson<String?>(command),
      'args': serializer.toJson<String>(args),
      'env': serializer.toJson<String>(env),
      'url': serializer.toJson<String?>(url),
      'enabled': serializer.toJson<int>(enabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  McpServerRow copyWith({
    String? id,
    String? name,
    String? transport,
    Value<String?> command = const Value.absent(),
    String? args,
    String? env,
    Value<String?> url = const Value.absent(),
    int? enabled,
    int? sortOrder,
  }) => McpServerRow(
    id: id ?? this.id,
    name: name ?? this.name,
    transport: transport ?? this.transport,
    command: command.present ? command.value : this.command,
    args: args ?? this.args,
    env: env ?? this.env,
    url: url.present ? url.value : this.url,
    enabled: enabled ?? this.enabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  McpServerRow copyWithCompanion(McpServersCompanion data) {
    return McpServerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      transport: data.transport.present ? data.transport.value : this.transport,
      command: data.command.present ? data.command.value : this.command,
      args: data.args.present ? data.args.value : this.args,
      env: data.env.present ? data.env.value : this.env,
      url: data.url.present ? data.url.value : this.url,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('McpServerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('transport: $transport, ')
          ..write('command: $command, ')
          ..write('args: $args, ')
          ..write('env: $env, ')
          ..write('url: $url, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, transport, command, args, env, url, enabled, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpServerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.transport == this.transport &&
          other.command == this.command &&
          other.args == this.args &&
          other.env == this.env &&
          other.url == this.url &&
          other.enabled == this.enabled &&
          other.sortOrder == this.sortOrder);
}

class McpServersCompanion extends UpdateCompanion<McpServerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> transport;
  final Value<String?> command;
  final Value<String> args;
  final Value<String> env;
  final Value<String?> url;
  final Value<int> enabled;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const McpServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.transport = const Value.absent(),
    this.command = const Value.absent(),
    this.args = const Value.absent(),
    this.env = const Value.absent(),
    this.url = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  McpServersCompanion.insert({
    required String id,
    required String name,
    required String transport,
    this.command = const Value.absent(),
    this.args = const Value.absent(),
    this.env = const Value.absent(),
    this.url = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       transport = Value(transport);
  static Insertable<McpServerRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? transport,
    Expression<String>? command,
    Expression<String>? args,
    Expression<String>? env,
    Expression<String>? url,
    Expression<int>? enabled,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (transport != null) 'transport': transport,
      if (command != null) 'command': command,
      if (args != null) 'args': args,
      if (env != null) 'env': env,
      if (url != null) 'url': url,
      if (enabled != null) 'enabled': enabled,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  McpServersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? transport,
    Value<String?>? command,
    Value<String>? args,
    Value<String>? env,
    Value<String?>? url,
    Value<int>? enabled,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return McpServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      transport: transport ?? this.transport,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      url: url ?? this.url,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (transport.present) {
      map['transport'] = Variable<String>(transport.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (args.present) {
      map['args'] = Variable<String>(args.value);
    }
    if (env.present) {
      map['env'] = Variable<String>(env.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<int>(enabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('McpServersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('transport: $transport, ')
          ..write('command: $command, ')
          ..write('args: $args, ')
          ..write('env: $env, ')
          ..write('url: $url, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $WorkspaceProjectsTable workspaceProjects = $WorkspaceProjectsTable(this);
  late final $McpServersTable mcpServers = $McpServersTable(this);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  late final ProjectDao projectDao = ProjectDao(this as AppDatabase);
  late final McpDao mcpDao = McpDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [chatSessions, chatMessages, workspaceProjects, mcpServers];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ChatSessionsTableCreateCompanionBuilder =
    ChatSessionsCompanion Function({
      required String sessionId,
      required String title,
      required String modelId,
      required String providerId,
      Value<String?> projectId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isPinned,
      Value<bool> isArchived,
      Value<String?> systemPrompt,
      Value<String?> mode,
      Value<String?> effort,
      Value<String?> permission,
      Value<int> rowid,
    });
typedef $$ChatSessionsTableUpdateCompanionBuilder =
    ChatSessionsCompanion Function({
      Value<String> sessionId,
      Value<String> title,
      Value<String> modelId,
      Value<String> providerId,
      Value<String?> projectId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isPinned,
      Value<bool> isArchived,
      Value<String?> systemPrompt,
      Value<String?> mode,
      Value<String?> effort,
      Value<String?> permission,
      Value<int> rowid,
    });

final class $$ChatSessionsTableReferences extends BaseReferences<_$AppDatabase, $ChatSessionsTable, ChatSessionRow> {
  $$ChatSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessageRow>> _chatMessagesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.chatMessages,
        aliasName: $_aliasNameGenerator(db.chatSessions.sessionId, db.chatMessages.sessionId),
      );

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager(
      $_db,
      $_db.chatMessages,
    ).filter((f) => f.sessionId.sessionId.sqlEquals($_itemColumn<String>('session_id')!));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChatSessionsTableFilterComposer extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId =>
      $composableBuilder(column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived =>
      $composableBuilder(column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPrompt =>
      $composableBuilder(column: $table.systemPrompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permission =>
      $composableBuilder(column: $table.permission, builder: (column) => ColumnFilters(column));

  Expression<bool> chatMessagesRefs(Expression<bool> Function($$ChatMessagesTableFilterComposer f) f) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ChatMessagesTableFilterComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableOrderingComposer extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId =>
      $composableBuilder(column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived =>
      $composableBuilder(column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPrompt =>
      $composableBuilder(column: $table.systemPrompt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permission =>
      $composableBuilder(column: $table.permission, builder: (column) => ColumnOrderings(column));
}

class $$ChatSessionsTableAnnotationComposer extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId => $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get modelId => $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get projectId => $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPinned => $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt =>
      $composableBuilder(column: $table.systemPrompt, builder: (column) => column);

  GeneratedColumn<String> get mode => $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get effort => $composableBuilder(column: $table.effort, builder: (column) => column);

  GeneratedColumn<String> get permission => $composableBuilder(column: $table.permission, builder: (column) => column);

  Expression<T> chatMessagesRefs<T extends Object>(Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ChatMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatSessionsTable,
          ChatSessionRow,
          $$ChatSessionsTableFilterComposer,
          $$ChatSessionsTableOrderingComposer,
          $$ChatSessionsTableAnnotationComposer,
          $$ChatSessionsTableCreateCompanionBuilder,
          $$ChatSessionsTableUpdateCompanionBuilder,
          (ChatSessionRow, $$ChatSessionsTableReferences),
          ChatSessionRow,
          PrefetchHooks Function({bool chatMessagesRefs})
        > {
  $$ChatSessionsTableTableManager(_$AppDatabase db, $ChatSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> systemPrompt = const Value.absent(),
                Value<String?> mode = const Value.absent(),
                Value<String?> effort = const Value.absent(),
                Value<String?> permission = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSessionsCompanion(
                sessionId: sessionId,
                title: title,
                modelId: modelId,
                providerId: providerId,
                projectId: projectId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPinned: isPinned,
                isArchived: isArchived,
                systemPrompt: systemPrompt,
                mode: mode,
                effort: effort,
                permission: permission,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String title,
                required String modelId,
                required String providerId,
                Value<String?> projectId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> systemPrompt = const Value.absent(),
                Value<String?> mode = const Value.absent(),
                Value<String?> effort = const Value.absent(),
                Value<String?> permission = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSessionsCompanion.insert(
                sessionId: sessionId,
                title: title,
                modelId: modelId,
                providerId: providerId,
                projectId: projectId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPinned: isPinned,
                isArchived: isArchived,
                systemPrompt: systemPrompt,
                mode: mode,
                effort: effort,
                permission: permission,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$ChatSessionsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({chatMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatMessagesRefs) db.chatMessages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatMessagesRefs)
                    await $_getPrefetchedData<ChatSessionRow, $ChatSessionsTable, ChatMessageRow>(
                      currentTable: table,
                      referencedTable: $$ChatSessionsTableReferences._chatMessagesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ChatSessionsTableReferences(db, table, p0).chatMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.sessionId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChatSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatSessionsTable,
      ChatSessionRow,
      $$ChatSessionsTableFilterComposer,
      $$ChatSessionsTableOrderingComposer,
      $$ChatSessionsTableAnnotationComposer,
      $$ChatSessionsTableCreateCompanionBuilder,
      $$ChatSessionsTableUpdateCompanionBuilder,
      (ChatSessionRow, $$ChatSessionsTableReferences),
      ChatSessionRow,
      PrefetchHooks Function({bool chatMessagesRefs})
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required String sessionId,
      required String role,
      required String content,
      Value<String> codeBlocksJson,
      Value<String> toolEventsJson,
      required DateTime timestamp,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> role,
      Value<String> content,
      Value<String> codeBlocksJson,
      Value<String> toolEventsJson,
      Value<DateTime> timestamp,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<int> rowid,
    });

final class $$ChatMessagesTableReferences extends BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.chatSessions.createAlias($_aliasNameGenerator(db.chatMessages.sessionId, db.chatSessions.sessionId));

  $$ChatSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$ChatSessionsTableTableManager(
      $_db,
      $_db.chatSessions,
    ).filter((f) => f.sessionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChatMessagesTableFilterComposer extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codeBlocksJson =>
      $composableBuilder(column: $table.codeBlocksJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toolEventsJson =>
      $composableBuilder(column: $table.toolEventsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId =>
      $composableBuilder(column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => ColumnFilters(column));

  $$ChatSessionsTableFilterComposer get sessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ChatSessionsTableFilterComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableOrderingComposer extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codeBlocksJson =>
      $composableBuilder(column: $table.codeBlocksJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toolEventsJson =>
      $composableBuilder(column: $table.toolEventsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId =>
      $composableBuilder(column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => ColumnOrderings(column));

  $$ChatSessionsTableOrderingComposer get sessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ChatSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role => $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content => $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get codeBlocksJson =>
      $composableBuilder(column: $table.codeBlocksJson, builder: (column) => column);

  GeneratedColumn<String> get toolEventsJson =>
      $composableBuilder(column: $table.toolEventsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp => $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get modelId => $composableBuilder(column: $table.modelId, builder: (column) => column);

  $$ChatSessionsTableAnnotationComposer get sessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ChatSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessageRow,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (ChatMessageRow, $$ChatMessagesTableReferences),
          ChatMessageRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> codeBlocksJson = const Value.absent(),
                Value<String> toolEventsJson = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                sessionId: sessionId,
                role: role,
                content: content,
                codeBlocksJson: codeBlocksJson,
                toolEventsJson: toolEventsJson,
                timestamp: timestamp,
                providerId: providerId,
                modelId: modelId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String role,
                required String content,
                Value<String> codeBlocksJson = const Value.absent(),
                Value<String> toolEventsJson = const Value.absent(),
                required DateTime timestamp,
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                role: role,
                content: content,
                codeBlocksJson: codeBlocksJson,
                toolEventsJson: toolEventsJson,
                timestamp: timestamp,
                providerId: providerId,
                modelId: modelId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$ChatMessagesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$ChatMessagesTableReferences._sessionIdTable(db),
                                referencedColumn: $$ChatMessagesTableReferences._sessionIdTable(db).sessionId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessageRow,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (ChatMessageRow, $$ChatMessagesTableReferences),
      ChatMessageRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$WorkspaceProjectsTableCreateCompanionBuilder =
    WorkspaceProjectsCompanion Function({
      required String id,
      required String name,
      required String path,
      required DateTime createdAt,
      Value<int> sortOrder,
      Value<String> actionsJson,
      Value<int> rowid,
    });
typedef $$WorkspaceProjectsTableUpdateCompanionBuilder =
    WorkspaceProjectsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> path,
      Value<DateTime> createdAt,
      Value<int> sortOrder,
      Value<String> actionsJson,
      Value<int> rowid,
    });

class $$WorkspaceProjectsTableFilterComposer extends Composer<_$AppDatabase, $WorkspaceProjectsTable> {
  $$WorkspaceProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionsJson =>
      $composableBuilder(column: $table.actionsJson, builder: (column) => ColumnFilters(column));
}

class $$WorkspaceProjectsTableOrderingComposer extends Composer<_$AppDatabase, $WorkspaceProjectsTable> {
  $$WorkspaceProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionsJson =>
      $composableBuilder(column: $table.actionsJson, builder: (column) => ColumnOrderings(column));
}

class $$WorkspaceProjectsTableAnnotationComposer extends Composer<_$AppDatabase, $WorkspaceProjectsTable> {
  $$WorkspaceProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get actionsJson =>
      $composableBuilder(column: $table.actionsJson, builder: (column) => column);
}

class $$WorkspaceProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspaceProjectsTable,
          WorkspaceProjectRow,
          $$WorkspaceProjectsTableFilterComposer,
          $$WorkspaceProjectsTableOrderingComposer,
          $$WorkspaceProjectsTableAnnotationComposer,
          $$WorkspaceProjectsTableCreateCompanionBuilder,
          $$WorkspaceProjectsTableUpdateCompanionBuilder,
          (WorkspaceProjectRow, BaseReferences<_$AppDatabase, $WorkspaceProjectsTable, WorkspaceProjectRow>),
          WorkspaceProjectRow,
          PrefetchHooks Function()
        > {
  $$WorkspaceProjectsTableTableManager(_$AppDatabase db, $WorkspaceProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WorkspaceProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WorkspaceProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WorkspaceProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> actionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceProjectsCompanion(
                id: id,
                name: name,
                path: path,
                createdAt: createdAt,
                sortOrder: sortOrder,
                actionsJson: actionsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String path,
                required DateTime createdAt,
                Value<int> sortOrder = const Value.absent(),
                Value<String> actionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceProjectsCompanion.insert(
                id: id,
                name: name,
                path: path,
                createdAt: createdAt,
                sortOrder: sortOrder,
                actionsJson: actionsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkspaceProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspaceProjectsTable,
      WorkspaceProjectRow,
      $$WorkspaceProjectsTableFilterComposer,
      $$WorkspaceProjectsTableOrderingComposer,
      $$WorkspaceProjectsTableAnnotationComposer,
      $$WorkspaceProjectsTableCreateCompanionBuilder,
      $$WorkspaceProjectsTableUpdateCompanionBuilder,
      (WorkspaceProjectRow, BaseReferences<_$AppDatabase, $WorkspaceProjectsTable, WorkspaceProjectRow>),
      WorkspaceProjectRow,
      PrefetchHooks Function()
    >;
typedef $$McpServersTableCreateCompanionBuilder =
    McpServersCompanion Function({
      required String id,
      required String name,
      required String transport,
      Value<String?> command,
      Value<String> args,
      Value<String> env,
      Value<String?> url,
      Value<int> enabled,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$McpServersTableUpdateCompanionBuilder =
    McpServersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> transport,
      Value<String?> command,
      Value<String> args,
      Value<String> env,
      Value<String?> url,
      Value<int> enabled,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$McpServersTableFilterComposer extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transport =>
      $composableBuilder(column: $table.transport, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get args => $composableBuilder(column: $table.args, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get env => $composableBuilder(column: $table.env, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$McpServersTableOrderingComposer extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transport =>
      $composableBuilder(column: $table.transport, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get args =>
      $composableBuilder(column: $table.args, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get env =>
      $composableBuilder(column: $table.env, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$McpServersTableAnnotationComposer extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get transport => $composableBuilder(column: $table.transport, builder: (column) => column);

  GeneratedColumn<String> get command => $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get args => $composableBuilder(column: $table.args, builder: (column) => column);

  GeneratedColumn<String> get env => $composableBuilder(column: $table.env, builder: (column) => column);

  GeneratedColumn<String> get url => $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get enabled => $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$McpServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $McpServersTable,
          McpServerRow,
          $$McpServersTableFilterComposer,
          $$McpServersTableOrderingComposer,
          $$McpServersTableAnnotationComposer,
          $$McpServersTableCreateCompanionBuilder,
          $$McpServersTableUpdateCompanionBuilder,
          (McpServerRow, BaseReferences<_$AppDatabase, $McpServersTable, McpServerRow>),
          McpServerRow,
          PrefetchHooks Function()
        > {
  $$McpServersTableTableManager(_$AppDatabase db, $McpServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$McpServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$McpServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$McpServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> transport = const Value.absent(),
                Value<String?> command = const Value.absent(),
                Value<String> args = const Value.absent(),
                Value<String> env = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => McpServersCompanion(
                id: id,
                name: name,
                transport: transport,
                command: command,
                args: args,
                env: env,
                url: url,
                enabled: enabled,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String transport,
                Value<String?> command = const Value.absent(),
                Value<String> args = const Value.absent(),
                Value<String> env = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => McpServersCompanion.insert(
                id: id,
                name: name,
                transport: transport,
                command: command,
                args: args,
                env: env,
                url: url,
                enabled: enabled,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$McpServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $McpServersTable,
      McpServerRow,
      $$McpServersTableFilterComposer,
      $$McpServersTableOrderingComposer,
      $$McpServersTableAnnotationComposer,
      $$McpServersTableCreateCompanionBuilder,
      $$McpServersTableUpdateCompanionBuilder,
      (McpServerRow, BaseReferences<_$AppDatabase, $McpServersTable, McpServerRow>),
      McpServerRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatSessionsTableTableManager get chatSessions => $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages => $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$WorkspaceProjectsTableTableManager get workspaceProjects =>
      $$WorkspaceProjectsTableTableManager(_db, _db.workspaceProjects);
  $$McpServersTableTableManager get mcpServers => $$McpServersTableTableManager(_db, _db.mcpServers);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppDatabase>(value));
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';
