// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db_service.dart';

// ignore_for_file: type=lint
class $LocalChatsTable extends LocalChats
    with TableInfo<$LocalChatsTable, LocalChat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageMeta =
      const VerificationMeta('lastMessage');
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
      'last_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageTypeMeta =
      const VerificationMeta('lastMessageType');
  @override
  late final GeneratedColumn<String> lastMessageType = GeneratedColumn<String>(
      'last_message_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _lastTimestampMeta =
      const VerificationMeta('lastTimestamp');
  @override
  late final GeneratedColumn<String> lastTimestamp = GeneratedColumn<String>(
      'last_timestamp', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastDirectionMeta =
      const VerificationMeta('lastDirection');
  @override
  late final GeneratedColumn<String> lastDirection = GeneratedColumn<String>(
      'last_direction', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unreadCountMeta =
      const VerificationMeta('unreadCount');
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
      'unread_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalMessagesMeta =
      const VerificationMeta('totalMessages');
  @override
  late final GeneratedColumn<int> totalMessages = GeneratedColumn<int>(
      'total_messages', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _assignedToMeta =
      const VerificationMeta('assignedTo');
  @override
  late final GeneratedColumn<String> assignedTo = GeneratedColumn<String>(
      'assigned_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  static const VerificationMeta _labelsMeta = const VerificationMeta('labels');
  @override
  late final GeneratedColumn<String> labels = GeneratedColumn<String>(
      'labels', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isStarredMeta =
      const VerificationMeta('isStarred');
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
      'is_starred', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_starred" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isBlockedMeta =
      const VerificationMeta('isBlocked');
  @override
  late final GeneratedColumn<bool> isBlocked = GeneratedColumn<bool>(
      'is_blocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_blocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isBotEnabledMeta =
      const VerificationMeta('isBotEnabled');
  @override
  late final GeneratedColumn<bool> isBotEnabled = GeneratedColumn<bool>(
      'is_bot_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_bot_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        phone,
        customerName,
        lastMessage,
        lastMessageType,
        lastTimestamp,
        lastDirection,
        unreadCount,
        totalMessages,
        assignedTo,
        status,
        priority,
        labels,
        isStarred,
        isBlocked,
        isBotEnabled,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_chats';
  @override
  VerificationContext validateIntegrity(Insertable<LocalChat> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('last_message')) {
      context.handle(
          _lastMessageMeta,
          lastMessage.isAcceptableOrUnknown(
              data['last_message']!, _lastMessageMeta));
    }
    if (data.containsKey('last_message_type')) {
      context.handle(
          _lastMessageTypeMeta,
          lastMessageType.isAcceptableOrUnknown(
              data['last_message_type']!, _lastMessageTypeMeta));
    }
    if (data.containsKey('last_timestamp')) {
      context.handle(
          _lastTimestampMeta,
          lastTimestamp.isAcceptableOrUnknown(
              data['last_timestamp']!, _lastTimestampMeta));
    }
    if (data.containsKey('last_direction')) {
      context.handle(
          _lastDirectionMeta,
          lastDirection.isAcceptableOrUnknown(
              data['last_direction']!, _lastDirectionMeta));
    }
    if (data.containsKey('unread_count')) {
      context.handle(
          _unreadCountMeta,
          unreadCount.isAcceptableOrUnknown(
              data['unread_count']!, _unreadCountMeta));
    }
    if (data.containsKey('total_messages')) {
      context.handle(
          _totalMessagesMeta,
          totalMessages.isAcceptableOrUnknown(
              data['total_messages']!, _totalMessagesMeta));
    }
    if (data.containsKey('assigned_to')) {
      context.handle(
          _assignedToMeta,
          assignedTo.isAcceptableOrUnknown(
              data['assigned_to']!, _assignedToMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('labels')) {
      context.handle(_labelsMeta,
          labels.isAcceptableOrUnknown(data['labels']!, _labelsMeta));
    }
    if (data.containsKey('is_starred')) {
      context.handle(_isStarredMeta,
          isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta));
    }
    if (data.containsKey('is_blocked')) {
      context.handle(_isBlockedMeta,
          isBlocked.isAcceptableOrUnknown(data['is_blocked']!, _isBlockedMeta));
    }
    if (data.containsKey('is_bot_enabled')) {
      context.handle(
          _isBotEnabledMeta,
          isBotEnabled.isAcceptableOrUnknown(
              data['is_bot_enabled']!, _isBotEnabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {phone},
      ];
  @override
  LocalChat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalChat(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      lastMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_message']),
      lastMessageType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_message_type'])!,
      lastTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_timestamp']),
      lastDirection: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_direction']),
      unreadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unread_count'])!,
      totalMessages: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_messages'])!,
      assignedTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assigned_to']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      labels: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}labels'])!,
      isStarred: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_starred'])!,
      isBlocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_blocked'])!,
      isBotEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_bot_enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $LocalChatsTable createAlias(String alias) {
    return $LocalChatsTable(attachedDatabase, alias);
  }
}

class LocalChat extends DataClass implements Insertable<LocalChat> {
  final int id;
  final String phone;
  final String? customerName;
  final String? lastMessage;
  final String lastMessageType;
  final String? lastTimestamp;
  final String? lastDirection;
  final int unreadCount;
  final int totalMessages;
  final String? assignedTo;
  final String status;
  final String priority;
  final String labels;
  final bool isStarred;
  final bool isBlocked;
  final bool isBotEnabled;
  final String? createdAt;
  final String? updatedAt;
  const LocalChat(
      {required this.id,
      required this.phone,
      this.customerName,
      this.lastMessage,
      required this.lastMessageType,
      this.lastTimestamp,
      this.lastDirection,
      required this.unreadCount,
      required this.totalMessages,
      this.assignedTo,
      required this.status,
      required this.priority,
      required this.labels,
      required this.isStarred,
      required this.isBlocked,
      required this.isBotEnabled,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<String>(lastMessage);
    }
    map['last_message_type'] = Variable<String>(lastMessageType);
    if (!nullToAbsent || lastTimestamp != null) {
      map['last_timestamp'] = Variable<String>(lastTimestamp);
    }
    if (!nullToAbsent || lastDirection != null) {
      map['last_direction'] = Variable<String>(lastDirection);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['total_messages'] = Variable<int>(totalMessages);
    if (!nullToAbsent || assignedTo != null) {
      map['assigned_to'] = Variable<String>(assignedTo);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    map['labels'] = Variable<String>(labels);
    map['is_starred'] = Variable<bool>(isStarred);
    map['is_blocked'] = Variable<bool>(isBlocked);
    map['is_bot_enabled'] = Variable<bool>(isBotEnabled);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  LocalChatsCompanion toCompanion(bool nullToAbsent) {
    return LocalChatsCompanion(
      id: Value(id),
      phone: Value(phone),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
      lastMessageType: Value(lastMessageType),
      lastTimestamp: lastTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTimestamp),
      lastDirection: lastDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDirection),
      unreadCount: Value(unreadCount),
      totalMessages: Value(totalMessages),
      assignedTo: assignedTo == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedTo),
      status: Value(status),
      priority: Value(priority),
      labels: Value(labels),
      isStarred: Value(isStarred),
      isBlocked: Value(isBlocked),
      isBotEnabled: Value(isBotEnabled),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalChat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalChat(
      id: serializer.fromJson<int>(json['id']),
      phone: serializer.fromJson<String>(json['phone']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      lastMessage: serializer.fromJson<String?>(json['lastMessage']),
      lastMessageType: serializer.fromJson<String>(json['lastMessageType']),
      lastTimestamp: serializer.fromJson<String?>(json['lastTimestamp']),
      lastDirection: serializer.fromJson<String?>(json['lastDirection']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      totalMessages: serializer.fromJson<int>(json['totalMessages']),
      assignedTo: serializer.fromJson<String?>(json['assignedTo']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      labels: serializer.fromJson<String>(json['labels']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      isBlocked: serializer.fromJson<bool>(json['isBlocked']),
      isBotEnabled: serializer.fromJson<bool>(json['isBotEnabled']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'phone': serializer.toJson<String>(phone),
      'customerName': serializer.toJson<String?>(customerName),
      'lastMessage': serializer.toJson<String?>(lastMessage),
      'lastMessageType': serializer.toJson<String>(lastMessageType),
      'lastTimestamp': serializer.toJson<String?>(lastTimestamp),
      'lastDirection': serializer.toJson<String?>(lastDirection),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'totalMessages': serializer.toJson<int>(totalMessages),
      'assignedTo': serializer.toJson<String?>(assignedTo),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'labels': serializer.toJson<String>(labels),
      'isStarred': serializer.toJson<bool>(isStarred),
      'isBlocked': serializer.toJson<bool>(isBlocked),
      'isBotEnabled': serializer.toJson<bool>(isBotEnabled),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  LocalChat copyWith(
          {int? id,
          String? phone,
          Value<String?> customerName = const Value.absent(),
          Value<String?> lastMessage = const Value.absent(),
          String? lastMessageType,
          Value<String?> lastTimestamp = const Value.absent(),
          Value<String?> lastDirection = const Value.absent(),
          int? unreadCount,
          int? totalMessages,
          Value<String?> assignedTo = const Value.absent(),
          String? status,
          String? priority,
          String? labels,
          bool? isStarred,
          bool? isBlocked,
          bool? isBotEnabled,
          Value<String?> createdAt = const Value.absent(),
          Value<String?> updatedAt = const Value.absent()}) =>
      LocalChat(
        id: id ?? this.id,
        phone: phone ?? this.phone,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
        lastMessageType: lastMessageType ?? this.lastMessageType,
        lastTimestamp:
            lastTimestamp.present ? lastTimestamp.value : this.lastTimestamp,
        lastDirection:
            lastDirection.present ? lastDirection.value : this.lastDirection,
        unreadCount: unreadCount ?? this.unreadCount,
        totalMessages: totalMessages ?? this.totalMessages,
        assignedTo: assignedTo.present ? assignedTo.value : this.assignedTo,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        labels: labels ?? this.labels,
        isStarred: isStarred ?? this.isStarred,
        isBlocked: isBlocked ?? this.isBlocked,
        isBotEnabled: isBotEnabled ?? this.isBotEnabled,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  LocalChat copyWithCompanion(LocalChatsCompanion data) {
    return LocalChat(
      id: data.id.present ? data.id.value : this.id,
      phone: data.phone.present ? data.phone.value : this.phone,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      lastMessage:
          data.lastMessage.present ? data.lastMessage.value : this.lastMessage,
      lastMessageType: data.lastMessageType.present
          ? data.lastMessageType.value
          : this.lastMessageType,
      lastTimestamp: data.lastTimestamp.present
          ? data.lastTimestamp.value
          : this.lastTimestamp,
      lastDirection: data.lastDirection.present
          ? data.lastDirection.value
          : this.lastDirection,
      unreadCount:
          data.unreadCount.present ? data.unreadCount.value : this.unreadCount,
      totalMessages: data.totalMessages.present
          ? data.totalMessages.value
          : this.totalMessages,
      assignedTo:
          data.assignedTo.present ? data.assignedTo.value : this.assignedTo,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      labels: data.labels.present ? data.labels.value : this.labels,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      isBlocked: data.isBlocked.present ? data.isBlocked.value : this.isBlocked,
      isBotEnabled: data.isBotEnabled.present
          ? data.isBotEnabled.value
          : this.isBotEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalChat(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('customerName: $customerName, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastTimestamp: $lastTimestamp, ')
          ..write('lastDirection: $lastDirection, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('totalMessages: $totalMessages, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('labels: $labels, ')
          ..write('isStarred: $isStarred, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('isBotEnabled: $isBotEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      phone,
      customerName,
      lastMessage,
      lastMessageType,
      lastTimestamp,
      lastDirection,
      unreadCount,
      totalMessages,
      assignedTo,
      status,
      priority,
      labels,
      isStarred,
      isBlocked,
      isBotEnabled,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalChat &&
          other.id == this.id &&
          other.phone == this.phone &&
          other.customerName == this.customerName &&
          other.lastMessage == this.lastMessage &&
          other.lastMessageType == this.lastMessageType &&
          other.lastTimestamp == this.lastTimestamp &&
          other.lastDirection == this.lastDirection &&
          other.unreadCount == this.unreadCount &&
          other.totalMessages == this.totalMessages &&
          other.assignedTo == this.assignedTo &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.labels == this.labels &&
          other.isStarred == this.isStarred &&
          other.isBlocked == this.isBlocked &&
          other.isBotEnabled == this.isBotEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalChatsCompanion extends UpdateCompanion<LocalChat> {
  final Value<int> id;
  final Value<String> phone;
  final Value<String?> customerName;
  final Value<String?> lastMessage;
  final Value<String> lastMessageType;
  final Value<String?> lastTimestamp;
  final Value<String?> lastDirection;
  final Value<int> unreadCount;
  final Value<int> totalMessages;
  final Value<String?> assignedTo;
  final Value<String> status;
  final Value<String> priority;
  final Value<String> labels;
  final Value<bool> isStarred;
  final Value<bool> isBlocked;
  final Value<bool> isBotEnabled;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const LocalChatsCompanion({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.customerName = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastTimestamp = const Value.absent(),
    this.lastDirection = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.totalMessages = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.labels = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.isBotEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalChatsCompanion.insert({
    this.id = const Value.absent(),
    required String phone,
    this.customerName = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastTimestamp = const Value.absent(),
    this.lastDirection = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.totalMessages = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.labels = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.isBotEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : phone = Value(phone);
  static Insertable<LocalChat> custom({
    Expression<int>? id,
    Expression<String>? phone,
    Expression<String>? customerName,
    Expression<String>? lastMessage,
    Expression<String>? lastMessageType,
    Expression<String>? lastTimestamp,
    Expression<String>? lastDirection,
    Expression<int>? unreadCount,
    Expression<int>? totalMessages,
    Expression<String>? assignedTo,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? labels,
    Expression<bool>? isStarred,
    Expression<bool>? isBlocked,
    Expression<bool>? isBotEnabled,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phone != null) 'phone': phone,
      if (customerName != null) 'customer_name': customerName,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageType != null) 'last_message_type': lastMessageType,
      if (lastTimestamp != null) 'last_timestamp': lastTimestamp,
      if (lastDirection != null) 'last_direction': lastDirection,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (totalMessages != null) 'total_messages': totalMessages,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (labels != null) 'labels': labels,
      if (isStarred != null) 'is_starred': isStarred,
      if (isBlocked != null) 'is_blocked': isBlocked,
      if (isBotEnabled != null) 'is_bot_enabled': isBotEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalChatsCompanion copyWith(
      {Value<int>? id,
      Value<String>? phone,
      Value<String?>? customerName,
      Value<String?>? lastMessage,
      Value<String>? lastMessageType,
      Value<String?>? lastTimestamp,
      Value<String?>? lastDirection,
      Value<int>? unreadCount,
      Value<int>? totalMessages,
      Value<String?>? assignedTo,
      Value<String>? status,
      Value<String>? priority,
      Value<String>? labels,
      Value<bool>? isStarred,
      Value<bool>? isBlocked,
      Value<bool>? isBotEnabled,
      Value<String?>? createdAt,
      Value<String?>? updatedAt}) {
    return LocalChatsCompanion(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      customerName: customerName ?? this.customerName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      lastDirection: lastDirection ?? this.lastDirection,
      unreadCount: unreadCount ?? this.unreadCount,
      totalMessages: totalMessages ?? this.totalMessages,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      labels: labels ?? this.labels,
      isStarred: isStarred ?? this.isStarred,
      isBlocked: isBlocked ?? this.isBlocked,
      isBotEnabled: isBotEnabled ?? this.isBotEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastMessageType.present) {
      map['last_message_type'] = Variable<String>(lastMessageType.value);
    }
    if (lastTimestamp.present) {
      map['last_timestamp'] = Variable<String>(lastTimestamp.value);
    }
    if (lastDirection.present) {
      map['last_direction'] = Variable<String>(lastDirection.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (totalMessages.present) {
      map['total_messages'] = Variable<int>(totalMessages.value);
    }
    if (assignedTo.present) {
      map['assigned_to'] = Variable<String>(assignedTo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (labels.present) {
      map['labels'] = Variable<String>(labels.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (isBlocked.present) {
      map['is_blocked'] = Variable<bool>(isBlocked.value);
    }
    if (isBotEnabled.present) {
      map['is_bot_enabled'] = Variable<bool>(isBotEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalChatsCompanion(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('customerName: $customerName, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastTimestamp: $lastTimestamp, ')
          ..write('lastDirection: $lastDirection, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('totalMessages: $totalMessages, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('labels: $labels, ')
          ..write('isStarred: $isStarred, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('isBotEnabled: $isBotEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _msgTextMeta =
      const VerificationMeta('msgText');
  @override
  late final GeneratedColumn<String> msgText = GeneratedColumn<String>(
      'msg_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageTypeMeta =
      const VerificationMeta('messageType');
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
      'message_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaUrlMeta =
      const VerificationMeta('mediaUrl');
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
      'media_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaMimeMeta =
      const VerificationMeta('mediaMime');
  @override
  late final GeneratedColumn<String> mediaMime = GeneratedColumn<String>(
      'media_mime', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaCaptionMeta =
      const VerificationMeta('mediaCaption');
  @override
  late final GeneratedColumn<String> mediaCaption = GeneratedColumn<String>(
      'media_caption', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _buttonIdMeta =
      const VerificationMeta('buttonId');
  @override
  late final GeneratedColumn<String> buttonId = GeneratedColumn<String>(
      'button_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _buttonTextMeta =
      const VerificationMeta('buttonText');
  @override
  late final GeneratedColumn<String> buttonText = GeneratedColumn<String>(
      'button_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _buttonsMeta =
      const VerificationMeta('buttons');
  @override
  late final GeneratedColumn<String> buttons = GeneratedColumn<String>(
      'buttons', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contextMessageIdMeta =
      const VerificationMeta('contextMessageId');
  @override
  late final GeneratedColumn<String> contextMessageId = GeneratedColumn<String>(
      'context_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isForwardedMeta =
      const VerificationMeta('isForwarded');
  @override
  late final GeneratedColumn<bool> isForwarded = GeneratedColumn<bool>(
      'is_forwarded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_forwarded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sent'));
  static const VerificationMeta _isAutoReplyMeta =
      const VerificationMeta('isAutoReply');
  @override
  late final GeneratedColumn<bool> isAutoReply = GeneratedColumn<bool>(
      'is_auto_reply', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_auto_reply" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isTemplateMeta =
      const VerificationMeta('isTemplate');
  @override
  late final GeneratedColumn<bool> isTemplate = GeneratedColumn<bool>(
      'is_template', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_template" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _templateNameMeta =
      const VerificationMeta('templateName');
  @override
  late final GeneratedColumn<String> templateName = GeneratedColumn<String>(
      'template_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deliveredAtMeta =
      const VerificationMeta('deliveredAt');
  @override
  late final GeneratedColumn<String> deliveredAt = GeneratedColumn<String>(
      'delivered_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<String> readAt = GeneratedColumn<String>(
      'read_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        phone,
        msgText,
        messageType,
        direction,
        mediaId,
        mediaUrl,
        mediaMime,
        mediaCaption,
        buttonId,
        buttonText,
        buttons,
        contextMessageId,
        isForwarded,
        status,
        isAutoReply,
        isTemplate,
        templateName,
        timestamp,
        deliveredAt,
        readAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(Insertable<LocalMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('msg_text')) {
      context.handle(_msgTextMeta,
          msgText.isAcceptableOrUnknown(data['msg_text']!, _msgTextMeta));
    }
    if (data.containsKey('message_type')) {
      context.handle(
          _messageTypeMeta,
          messageType.isAcceptableOrUnknown(
              data['message_type']!, _messageTypeMeta));
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    }
    if (data.containsKey('media_url')) {
      context.handle(_mediaUrlMeta,
          mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta));
    }
    if (data.containsKey('media_mime')) {
      context.handle(_mediaMimeMeta,
          mediaMime.isAcceptableOrUnknown(data['media_mime']!, _mediaMimeMeta));
    }
    if (data.containsKey('media_caption')) {
      context.handle(
          _mediaCaptionMeta,
          mediaCaption.isAcceptableOrUnknown(
              data['media_caption']!, _mediaCaptionMeta));
    }
    if (data.containsKey('button_id')) {
      context.handle(_buttonIdMeta,
          buttonId.isAcceptableOrUnknown(data['button_id']!, _buttonIdMeta));
    }
    if (data.containsKey('button_text')) {
      context.handle(
          _buttonTextMeta,
          buttonText.isAcceptableOrUnknown(
              data['button_text']!, _buttonTextMeta));
    }
    if (data.containsKey('buttons')) {
      context.handle(_buttonsMeta,
          buttons.isAcceptableOrUnknown(data['buttons']!, _buttonsMeta));
    }
    if (data.containsKey('context_message_id')) {
      context.handle(
          _contextMessageIdMeta,
          contextMessageId.isAcceptableOrUnknown(
              data['context_message_id']!, _contextMessageIdMeta));
    }
    if (data.containsKey('is_forwarded')) {
      context.handle(
          _isForwardedMeta,
          isForwarded.isAcceptableOrUnknown(
              data['is_forwarded']!, _isForwardedMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_auto_reply')) {
      context.handle(
          _isAutoReplyMeta,
          isAutoReply.isAcceptableOrUnknown(
              data['is_auto_reply']!, _isAutoReplyMeta));
    }
    if (data.containsKey('is_template')) {
      context.handle(
          _isTemplateMeta,
          isTemplate.isAcceptableOrUnknown(
              data['is_template']!, _isTemplateMeta));
    }
    if (data.containsKey('template_name')) {
      context.handle(
          _templateNameMeta,
          templateName.isAcceptableOrUnknown(
              data['template_name']!, _templateNameMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
          _deliveredAtMeta,
          deliveredAt.isAcceptableOrUnknown(
              data['delivered_at']!, _deliveredAtMeta));
    }
    if (data.containsKey('read_at')) {
      context.handle(_readAtMeta,
          readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {messageId},
      ];
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      msgText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}msg_text']),
      messageType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_type'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id']),
      mediaUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_url']),
      mediaMime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_mime']),
      mediaCaption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_caption']),
      buttonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}button_id']),
      buttonText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}button_text']),
      buttons: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}buttons']),
      contextMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}context_message_id']),
      isForwarded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_forwarded'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isAutoReply: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_auto_reply'])!,
      isTemplate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_template'])!,
      templateName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_name']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timestamp'])!,
      deliveredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delivered_at']),
      readAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}read_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final int id;
  final String? messageId;
  final String phone;
  final String? msgText;
  final String messageType;
  final String direction;
  final String? mediaId;
  final String? mediaUrl;
  final String? mediaMime;
  final String? mediaCaption;
  final String? buttonId;
  final String? buttonText;
  final String? buttons;
  final String? contextMessageId;
  final bool isForwarded;
  final String status;
  final bool isAutoReply;
  final bool isTemplate;
  final String? templateName;
  final String timestamp;
  final String? deliveredAt;
  final String? readAt;
  final String? createdAt;
  const LocalMessage(
      {required this.id,
      this.messageId,
      required this.phone,
      this.msgText,
      required this.messageType,
      required this.direction,
      this.mediaId,
      this.mediaUrl,
      this.mediaMime,
      this.mediaCaption,
      this.buttonId,
      this.buttonText,
      this.buttons,
      this.contextMessageId,
      required this.isForwarded,
      required this.status,
      required this.isAutoReply,
      required this.isTemplate,
      this.templateName,
      required this.timestamp,
      this.deliveredAt,
      this.readAt,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || msgText != null) {
      map['msg_text'] = Variable<String>(msgText);
    }
    map['message_type'] = Variable<String>(messageType);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || mediaId != null) {
      map['media_id'] = Variable<String>(mediaId);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || mediaMime != null) {
      map['media_mime'] = Variable<String>(mediaMime);
    }
    if (!nullToAbsent || mediaCaption != null) {
      map['media_caption'] = Variable<String>(mediaCaption);
    }
    if (!nullToAbsent || buttonId != null) {
      map['button_id'] = Variable<String>(buttonId);
    }
    if (!nullToAbsent || buttonText != null) {
      map['button_text'] = Variable<String>(buttonText);
    }
    if (!nullToAbsent || buttons != null) {
      map['buttons'] = Variable<String>(buttons);
    }
    if (!nullToAbsent || contextMessageId != null) {
      map['context_message_id'] = Variable<String>(contextMessageId);
    }
    map['is_forwarded'] = Variable<bool>(isForwarded);
    map['status'] = Variable<String>(status);
    map['is_auto_reply'] = Variable<bool>(isAutoReply);
    map['is_template'] = Variable<bool>(isTemplate);
    if (!nullToAbsent || templateName != null) {
      map['template_name'] = Variable<String>(templateName);
    }
    map['timestamp'] = Variable<String>(timestamp);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<String>(deliveredAt);
    }
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<String>(readAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      phone: Value(phone),
      msgText: msgText == null && nullToAbsent
          ? const Value.absent()
          : Value(msgText),
      messageType: Value(messageType),
      direction: Value(direction),
      mediaId: mediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaId),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      mediaMime: mediaMime == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaMime),
      mediaCaption: mediaCaption == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaCaption),
      buttonId: buttonId == null && nullToAbsent
          ? const Value.absent()
          : Value(buttonId),
      buttonText: buttonText == null && nullToAbsent
          ? const Value.absent()
          : Value(buttonText),
      buttons: buttons == null && nullToAbsent
          ? const Value.absent()
          : Value(buttons),
      contextMessageId: contextMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(contextMessageId),
      isForwarded: Value(isForwarded),
      status: Value(status),
      isAutoReply: Value(isAutoReply),
      isTemplate: Value(isTemplate),
      templateName: templateName == null && nullToAbsent
          ? const Value.absent()
          : Value(templateName),
      timestamp: Value(timestamp),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      readAt:
          readAt == null && nullToAbsent ? const Value.absent() : Value(readAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      phone: serializer.fromJson<String>(json['phone']),
      msgText: serializer.fromJson<String?>(json['msgText']),
      messageType: serializer.fromJson<String>(json['messageType']),
      direction: serializer.fromJson<String>(json['direction']),
      mediaId: serializer.fromJson<String?>(json['mediaId']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      mediaMime: serializer.fromJson<String?>(json['mediaMime']),
      mediaCaption: serializer.fromJson<String?>(json['mediaCaption']),
      buttonId: serializer.fromJson<String?>(json['buttonId']),
      buttonText: serializer.fromJson<String?>(json['buttonText']),
      buttons: serializer.fromJson<String?>(json['buttons']),
      contextMessageId: serializer.fromJson<String?>(json['contextMessageId']),
      isForwarded: serializer.fromJson<bool>(json['isForwarded']),
      status: serializer.fromJson<String>(json['status']),
      isAutoReply: serializer.fromJson<bool>(json['isAutoReply']),
      isTemplate: serializer.fromJson<bool>(json['isTemplate']),
      templateName: serializer.fromJson<String?>(json['templateName']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      deliveredAt: serializer.fromJson<String?>(json['deliveredAt']),
      readAt: serializer.fromJson<String?>(json['readAt']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String?>(messageId),
      'phone': serializer.toJson<String>(phone),
      'msgText': serializer.toJson<String?>(msgText),
      'messageType': serializer.toJson<String>(messageType),
      'direction': serializer.toJson<String>(direction),
      'mediaId': serializer.toJson<String?>(mediaId),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'mediaMime': serializer.toJson<String?>(mediaMime),
      'mediaCaption': serializer.toJson<String?>(mediaCaption),
      'buttonId': serializer.toJson<String?>(buttonId),
      'buttonText': serializer.toJson<String?>(buttonText),
      'buttons': serializer.toJson<String?>(buttons),
      'contextMessageId': serializer.toJson<String?>(contextMessageId),
      'isForwarded': serializer.toJson<bool>(isForwarded),
      'status': serializer.toJson<String>(status),
      'isAutoReply': serializer.toJson<bool>(isAutoReply),
      'isTemplate': serializer.toJson<bool>(isTemplate),
      'templateName': serializer.toJson<String?>(templateName),
      'timestamp': serializer.toJson<String>(timestamp),
      'deliveredAt': serializer.toJson<String?>(deliveredAt),
      'readAt': serializer.toJson<String?>(readAt),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  LocalMessage copyWith(
          {int? id,
          Value<String?> messageId = const Value.absent(),
          String? phone,
          Value<String?> msgText = const Value.absent(),
          String? messageType,
          String? direction,
          Value<String?> mediaId = const Value.absent(),
          Value<String?> mediaUrl = const Value.absent(),
          Value<String?> mediaMime = const Value.absent(),
          Value<String?> mediaCaption = const Value.absent(),
          Value<String?> buttonId = const Value.absent(),
          Value<String?> buttonText = const Value.absent(),
          Value<String?> buttons = const Value.absent(),
          Value<String?> contextMessageId = const Value.absent(),
          bool? isForwarded,
          String? status,
          bool? isAutoReply,
          bool? isTemplate,
          Value<String?> templateName = const Value.absent(),
          String? timestamp,
          Value<String?> deliveredAt = const Value.absent(),
          Value<String?> readAt = const Value.absent(),
          Value<String?> createdAt = const Value.absent()}) =>
      LocalMessage(
        id: id ?? this.id,
        messageId: messageId.present ? messageId.value : this.messageId,
        phone: phone ?? this.phone,
        msgText: msgText.present ? msgText.value : this.msgText,
        messageType: messageType ?? this.messageType,
        direction: direction ?? this.direction,
        mediaId: mediaId.present ? mediaId.value : this.mediaId,
        mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
        mediaMime: mediaMime.present ? mediaMime.value : this.mediaMime,
        mediaCaption:
            mediaCaption.present ? mediaCaption.value : this.mediaCaption,
        buttonId: buttonId.present ? buttonId.value : this.buttonId,
        buttonText: buttonText.present ? buttonText.value : this.buttonText,
        buttons: buttons.present ? buttons.value : this.buttons,
        contextMessageId: contextMessageId.present
            ? contextMessageId.value
            : this.contextMessageId,
        isForwarded: isForwarded ?? this.isForwarded,
        status: status ?? this.status,
        isAutoReply: isAutoReply ?? this.isAutoReply,
        isTemplate: isTemplate ?? this.isTemplate,
        templateName:
            templateName.present ? templateName.value : this.templateName,
        timestamp: timestamp ?? this.timestamp,
        deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
        readAt: readAt.present ? readAt.value : this.readAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  LocalMessage copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessage(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      phone: data.phone.present ? data.phone.value : this.phone,
      msgText: data.msgText.present ? data.msgText.value : this.msgText,
      messageType:
          data.messageType.present ? data.messageType.value : this.messageType,
      direction: data.direction.present ? data.direction.value : this.direction,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      mediaMime: data.mediaMime.present ? data.mediaMime.value : this.mediaMime,
      mediaCaption: data.mediaCaption.present
          ? data.mediaCaption.value
          : this.mediaCaption,
      buttonId: data.buttonId.present ? data.buttonId.value : this.buttonId,
      buttonText:
          data.buttonText.present ? data.buttonText.value : this.buttonText,
      buttons: data.buttons.present ? data.buttons.value : this.buttons,
      contextMessageId: data.contextMessageId.present
          ? data.contextMessageId.value
          : this.contextMessageId,
      isForwarded:
          data.isForwarded.present ? data.isForwarded.value : this.isForwarded,
      status: data.status.present ? data.status.value : this.status,
      isAutoReply:
          data.isAutoReply.present ? data.isAutoReply.value : this.isAutoReply,
      isTemplate:
          data.isTemplate.present ? data.isTemplate.value : this.isTemplate,
      templateName: data.templateName.present
          ? data.templateName.value
          : this.templateName,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      deliveredAt:
          data.deliveredAt.present ? data.deliveredAt.value : this.deliveredAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('phone: $phone, ')
          ..write('msgText: $msgText, ')
          ..write('messageType: $messageType, ')
          ..write('direction: $direction, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMime: $mediaMime, ')
          ..write('mediaCaption: $mediaCaption, ')
          ..write('buttonId: $buttonId, ')
          ..write('buttonText: $buttonText, ')
          ..write('buttons: $buttons, ')
          ..write('contextMessageId: $contextMessageId, ')
          ..write('isForwarded: $isForwarded, ')
          ..write('status: $status, ')
          ..write('isAutoReply: $isAutoReply, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('templateName: $templateName, ')
          ..write('timestamp: $timestamp, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('readAt: $readAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        messageId,
        phone,
        msgText,
        messageType,
        direction,
        mediaId,
        mediaUrl,
        mediaMime,
        mediaCaption,
        buttonId,
        buttonText,
        buttons,
        contextMessageId,
        isForwarded,
        status,
        isAutoReply,
        isTemplate,
        templateName,
        timestamp,
        deliveredAt,
        readAt,
        createdAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.phone == this.phone &&
          other.msgText == this.msgText &&
          other.messageType == this.messageType &&
          other.direction == this.direction &&
          other.mediaId == this.mediaId &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaMime == this.mediaMime &&
          other.mediaCaption == this.mediaCaption &&
          other.buttonId == this.buttonId &&
          other.buttonText == this.buttonText &&
          other.buttons == this.buttons &&
          other.contextMessageId == this.contextMessageId &&
          other.isForwarded == this.isForwarded &&
          other.status == this.status &&
          other.isAutoReply == this.isAutoReply &&
          other.isTemplate == this.isTemplate &&
          other.templateName == this.templateName &&
          other.timestamp == this.timestamp &&
          other.deliveredAt == this.deliveredAt &&
          other.readAt == this.readAt &&
          other.createdAt == this.createdAt);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<int> id;
  final Value<String?> messageId;
  final Value<String> phone;
  final Value<String?> msgText;
  final Value<String> messageType;
  final Value<String> direction;
  final Value<String?> mediaId;
  final Value<String?> mediaUrl;
  final Value<String?> mediaMime;
  final Value<String?> mediaCaption;
  final Value<String?> buttonId;
  final Value<String?> buttonText;
  final Value<String?> buttons;
  final Value<String?> contextMessageId;
  final Value<bool> isForwarded;
  final Value<String> status;
  final Value<bool> isAutoReply;
  final Value<bool> isTemplate;
  final Value<String?> templateName;
  final Value<String> timestamp;
  final Value<String?> deliveredAt;
  final Value<String?> readAt;
  final Value<String?> createdAt;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.phone = const Value.absent(),
    this.msgText = const Value.absent(),
    this.messageType = const Value.absent(),
    this.direction = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaMime = const Value.absent(),
    this.mediaCaption = const Value.absent(),
    this.buttonId = const Value.absent(),
    this.buttonText = const Value.absent(),
    this.buttons = const Value.absent(),
    this.contextMessageId = const Value.absent(),
    this.isForwarded = const Value.absent(),
    this.status = const Value.absent(),
    this.isAutoReply = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.templateName = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    required String phone,
    this.msgText = const Value.absent(),
    this.messageType = const Value.absent(),
    required String direction,
    this.mediaId = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaMime = const Value.absent(),
    this.mediaCaption = const Value.absent(),
    this.buttonId = const Value.absent(),
    this.buttonText = const Value.absent(),
    this.buttons = const Value.absent(),
    this.contextMessageId = const Value.absent(),
    this.isForwarded = const Value.absent(),
    this.status = const Value.absent(),
    this.isAutoReply = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.templateName = const Value.absent(),
    required String timestamp,
    this.deliveredAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : phone = Value(phone),
        direction = Value(direction),
        timestamp = Value(timestamp);
  static Insertable<LocalMessage> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? phone,
    Expression<String>? msgText,
    Expression<String>? messageType,
    Expression<String>? direction,
    Expression<String>? mediaId,
    Expression<String>? mediaUrl,
    Expression<String>? mediaMime,
    Expression<String>? mediaCaption,
    Expression<String>? buttonId,
    Expression<String>? buttonText,
    Expression<String>? buttons,
    Expression<String>? contextMessageId,
    Expression<bool>? isForwarded,
    Expression<String>? status,
    Expression<bool>? isAutoReply,
    Expression<bool>? isTemplate,
    Expression<String>? templateName,
    Expression<String>? timestamp,
    Expression<String>? deliveredAt,
    Expression<String>? readAt,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (phone != null) 'phone': phone,
      if (msgText != null) 'msg_text': msgText,
      if (messageType != null) 'message_type': messageType,
      if (direction != null) 'direction': direction,
      if (mediaId != null) 'media_id': mediaId,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaMime != null) 'media_mime': mediaMime,
      if (mediaCaption != null) 'media_caption': mediaCaption,
      if (buttonId != null) 'button_id': buttonId,
      if (buttonText != null) 'button_text': buttonText,
      if (buttons != null) 'buttons': buttons,
      if (contextMessageId != null) 'context_message_id': contextMessageId,
      if (isForwarded != null) 'is_forwarded': isForwarded,
      if (status != null) 'status': status,
      if (isAutoReply != null) 'is_auto_reply': isAutoReply,
      if (isTemplate != null) 'is_template': isTemplate,
      if (templateName != null) 'template_name': templateName,
      if (timestamp != null) 'timestamp': timestamp,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (readAt != null) 'read_at': readAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalMessagesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? messageId,
      Value<String>? phone,
      Value<String?>? msgText,
      Value<String>? messageType,
      Value<String>? direction,
      Value<String?>? mediaId,
      Value<String?>? mediaUrl,
      Value<String?>? mediaMime,
      Value<String?>? mediaCaption,
      Value<String?>? buttonId,
      Value<String?>? buttonText,
      Value<String?>? buttons,
      Value<String?>? contextMessageId,
      Value<bool>? isForwarded,
      Value<String>? status,
      Value<bool>? isAutoReply,
      Value<bool>? isTemplate,
      Value<String?>? templateName,
      Value<String>? timestamp,
      Value<String?>? deliveredAt,
      Value<String?>? readAt,
      Value<String?>? createdAt}) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      phone: phone ?? this.phone,
      msgText: msgText ?? this.msgText,
      messageType: messageType ?? this.messageType,
      direction: direction ?? this.direction,
      mediaId: mediaId ?? this.mediaId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMime: mediaMime ?? this.mediaMime,
      mediaCaption: mediaCaption ?? this.mediaCaption,
      buttonId: buttonId ?? this.buttonId,
      buttonText: buttonText ?? this.buttonText,
      buttons: buttons ?? this.buttons,
      contextMessageId: contextMessageId ?? this.contextMessageId,
      isForwarded: isForwarded ?? this.isForwarded,
      status: status ?? this.status,
      isAutoReply: isAutoReply ?? this.isAutoReply,
      isTemplate: isTemplate ?? this.isTemplate,
      templateName: templateName ?? this.templateName,
      timestamp: timestamp ?? this.timestamp,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (msgText.present) {
      map['msg_text'] = Variable<String>(msgText.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaMime.present) {
      map['media_mime'] = Variable<String>(mediaMime.value);
    }
    if (mediaCaption.present) {
      map['media_caption'] = Variable<String>(mediaCaption.value);
    }
    if (buttonId.present) {
      map['button_id'] = Variable<String>(buttonId.value);
    }
    if (buttonText.present) {
      map['button_text'] = Variable<String>(buttonText.value);
    }
    if (buttons.present) {
      map['buttons'] = Variable<String>(buttons.value);
    }
    if (contextMessageId.present) {
      map['context_message_id'] = Variable<String>(contextMessageId.value);
    }
    if (isForwarded.present) {
      map['is_forwarded'] = Variable<bool>(isForwarded.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isAutoReply.present) {
      map['is_auto_reply'] = Variable<bool>(isAutoReply.value);
    }
    if (isTemplate.present) {
      map['is_template'] = Variable<bool>(isTemplate.value);
    }
    if (templateName.present) {
      map['template_name'] = Variable<String>(templateName.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<String>(deliveredAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<String>(readAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('phone: $phone, ')
          ..write('msgText: $msgText, ')
          ..write('messageType: $messageType, ')
          ..write('direction: $direction, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaMime: $mediaMime, ')
          ..write('mediaCaption: $mediaCaption, ')
          ..write('buttonId: $buttonId, ')
          ..write('buttonText: $buttonText, ')
          ..write('buttons: $buttons, ')
          ..write('contextMessageId: $contextMessageId, ')
          ..write('isForwarded: $isForwarded, ')
          ..write('status: $status, ')
          ..write('isAutoReply: $isAutoReply, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('templateName: $templateName, ')
          ..write('timestamp: $timestamp, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('readAt: $readAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalCustomersTable extends LocalCustomers
    with TableInfo<$LocalCustomersTable, LocalCustomer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
      'city', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pincodeMeta =
      const VerificationMeta('pincode');
  @override
  late final GeneratedColumn<String> pincode = GeneratedColumn<String>(
      'pincode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _segmentMeta =
      const VerificationMeta('segment');
  @override
  late final GeneratedColumn<String> segment = GeneratedColumn<String>(
      'segment', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('new'));
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
      'tier', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('bronze'));
  static const VerificationMeta _labelsMeta = const VerificationMeta('labels');
  @override
  late final GeneratedColumn<String> labels = GeneratedColumn<String>(
      'labels', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _messageCountMeta =
      const VerificationMeta('messageCount');
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
      'message_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _orderCountMeta =
      const VerificationMeta('orderCount');
  @override
  late final GeneratedColumn<int> orderCount = GeneratedColumn<int>(
      'order_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSpentMeta =
      const VerificationMeta('totalSpent');
  @override
  late final GeneratedColumn<double> totalSpent = GeneratedColumn<double>(
      'total_spent', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('en'));
  static const VerificationMeta _optedInMeta =
      const VerificationMeta('optedIn');
  @override
  late final GeneratedColumn<bool> optedIn = GeneratedColumn<bool>(
      'opted_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("opted_in" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _firstSeenMeta =
      const VerificationMeta('firstSeen');
  @override
  late final GeneratedColumn<String> firstSeen = GeneratedColumn<String>(
      'first_seen', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<String> lastSeen = GeneratedColumn<String>(
      'last_seen', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastOrderAtMeta =
      const VerificationMeta('lastOrderAt');
  @override
  late final GeneratedColumn<String> lastOrderAt = GeneratedColumn<String>(
      'last_order_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        phone,
        name,
        email,
        address,
        state,
        city,
        pincode,
        segment,
        tier,
        labels,
        messageCount,
        orderCount,
        totalSpent,
        language,
        optedIn,
        firstSeen,
        lastSeen,
        lastOrderAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_customers';
  @override
  VerificationContext validateIntegrity(Insertable<LocalCustomer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('city')) {
      context.handle(
          _cityMeta, city.isAcceptableOrUnknown(data['city']!, _cityMeta));
    }
    if (data.containsKey('pincode')) {
      context.handle(_pincodeMeta,
          pincode.isAcceptableOrUnknown(data['pincode']!, _pincodeMeta));
    }
    if (data.containsKey('segment')) {
      context.handle(_segmentMeta,
          segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta));
    }
    if (data.containsKey('tier')) {
      context.handle(
          _tierMeta, tier.isAcceptableOrUnknown(data['tier']!, _tierMeta));
    }
    if (data.containsKey('labels')) {
      context.handle(_labelsMeta,
          labels.isAcceptableOrUnknown(data['labels']!, _labelsMeta));
    }
    if (data.containsKey('message_count')) {
      context.handle(
          _messageCountMeta,
          messageCount.isAcceptableOrUnknown(
              data['message_count']!, _messageCountMeta));
    }
    if (data.containsKey('order_count')) {
      context.handle(
          _orderCountMeta,
          orderCount.isAcceptableOrUnknown(
              data['order_count']!, _orderCountMeta));
    }
    if (data.containsKey('total_spent')) {
      context.handle(
          _totalSpentMeta,
          totalSpent.isAcceptableOrUnknown(
              data['total_spent']!, _totalSpentMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('opted_in')) {
      context.handle(_optedInMeta,
          optedIn.isAcceptableOrUnknown(data['opted_in']!, _optedInMeta));
    }
    if (data.containsKey('first_seen')) {
      context.handle(_firstSeenMeta,
          firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta));
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    }
    if (data.containsKey('last_order_at')) {
      context.handle(
          _lastOrderAtMeta,
          lastOrderAt.isAcceptableOrUnknown(
              data['last_order_at']!, _lastOrderAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {phone},
      ];
  @override
  LocalCustomer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCustomer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state']),
      city: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city']),
      pincode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pincode']),
      segment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}segment'])!,
      tier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tier'])!,
      labels: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}labels'])!,
      messageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_count'])!,
      orderCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_count'])!,
      totalSpent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_spent'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      optedIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}opted_in'])!,
      firstSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_seen']),
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_seen']),
      lastOrderAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_order_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $LocalCustomersTable createAlias(String alias) {
    return $LocalCustomersTable(attachedDatabase, alias);
  }
}

class LocalCustomer extends DataClass implements Insertable<LocalCustomer> {
  final int id;
  final String phone;
  final String? name;
  final String? email;
  final String? address;
  final String? state;
  final String? city;
  final String? pincode;
  final String segment;
  final String tier;
  final String labels;
  final int messageCount;
  final int orderCount;
  final double totalSpent;
  final String language;
  final bool optedIn;
  final String? firstSeen;
  final String? lastSeen;
  final String? lastOrderAt;
  final String? createdAt;
  final String? updatedAt;
  const LocalCustomer(
      {required this.id,
      required this.phone,
      this.name,
      this.email,
      this.address,
      this.state,
      this.city,
      this.pincode,
      required this.segment,
      required this.tier,
      required this.labels,
      required this.messageCount,
      required this.orderCount,
      required this.totalSpent,
      required this.language,
      required this.optedIn,
      this.firstSeen,
      this.lastSeen,
      this.lastOrderAt,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || pincode != null) {
      map['pincode'] = Variable<String>(pincode);
    }
    map['segment'] = Variable<String>(segment);
    map['tier'] = Variable<String>(tier);
    map['labels'] = Variable<String>(labels);
    map['message_count'] = Variable<int>(messageCount);
    map['order_count'] = Variable<int>(orderCount);
    map['total_spent'] = Variable<double>(totalSpent);
    map['language'] = Variable<String>(language);
    map['opted_in'] = Variable<bool>(optedIn);
    if (!nullToAbsent || firstSeen != null) {
      map['first_seen'] = Variable<String>(firstSeen);
    }
    if (!nullToAbsent || lastSeen != null) {
      map['last_seen'] = Variable<String>(lastSeen);
    }
    if (!nullToAbsent || lastOrderAt != null) {
      map['last_order_at'] = Variable<String>(lastOrderAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  LocalCustomersCompanion toCompanion(bool nullToAbsent) {
    return LocalCustomersCompanion(
      id: Value(id),
      phone: Value(phone),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      state:
          state == null && nullToAbsent ? const Value.absent() : Value(state),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      pincode: pincode == null && nullToAbsent
          ? const Value.absent()
          : Value(pincode),
      segment: Value(segment),
      tier: Value(tier),
      labels: Value(labels),
      messageCount: Value(messageCount),
      orderCount: Value(orderCount),
      totalSpent: Value(totalSpent),
      language: Value(language),
      optedIn: Value(optedIn),
      firstSeen: firstSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(firstSeen),
      lastSeen: lastSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeen),
      lastOrderAt: lastOrderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOrderAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalCustomer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCustomer(
      id: serializer.fromJson<int>(json['id']),
      phone: serializer.fromJson<String>(json['phone']),
      name: serializer.fromJson<String?>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      state: serializer.fromJson<String?>(json['state']),
      city: serializer.fromJson<String?>(json['city']),
      pincode: serializer.fromJson<String?>(json['pincode']),
      segment: serializer.fromJson<String>(json['segment']),
      tier: serializer.fromJson<String>(json['tier']),
      labels: serializer.fromJson<String>(json['labels']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      orderCount: serializer.fromJson<int>(json['orderCount']),
      totalSpent: serializer.fromJson<double>(json['totalSpent']),
      language: serializer.fromJson<String>(json['language']),
      optedIn: serializer.fromJson<bool>(json['optedIn']),
      firstSeen: serializer.fromJson<String?>(json['firstSeen']),
      lastSeen: serializer.fromJson<String?>(json['lastSeen']),
      lastOrderAt: serializer.fromJson<String?>(json['lastOrderAt']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'phone': serializer.toJson<String>(phone),
      'name': serializer.toJson<String?>(name),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'state': serializer.toJson<String?>(state),
      'city': serializer.toJson<String?>(city),
      'pincode': serializer.toJson<String?>(pincode),
      'segment': serializer.toJson<String>(segment),
      'tier': serializer.toJson<String>(tier),
      'labels': serializer.toJson<String>(labels),
      'messageCount': serializer.toJson<int>(messageCount),
      'orderCount': serializer.toJson<int>(orderCount),
      'totalSpent': serializer.toJson<double>(totalSpent),
      'language': serializer.toJson<String>(language),
      'optedIn': serializer.toJson<bool>(optedIn),
      'firstSeen': serializer.toJson<String?>(firstSeen),
      'lastSeen': serializer.toJson<String?>(lastSeen),
      'lastOrderAt': serializer.toJson<String?>(lastOrderAt),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  LocalCustomer copyWith(
          {int? id,
          String? phone,
          Value<String?> name = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> state = const Value.absent(),
          Value<String?> city = const Value.absent(),
          Value<String?> pincode = const Value.absent(),
          String? segment,
          String? tier,
          String? labels,
          int? messageCount,
          int? orderCount,
          double? totalSpent,
          String? language,
          bool? optedIn,
          Value<String?> firstSeen = const Value.absent(),
          Value<String?> lastSeen = const Value.absent(),
          Value<String?> lastOrderAt = const Value.absent(),
          Value<String?> createdAt = const Value.absent(),
          Value<String?> updatedAt = const Value.absent()}) =>
      LocalCustomer(
        id: id ?? this.id,
        phone: phone ?? this.phone,
        name: name.present ? name.value : this.name,
        email: email.present ? email.value : this.email,
        address: address.present ? address.value : this.address,
        state: state.present ? state.value : this.state,
        city: city.present ? city.value : this.city,
        pincode: pincode.present ? pincode.value : this.pincode,
        segment: segment ?? this.segment,
        tier: tier ?? this.tier,
        labels: labels ?? this.labels,
        messageCount: messageCount ?? this.messageCount,
        orderCount: orderCount ?? this.orderCount,
        totalSpent: totalSpent ?? this.totalSpent,
        language: language ?? this.language,
        optedIn: optedIn ?? this.optedIn,
        firstSeen: firstSeen.present ? firstSeen.value : this.firstSeen,
        lastSeen: lastSeen.present ? lastSeen.value : this.lastSeen,
        lastOrderAt: lastOrderAt.present ? lastOrderAt.value : this.lastOrderAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  LocalCustomer copyWithCompanion(LocalCustomersCompanion data) {
    return LocalCustomer(
      id: data.id.present ? data.id.value : this.id,
      phone: data.phone.present ? data.phone.value : this.phone,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      state: data.state.present ? data.state.value : this.state,
      city: data.city.present ? data.city.value : this.city,
      pincode: data.pincode.present ? data.pincode.value : this.pincode,
      segment: data.segment.present ? data.segment.value : this.segment,
      tier: data.tier.present ? data.tier.value : this.tier,
      labels: data.labels.present ? data.labels.value : this.labels,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      orderCount:
          data.orderCount.present ? data.orderCount.value : this.orderCount,
      totalSpent:
          data.totalSpent.present ? data.totalSpent.value : this.totalSpent,
      language: data.language.present ? data.language.value : this.language,
      optedIn: data.optedIn.present ? data.optedIn.value : this.optedIn,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      lastOrderAt:
          data.lastOrderAt.present ? data.lastOrderAt.value : this.lastOrderAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomer(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('state: $state, ')
          ..write('city: $city, ')
          ..write('pincode: $pincode, ')
          ..write('segment: $segment, ')
          ..write('tier: $tier, ')
          ..write('labels: $labels, ')
          ..write('messageCount: $messageCount, ')
          ..write('orderCount: $orderCount, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('language: $language, ')
          ..write('optedIn: $optedIn, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastOrderAt: $lastOrderAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        phone,
        name,
        email,
        address,
        state,
        city,
        pincode,
        segment,
        tier,
        labels,
        messageCount,
        orderCount,
        totalSpent,
        language,
        optedIn,
        firstSeen,
        lastSeen,
        lastOrderAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCustomer &&
          other.id == this.id &&
          other.phone == this.phone &&
          other.name == this.name &&
          other.email == this.email &&
          other.address == this.address &&
          other.state == this.state &&
          other.city == this.city &&
          other.pincode == this.pincode &&
          other.segment == this.segment &&
          other.tier == this.tier &&
          other.labels == this.labels &&
          other.messageCount == this.messageCount &&
          other.orderCount == this.orderCount &&
          other.totalSpent == this.totalSpent &&
          other.language == this.language &&
          other.optedIn == this.optedIn &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen &&
          other.lastOrderAt == this.lastOrderAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalCustomersCompanion extends UpdateCompanion<LocalCustomer> {
  final Value<int> id;
  final Value<String> phone;
  final Value<String?> name;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> state;
  final Value<String?> city;
  final Value<String?> pincode;
  final Value<String> segment;
  final Value<String> tier;
  final Value<String> labels;
  final Value<int> messageCount;
  final Value<int> orderCount;
  final Value<double> totalSpent;
  final Value<String> language;
  final Value<bool> optedIn;
  final Value<String?> firstSeen;
  final Value<String?> lastSeen;
  final Value<String?> lastOrderAt;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const LocalCustomersCompanion({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.state = const Value.absent(),
    this.city = const Value.absent(),
    this.pincode = const Value.absent(),
    this.segment = const Value.absent(),
    this.tier = const Value.absent(),
    this.labels = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.orderCount = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.language = const Value.absent(),
    this.optedIn = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastOrderAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalCustomersCompanion.insert({
    this.id = const Value.absent(),
    required String phone,
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.state = const Value.absent(),
    this.city = const Value.absent(),
    this.pincode = const Value.absent(),
    this.segment = const Value.absent(),
    this.tier = const Value.absent(),
    this.labels = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.orderCount = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.language = const Value.absent(),
    this.optedIn = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastOrderAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : phone = Value(phone);
  static Insertable<LocalCustomer> custom({
    Expression<int>? id,
    Expression<String>? phone,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? state,
    Expression<String>? city,
    Expression<String>? pincode,
    Expression<String>? segment,
    Expression<String>? tier,
    Expression<String>? labels,
    Expression<int>? messageCount,
    Expression<int>? orderCount,
    Expression<double>? totalSpent,
    Expression<String>? language,
    Expression<bool>? optedIn,
    Expression<String>? firstSeen,
    Expression<String>? lastSeen,
    Expression<String>? lastOrderAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phone != null) 'phone': phone,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (pincode != null) 'pincode': pincode,
      if (segment != null) 'segment': segment,
      if (tier != null) 'tier': tier,
      if (labels != null) 'labels': labels,
      if (messageCount != null) 'message_count': messageCount,
      if (orderCount != null) 'order_count': orderCount,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (language != null) 'language': language,
      if (optedIn != null) 'opted_in': optedIn,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (lastOrderAt != null) 'last_order_at': lastOrderAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalCustomersCompanion copyWith(
      {Value<int>? id,
      Value<String>? phone,
      Value<String?>? name,
      Value<String?>? email,
      Value<String?>? address,
      Value<String?>? state,
      Value<String?>? city,
      Value<String?>? pincode,
      Value<String>? segment,
      Value<String>? tier,
      Value<String>? labels,
      Value<int>? messageCount,
      Value<int>? orderCount,
      Value<double>? totalSpent,
      Value<String>? language,
      Value<bool>? optedIn,
      Value<String?>? firstSeen,
      Value<String?>? lastSeen,
      Value<String?>? lastOrderAt,
      Value<String?>? createdAt,
      Value<String?>? updatedAt}) {
    return LocalCustomersCompanion(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      segment: segment ?? this.segment,
      tier: tier ?? this.tier,
      labels: labels ?? this.labels,
      messageCount: messageCount ?? this.messageCount,
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
      language: language ?? this.language,
      optedIn: optedIn ?? this.optedIn,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      lastOrderAt: lastOrderAt ?? this.lastOrderAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (pincode.present) {
      map['pincode'] = Variable<String>(pincode.value);
    }
    if (segment.present) {
      map['segment'] = Variable<String>(segment.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (labels.present) {
      map['labels'] = Variable<String>(labels.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (orderCount.present) {
      map['order_count'] = Variable<int>(orderCount.value);
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<double>(totalSpent.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (optedIn.present) {
      map['opted_in'] = Variable<bool>(optedIn.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<String>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<String>(lastSeen.value);
    }
    if (lastOrderAt.present) {
      map['last_order_at'] = Variable<String>(lastOrderAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomersCompanion(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('state: $state, ')
          ..write('city: $city, ')
          ..write('pincode: $pincode, ')
          ..write('segment: $segment, ')
          ..write('tier: $tier, ')
          ..write('labels: $labels, ')
          ..write('messageCount: $messageCount, ')
          ..write('orderCount: $orderCount, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('language: $language, ')
          ..write('optedIn: $optedIn, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastOrderAt: $lastOrderAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalOrdersTable extends LocalOrders
    with TableInfo<$LocalOrdersTable, LocalOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
      'items', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _itemCountMeta =
      const VerificationMeta('itemCount');
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
      'item_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _shippingCostMeta =
      const VerificationMeta('shippingCost');
  @override
  late final GeneratedColumn<double> shippingCost = GeneratedColumn<double>(
      'shipping_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
      'tax', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unpaid'));
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _courierMeta =
      const VerificationMeta('courier');
  @override
  late final GeneratedColumn<String> courier = GeneratedColumn<String>(
      'courier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _trackingIdMeta =
      const VerificationMeta('trackingId');
  @override
  late final GeneratedColumn<String> trackingId = GeneratedColumn<String>(
      'tracking_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _awbNumberMeta =
      const VerificationMeta('awbNumber');
  @override
  late final GeneratedColumn<String> awbNumber = GeneratedColumn<String>(
      'awb_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('whatsapp'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        phone,
        customerName,
        items,
        itemCount,
        subtotal,
        discount,
        shippingCost,
        tax,
        total,
        status,
        paymentStatus,
        paymentMethod,
        courier,
        trackingId,
        awbNumber,
        source,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_orders';
  @override
  VerificationContext validateIntegrity(Insertable<LocalOrder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('items')) {
      context.handle(
          _itemsMeta, items.isAcceptableOrUnknown(data['items']!, _itemsMeta));
    }
    if (data.containsKey('item_count')) {
      context.handle(_itemCountMeta,
          itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('shipping_cost')) {
      context.handle(
          _shippingCostMeta,
          shippingCost.isAcceptableOrUnknown(
              data['shipping_cost']!, _shippingCostMeta));
    }
    if (data.containsKey('tax')) {
      context.handle(
          _taxMeta, tax.isAcceptableOrUnknown(data['tax']!, _taxMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('courier')) {
      context.handle(_courierMeta,
          courier.isAcceptableOrUnknown(data['courier']!, _courierMeta));
    }
    if (data.containsKey('tracking_id')) {
      context.handle(
          _trackingIdMeta,
          trackingId.isAcceptableOrUnknown(
              data['tracking_id']!, _trackingIdMeta));
    }
    if (data.containsKey('awb_number')) {
      context.handle(_awbNumberMeta,
          awbNumber.isAcceptableOrUnknown(data['awb_number']!, _awbNumberMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {orderId},
      ];
  @override
  LocalOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      items: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}items'])!,
      itemCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_count'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      shippingCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shipping_cost'])!,
      tax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method']),
      courier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}courier']),
      trackingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tracking_id']),
      awbNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}awb_number']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $LocalOrdersTable createAlias(String alias) {
    return $LocalOrdersTable(attachedDatabase, alias);
  }
}

class LocalOrder extends DataClass implements Insertable<LocalOrder> {
  final int id;
  final String orderId;
  final String phone;
  final String? customerName;
  final String items;
  final int itemCount;
  final double subtotal;
  final double discount;
  final double shippingCost;
  final double tax;
  final double total;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? courier;
  final String? trackingId;
  final String? awbNumber;
  final String source;
  final String? createdAt;
  final String? updatedAt;
  const LocalOrder(
      {required this.id,
      required this.orderId,
      required this.phone,
      this.customerName,
      required this.items,
      required this.itemCount,
      required this.subtotal,
      required this.discount,
      required this.shippingCost,
      required this.tax,
      required this.total,
      required this.status,
      required this.paymentStatus,
      this.paymentMethod,
      this.courier,
      this.trackingId,
      this.awbNumber,
      required this.source,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_id'] = Variable<String>(orderId);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['items'] = Variable<String>(items);
    map['item_count'] = Variable<int>(itemCount);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount'] = Variable<double>(discount);
    map['shipping_cost'] = Variable<double>(shippingCost);
    map['tax'] = Variable<double>(tax);
    map['total'] = Variable<double>(total);
    map['status'] = Variable<String>(status);
    map['payment_status'] = Variable<String>(paymentStatus);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || courier != null) {
      map['courier'] = Variable<String>(courier);
    }
    if (!nullToAbsent || trackingId != null) {
      map['tracking_id'] = Variable<String>(trackingId);
    }
    if (!nullToAbsent || awbNumber != null) {
      map['awb_number'] = Variable<String>(awbNumber);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  LocalOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdersCompanion(
      id: Value(id),
      orderId: Value(orderId),
      phone: Value(phone),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      items: Value(items),
      itemCount: Value(itemCount),
      subtotal: Value(subtotal),
      discount: Value(discount),
      shippingCost: Value(shippingCost),
      tax: Value(tax),
      total: Value(total),
      status: Value(status),
      paymentStatus: Value(paymentStatus),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      courier: courier == null && nullToAbsent
          ? const Value.absent()
          : Value(courier),
      trackingId: trackingId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackingId),
      awbNumber: awbNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(awbNumber),
      source: Value(source),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalOrder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrder(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      phone: serializer.fromJson<String>(json['phone']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      items: serializer.fromJson<String>(json['items']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discount: serializer.fromJson<double>(json['discount']),
      shippingCost: serializer.fromJson<double>(json['shippingCost']),
      tax: serializer.fromJson<double>(json['tax']),
      total: serializer.fromJson<double>(json['total']),
      status: serializer.fromJson<String>(json['status']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      courier: serializer.fromJson<String?>(json['courier']),
      trackingId: serializer.fromJson<String?>(json['trackingId']),
      awbNumber: serializer.fromJson<String?>(json['awbNumber']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<String>(orderId),
      'phone': serializer.toJson<String>(phone),
      'customerName': serializer.toJson<String?>(customerName),
      'items': serializer.toJson<String>(items),
      'itemCount': serializer.toJson<int>(itemCount),
      'subtotal': serializer.toJson<double>(subtotal),
      'discount': serializer.toJson<double>(discount),
      'shippingCost': serializer.toJson<double>(shippingCost),
      'tax': serializer.toJson<double>(tax),
      'total': serializer.toJson<double>(total),
      'status': serializer.toJson<String>(status),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'courier': serializer.toJson<String?>(courier),
      'trackingId': serializer.toJson<String?>(trackingId),
      'awbNumber': serializer.toJson<String?>(awbNumber),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  LocalOrder copyWith(
          {int? id,
          String? orderId,
          String? phone,
          Value<String?> customerName = const Value.absent(),
          String? items,
          int? itemCount,
          double? subtotal,
          double? discount,
          double? shippingCost,
          double? tax,
          double? total,
          String? status,
          String? paymentStatus,
          Value<String?> paymentMethod = const Value.absent(),
          Value<String?> courier = const Value.absent(),
          Value<String?> trackingId = const Value.absent(),
          Value<String?> awbNumber = const Value.absent(),
          String? source,
          Value<String?> createdAt = const Value.absent(),
          Value<String?> updatedAt = const Value.absent()}) =>
      LocalOrder(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        phone: phone ?? this.phone,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        items: items ?? this.items,
        itemCount: itemCount ?? this.itemCount,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        shippingCost: shippingCost ?? this.shippingCost,
        tax: tax ?? this.tax,
        total: total ?? this.total,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentMethod:
            paymentMethod.present ? paymentMethod.value : this.paymentMethod,
        courier: courier.present ? courier.value : this.courier,
        trackingId: trackingId.present ? trackingId.value : this.trackingId,
        awbNumber: awbNumber.present ? awbNumber.value : this.awbNumber,
        source: source ?? this.source,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  LocalOrder copyWithCompanion(LocalOrdersCompanion data) {
    return LocalOrder(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      phone: data.phone.present ? data.phone.value : this.phone,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      items: data.items.present ? data.items.value : this.items,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discount: data.discount.present ? data.discount.value : this.discount,
      shippingCost: data.shippingCost.present
          ? data.shippingCost.value
          : this.shippingCost,
      tax: data.tax.present ? data.tax.value : this.tax,
      total: data.total.present ? data.total.value : this.total,
      status: data.status.present ? data.status.value : this.status,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      courier: data.courier.present ? data.courier.value : this.courier,
      trackingId:
          data.trackingId.present ? data.trackingId.value : this.trackingId,
      awbNumber: data.awbNumber.present ? data.awbNumber.value : this.awbNumber,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrder(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('phone: $phone, ')
          ..write('customerName: $customerName, ')
          ..write('items: $items, ')
          ..write('itemCount: $itemCount, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('shippingCost: $shippingCost, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('courier: $courier, ')
          ..write('trackingId: $trackingId, ')
          ..write('awbNumber: $awbNumber, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      orderId,
      phone,
      customerName,
      items,
      itemCount,
      subtotal,
      discount,
      shippingCost,
      tax,
      total,
      status,
      paymentStatus,
      paymentMethod,
      courier,
      trackingId,
      awbNumber,
      source,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrder &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.phone == this.phone &&
          other.customerName == this.customerName &&
          other.items == this.items &&
          other.itemCount == this.itemCount &&
          other.subtotal == this.subtotal &&
          other.discount == this.discount &&
          other.shippingCost == this.shippingCost &&
          other.tax == this.tax &&
          other.total == this.total &&
          other.status == this.status &&
          other.paymentStatus == this.paymentStatus &&
          other.paymentMethod == this.paymentMethod &&
          other.courier == this.courier &&
          other.trackingId == this.trackingId &&
          other.awbNumber == this.awbNumber &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalOrdersCompanion extends UpdateCompanion<LocalOrder> {
  final Value<int> id;
  final Value<String> orderId;
  final Value<String> phone;
  final Value<String?> customerName;
  final Value<String> items;
  final Value<int> itemCount;
  final Value<double> subtotal;
  final Value<double> discount;
  final Value<double> shippingCost;
  final Value<double> tax;
  final Value<double> total;
  final Value<String> status;
  final Value<String> paymentStatus;
  final Value<String?> paymentMethod;
  final Value<String?> courier;
  final Value<String?> trackingId;
  final Value<String?> awbNumber;
  final Value<String> source;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const LocalOrdersCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.phone = const Value.absent(),
    this.customerName = const Value.absent(),
    this.items = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.shippingCost = const Value.absent(),
    this.tax = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.courier = const Value.absent(),
    this.trackingId = const Value.absent(),
    this.awbNumber = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalOrdersCompanion.insert({
    this.id = const Value.absent(),
    required String orderId,
    required String phone,
    this.customerName = const Value.absent(),
    this.items = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.shippingCost = const Value.absent(),
    this.tax = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.courier = const Value.absent(),
    this.trackingId = const Value.absent(),
    this.awbNumber = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : orderId = Value(orderId),
        phone = Value(phone);
  static Insertable<LocalOrder> custom({
    Expression<int>? id,
    Expression<String>? orderId,
    Expression<String>? phone,
    Expression<String>? customerName,
    Expression<String>? items,
    Expression<int>? itemCount,
    Expression<double>? subtotal,
    Expression<double>? discount,
    Expression<double>? shippingCost,
    Expression<double>? tax,
    Expression<double>? total,
    Expression<String>? status,
    Expression<String>? paymentStatus,
    Expression<String>? paymentMethod,
    Expression<String>? courier,
    Expression<String>? trackingId,
    Expression<String>? awbNumber,
    Expression<String>? source,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (phone != null) 'phone': phone,
      if (customerName != null) 'customer_name': customerName,
      if (items != null) 'items': items,
      if (itemCount != null) 'item_count': itemCount,
      if (subtotal != null) 'subtotal': subtotal,
      if (discount != null) 'discount': discount,
      if (shippingCost != null) 'shipping_cost': shippingCost,
      if (tax != null) 'tax': tax,
      if (total != null) 'total': total,
      if (status != null) 'status': status,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (courier != null) 'courier': courier,
      if (trackingId != null) 'tracking_id': trackingId,
      if (awbNumber != null) 'awb_number': awbNumber,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalOrdersCompanion copyWith(
      {Value<int>? id,
      Value<String>? orderId,
      Value<String>? phone,
      Value<String?>? customerName,
      Value<String>? items,
      Value<int>? itemCount,
      Value<double>? subtotal,
      Value<double>? discount,
      Value<double>? shippingCost,
      Value<double>? tax,
      Value<double>? total,
      Value<String>? status,
      Value<String>? paymentStatus,
      Value<String?>? paymentMethod,
      Value<String?>? courier,
      Value<String?>? trackingId,
      Value<String?>? awbNumber,
      Value<String>? source,
      Value<String?>? createdAt,
      Value<String?>? updatedAt}) {
    return LocalOrdersCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      phone: phone ?? this.phone,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shippingCost: shippingCost ?? this.shippingCost,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      courier: courier ?? this.courier,
      trackingId: trackingId ?? this.trackingId,
      awbNumber: awbNumber ?? this.awbNumber,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (shippingCost.present) {
      map['shipping_cost'] = Variable<double>(shippingCost.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (courier.present) {
      map['courier'] = Variable<String>(courier.value);
    }
    if (trackingId.present) {
      map['tracking_id'] = Variable<String>(trackingId.value);
    }
    if (awbNumber.present) {
      map['awb_number'] = Variable<String>(awbNumber.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrdersCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('phone: $phone, ')
          ..write('customerName: $customerName, ')
          ..write('items: $items, ')
          ..write('itemCount: $itemCount, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('shippingCost: $shippingCost, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('courier: $courier, ')
          ..write('trackingId: $trackingId, ')
          ..write('awbNumber: $awbNumber, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, LocalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _comparePriceMeta =
      const VerificationMeta('comparePrice');
  @override
  late final GeneratedColumn<double> comparePrice = GeneratedColumn<double>(
      'compare_price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
      'stock', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
      'images', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isFeaturedMeta =
      const VerificationMeta('isFeatured');
  @override
  late final GeneratedColumn<bool> isFeatured = GeneratedColumn<bool>(
      'is_featured', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_featured" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sku,
        name,
        description,
        price,
        comparePrice,
        category,
        stock,
        imageUrl,
        images,
        isActive,
        isFeatured,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(Insertable<LocalProduct> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('compare_price')) {
      context.handle(
          _comparePriceMeta,
          comparePrice.isAcceptableOrUnknown(
              data['compare_price']!, _comparePriceMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('stock')) {
      context.handle(
          _stockMeta, stock.isAcceptableOrUnknown(data['stock']!, _stockMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('images')) {
      context.handle(_imagesMeta,
          images.isAcceptableOrUnknown(data['images']!, _imagesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_featured')) {
      context.handle(
          _isFeaturedMeta,
          isFeatured.isAcceptableOrUnknown(
              data['is_featured']!, _isFeaturedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sku},
      ];
  @override
  LocalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProduct(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      comparePrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}compare_price']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      stock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      images: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}images'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isFeatured: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_featured'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }
}

class LocalProduct extends DataClass implements Insertable<LocalProduct> {
  final int id;
  final String sku;
  final String name;
  final String? description;
  final double price;
  final double? comparePrice;
  final String? category;
  final int stock;
  final String? imageUrl;
  final String images;
  final bool isActive;
  final bool isFeatured;
  final String? createdAt;
  final String? updatedAt;
  const LocalProduct(
      {required this.id,
      required this.sku,
      required this.name,
      this.description,
      required this.price,
      this.comparePrice,
      this.category,
      required this.stock,
      this.imageUrl,
      required this.images,
      required this.isActive,
      required this.isFeatured,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sku'] = Variable<String>(sku);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || comparePrice != null) {
      map['compare_price'] = Variable<double>(comparePrice);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['stock'] = Variable<int>(stock);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['images'] = Variable<String>(images);
    map['is_active'] = Variable<bool>(isActive);
    map['is_featured'] = Variable<bool>(isFeatured);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      sku: Value(sku),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
      comparePrice: comparePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(comparePrice),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      stock: Value(stock),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      images: Value(images),
      isActive: Value(isActive),
      isFeatured: Value(isFeatured),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalProduct.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProduct(
      id: serializer.fromJson<int>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      comparePrice: serializer.fromJson<double?>(json['comparePrice']),
      category: serializer.fromJson<String?>(json['category']),
      stock: serializer.fromJson<int>(json['stock']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      images: serializer.fromJson<String>(json['images']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isFeatured: serializer.fromJson<bool>(json['isFeatured']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<double>(price),
      'comparePrice': serializer.toJson<double?>(comparePrice),
      'category': serializer.toJson<String?>(category),
      'stock': serializer.toJson<int>(stock),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'images': serializer.toJson<String>(images),
      'isActive': serializer.toJson<bool>(isActive),
      'isFeatured': serializer.toJson<bool>(isFeatured),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  LocalProduct copyWith(
          {int? id,
          String? sku,
          String? name,
          Value<String?> description = const Value.absent(),
          double? price,
          Value<double?> comparePrice = const Value.absent(),
          Value<String?> category = const Value.absent(),
          int? stock,
          Value<String?> imageUrl = const Value.absent(),
          String? images,
          bool? isActive,
          bool? isFeatured,
          Value<String?> createdAt = const Value.absent(),
          Value<String?> updatedAt = const Value.absent()}) =>
      LocalProduct(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        price: price ?? this.price,
        comparePrice:
            comparePrice.present ? comparePrice.value : this.comparePrice,
        category: category.present ? category.value : this.category,
        stock: stock ?? this.stock,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        images: images ?? this.images,
        isActive: isActive ?? this.isActive,
        isFeatured: isFeatured ?? this.isFeatured,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  LocalProduct copyWithCompanion(LocalProductsCompanion data) {
    return LocalProduct(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      price: data.price.present ? data.price.value : this.price,
      comparePrice: data.comparePrice.present
          ? data.comparePrice.value
          : this.comparePrice,
      category: data.category.present ? data.category.value : this.category,
      stock: data.stock.present ? data.stock.value : this.stock,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      images: data.images.present ? data.images.value : this.images,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isFeatured:
          data.isFeatured.present ? data.isFeatured.value : this.isFeatured,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProduct(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('comparePrice: $comparePrice, ')
          ..write('category: $category, ')
          ..write('stock: $stock, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('images: $images, ')
          ..write('isActive: $isActive, ')
          ..write('isFeatured: $isFeatured, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sku,
      name,
      description,
      price,
      comparePrice,
      category,
      stock,
      imageUrl,
      images,
      isActive,
      isFeatured,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProduct &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.comparePrice == this.comparePrice &&
          other.category == this.category &&
          other.stock == this.stock &&
          other.imageUrl == this.imageUrl &&
          other.images == this.images &&
          other.isActive == this.isActive &&
          other.isFeatured == this.isFeatured &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalProductsCompanion extends UpdateCompanion<LocalProduct> {
  final Value<int> id;
  final Value<String> sku;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> price;
  final Value<double?> comparePrice;
  final Value<String?> category;
  final Value<int> stock;
  final Value<String?> imageUrl;
  final Value<String> images;
  final Value<bool> isActive;
  final Value<bool> isFeatured;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.comparePrice = const Value.absent(),
    this.category = const Value.absent(),
    this.stock = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.images = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isFeatured = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    this.id = const Value.absent(),
    required String sku,
    required String name,
    this.description = const Value.absent(),
    required double price,
    this.comparePrice = const Value.absent(),
    this.category = const Value.absent(),
    this.stock = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.images = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isFeatured = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : sku = Value(sku),
        name = Value(name),
        price = Value(price);
  static Insertable<LocalProduct> custom({
    Expression<int>? id,
    Expression<String>? sku,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<double>? comparePrice,
    Expression<String>? category,
    Expression<int>? stock,
    Expression<String>? imageUrl,
    Expression<String>? images,
    Expression<bool>? isActive,
    Expression<bool>? isFeatured,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (comparePrice != null) 'compare_price': comparePrice,
      if (category != null) 'category': category,
      if (stock != null) 'stock': stock,
      if (imageUrl != null) 'image_url': imageUrl,
      if (images != null) 'images': images,
      if (isActive != null) 'is_active': isActive,
      if (isFeatured != null) 'is_featured': isFeatured,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalProductsCompanion copyWith(
      {Value<int>? id,
      Value<String>? sku,
      Value<String>? name,
      Value<String?>? description,
      Value<double>? price,
      Value<double?>? comparePrice,
      Value<String?>? category,
      Value<int>? stock,
      Value<String?>? imageUrl,
      Value<String>? images,
      Value<bool>? isActive,
      Value<bool>? isFeatured,
      Value<String?>? createdAt,
      Value<String?>? updatedAt}) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      comparePrice: comparePrice ?? this.comparePrice,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (comparePrice.present) {
      map['compare_price'] = Variable<double>(comparePrice.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isFeatured.present) {
      map['is_featured'] = Variable<bool>(isFeatured.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('comparePrice: $comparePrice, ')
          ..write('category: $category, ')
          ..write('stock: $stock, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('images: $images, ')
          ..write('isActive: $isActive, ')
          ..write('isFeatured: $isFeatured, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalQuickRepliesTable extends LocalQuickReplies
    with TableInfo<$LocalQuickRepliesTable, LocalQuickReply> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQuickRepliesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _shortcutMeta =
      const VerificationMeta('shortcut');
  @override
  late final GeneratedColumn<String> shortcut = GeneratedColumn<String>(
      'shortcut', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageTypeMeta =
      const VerificationMeta('messageType');
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
      'message_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('general'));
  static const VerificationMeta _useCountMeta =
      const VerificationMeta('useCount');
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
      'use_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        shortcut,
        title,
        message,
        messageType,
        category,
        useCount,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_quick_replies';
  @override
  VerificationContext validateIntegrity(Insertable<LocalQuickReply> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shortcut')) {
      context.handle(_shortcutMeta,
          shortcut.isAcceptableOrUnknown(data['shortcut']!, _shortcutMeta));
    } else if (isInserting) {
      context.missing(_shortcutMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
          _messageTypeMeta,
          messageType.isAcceptableOrUnknown(
              data['message_type']!, _messageTypeMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('use_count')) {
      context.handle(_useCountMeta,
          useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {shortcut},
      ];
  @override
  LocalQuickReply map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQuickReply(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      shortcut: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shortcut'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      messageType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_type'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      useCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}use_count'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $LocalQuickRepliesTable createAlias(String alias) {
    return $LocalQuickRepliesTable(attachedDatabase, alias);
  }
}

class LocalQuickReply extends DataClass implements Insertable<LocalQuickReply> {
  final int id;
  final String shortcut;
  final String title;
  final String message;
  final String messageType;
  final String category;
  final int useCount;
  final bool isActive;
  final String? createdAt;
  const LocalQuickReply(
      {required this.id,
      required this.shortcut,
      required this.title,
      required this.message,
      required this.messageType,
      required this.category,
      required this.useCount,
      required this.isActive,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shortcut'] = Variable<String>(shortcut);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    map['message_type'] = Variable<String>(messageType);
    map['category'] = Variable<String>(category);
    map['use_count'] = Variable<int>(useCount);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  LocalQuickRepliesCompanion toCompanion(bool nullToAbsent) {
    return LocalQuickRepliesCompanion(
      id: Value(id),
      shortcut: Value(shortcut),
      title: Value(title),
      message: Value(message),
      messageType: Value(messageType),
      category: Value(category),
      useCount: Value(useCount),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalQuickReply.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQuickReply(
      id: serializer.fromJson<int>(json['id']),
      shortcut: serializer.fromJson<String>(json['shortcut']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      messageType: serializer.fromJson<String>(json['messageType']),
      category: serializer.fromJson<String>(json['category']),
      useCount: serializer.fromJson<int>(json['useCount']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shortcut': serializer.toJson<String>(shortcut),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'messageType': serializer.toJson<String>(messageType),
      'category': serializer.toJson<String>(category),
      'useCount': serializer.toJson<int>(useCount),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  LocalQuickReply copyWith(
          {int? id,
          String? shortcut,
          String? title,
          String? message,
          String? messageType,
          String? category,
          int? useCount,
          bool? isActive,
          Value<String?> createdAt = const Value.absent()}) =>
      LocalQuickReply(
        id: id ?? this.id,
        shortcut: shortcut ?? this.shortcut,
        title: title ?? this.title,
        message: message ?? this.message,
        messageType: messageType ?? this.messageType,
        category: category ?? this.category,
        useCount: useCount ?? this.useCount,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  LocalQuickReply copyWithCompanion(LocalQuickRepliesCompanion data) {
    return LocalQuickReply(
      id: data.id.present ? data.id.value : this.id,
      shortcut: data.shortcut.present ? data.shortcut.value : this.shortcut,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      messageType:
          data.messageType.present ? data.messageType.value : this.messageType,
      category: data.category.present ? data.category.value : this.category,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuickReply(')
          ..write('id: $id, ')
          ..write('shortcut: $shortcut, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('messageType: $messageType, ')
          ..write('category: $category, ')
          ..write('useCount: $useCount, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shortcut, title, message, messageType,
      category, useCount, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQuickReply &&
          other.id == this.id &&
          other.shortcut == this.shortcut &&
          other.title == this.title &&
          other.message == this.message &&
          other.messageType == this.messageType &&
          other.category == this.category &&
          other.useCount == this.useCount &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class LocalQuickRepliesCompanion extends UpdateCompanion<LocalQuickReply> {
  final Value<int> id;
  final Value<String> shortcut;
  final Value<String> title;
  final Value<String> message;
  final Value<String> messageType;
  final Value<String> category;
  final Value<int> useCount;
  final Value<bool> isActive;
  final Value<String?> createdAt;
  const LocalQuickRepliesCompanion({
    this.id = const Value.absent(),
    this.shortcut = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.messageType = const Value.absent(),
    this.category = const Value.absent(),
    this.useCount = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalQuickRepliesCompanion.insert({
    this.id = const Value.absent(),
    required String shortcut,
    required String title,
    required String message,
    this.messageType = const Value.absent(),
    this.category = const Value.absent(),
    this.useCount = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : shortcut = Value(shortcut),
        title = Value(title),
        message = Value(message);
  static Insertable<LocalQuickReply> custom({
    Expression<int>? id,
    Expression<String>? shortcut,
    Expression<String>? title,
    Expression<String>? message,
    Expression<String>? messageType,
    Expression<String>? category,
    Expression<int>? useCount,
    Expression<bool>? isActive,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shortcut != null) 'shortcut': shortcut,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (messageType != null) 'message_type': messageType,
      if (category != null) 'category': category,
      if (useCount != null) 'use_count': useCount,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalQuickRepliesCompanion copyWith(
      {Value<int>? id,
      Value<String>? shortcut,
      Value<String>? title,
      Value<String>? message,
      Value<String>? messageType,
      Value<String>? category,
      Value<int>? useCount,
      Value<bool>? isActive,
      Value<String?>? createdAt}) {
    return LocalQuickRepliesCompanion(
      id: id ?? this.id,
      shortcut: shortcut ?? this.shortcut,
      title: title ?? this.title,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      category: category ?? this.category,
      useCount: useCount ?? this.useCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shortcut.present) {
      map['shortcut'] = Variable<String>(shortcut.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuickRepliesCompanion(')
          ..write('id: $id, ')
          ..write('shortcut: $shortcut, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('messageType: $messageType, ')
          ..write('category: $category, ')
          ..write('useCount: $useCount, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalLabelsTable extends LocalLabels
    with TableInfo<$LocalLabelsTable, LocalLabel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#DBAC35'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerCountMeta =
      const VerificationMeta('customerCount');
  @override
  late final GeneratedColumn<int> customerCount = GeneratedColumn<int>(
      'customer_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _chatCountMeta =
      const VerificationMeta('chatCount');
  @override
  late final GeneratedColumn<int> chatCount = GeneratedColumn<int>(
      'chat_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        color,
        description,
        customerCount,
        chatCount,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_labels';
  @override
  VerificationContext validateIntegrity(Insertable<LocalLabel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('customer_count')) {
      context.handle(
          _customerCountMeta,
          customerCount.isAcceptableOrUnknown(
              data['customer_count']!, _customerCountMeta));
    }
    if (data.containsKey('chat_count')) {
      context.handle(_chatCountMeta,
          chatCount.isAcceptableOrUnknown(data['chat_count']!, _chatCountMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {name},
      ];
  @override
  LocalLabel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLabel(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      customerCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}customer_count'])!,
      chatCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chat_count'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $LocalLabelsTable createAlias(String alias) {
    return $LocalLabelsTable(attachedDatabase, alias);
  }
}

class LocalLabel extends DataClass implements Insertable<LocalLabel> {
  final int id;
  final String name;
  final String color;
  final String? description;
  final int customerCount;
  final int chatCount;
  final bool isActive;
  final String? createdAt;
  const LocalLabel(
      {required this.id,
      required this.name,
      required this.color,
      this.description,
      required this.customerCount,
      required this.chatCount,
      required this.isActive,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['customer_count'] = Variable<int>(customerCount);
    map['chat_count'] = Variable<int>(chatCount);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  LocalLabelsCompanion toCompanion(bool nullToAbsent) {
    return LocalLabelsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      customerCount: Value(customerCount),
      chatCount: Value(chatCount),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalLabel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLabel(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      description: serializer.fromJson<String?>(json['description']),
      customerCount: serializer.fromJson<int>(json['customerCount']),
      chatCount: serializer.fromJson<int>(json['chatCount']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'description': serializer.toJson<String?>(description),
      'customerCount': serializer.toJson<int>(customerCount),
      'chatCount': serializer.toJson<int>(chatCount),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  LocalLabel copyWith(
          {int? id,
          String? name,
          String? color,
          Value<String?> description = const Value.absent(),
          int? customerCount,
          int? chatCount,
          bool? isActive,
          Value<String?> createdAt = const Value.absent()}) =>
      LocalLabel(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        description: description.present ? description.value : this.description,
        customerCount: customerCount ?? this.customerCount,
        chatCount: chatCount ?? this.chatCount,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  LocalLabel copyWithCompanion(LocalLabelsCompanion data) {
    return LocalLabel(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      description:
          data.description.present ? data.description.value : this.description,
      customerCount: data.customerCount.present
          ? data.customerCount.value
          : this.customerCount,
      chatCount: data.chatCount.present ? data.chatCount.value : this.chatCount,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLabel(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('description: $description, ')
          ..write('customerCount: $customerCount, ')
          ..write('chatCount: $chatCount, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, description, customerCount,
      chatCount, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLabel &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.description == this.description &&
          other.customerCount == this.customerCount &&
          other.chatCount == this.chatCount &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class LocalLabelsCompanion extends UpdateCompanion<LocalLabel> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> color;
  final Value<String?> description;
  final Value<int> customerCount;
  final Value<int> chatCount;
  final Value<bool> isActive;
  final Value<String?> createdAt;
  const LocalLabelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.description = const Value.absent(),
    this.customerCount = const Value.absent(),
    this.chatCount = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalLabelsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.description = const Value.absent(),
    this.customerCount = const Value.absent(),
    this.chatCount = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<LocalLabel> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? description,
    Expression<int>? customerCount,
    Expression<int>? chatCount,
    Expression<bool>? isActive,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (description != null) 'description': description,
      if (customerCount != null) 'customer_count': customerCount,
      if (chatCount != null) 'chat_count': chatCount,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalLabelsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? color,
      Value<String?>? description,
      Value<int>? customerCount,
      Value<int>? chatCount,
      Value<bool>? isActive,
      Value<String?>? createdAt}) {
    return LocalLabelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      customerCount: customerCount ?? this.customerCount,
      chatCount: chatCount ?? this.chatCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (customerCount.present) {
      map['customer_count'] = Variable<int>(customerCount.value);
    }
    if (chatCount.present) {
      map['chat_count'] = Variable<int>(chatCount.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLabelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('description: $description, ')
          ..write('customerCount: $customerCount, ')
          ..write('chatCount: $chatCount, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $LocalChatsTable localChats = $LocalChatsTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalCustomersTable localCustomers = $LocalCustomersTable(this);
  late final $LocalOrdersTable localOrders = $LocalOrdersTable(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalQuickRepliesTable localQuickReplies =
      $LocalQuickRepliesTable(this);
  late final $LocalLabelsTable localLabels = $LocalLabelsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localChats,
        localMessages,
        localCustomers,
        localOrders,
        localProducts,
        localQuickReplies,
        localLabels
      ];
}

typedef $$LocalChatsTableCreateCompanionBuilder = LocalChatsCompanion Function({
  Value<int> id,
  required String phone,
  Value<String?> customerName,
  Value<String?> lastMessage,
  Value<String> lastMessageType,
  Value<String?> lastTimestamp,
  Value<String?> lastDirection,
  Value<int> unreadCount,
  Value<int> totalMessages,
  Value<String?> assignedTo,
  Value<String> status,
  Value<String> priority,
  Value<String> labels,
  Value<bool> isStarred,
  Value<bool> isBlocked,
  Value<bool> isBotEnabled,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});
typedef $$LocalChatsTableUpdateCompanionBuilder = LocalChatsCompanion Function({
  Value<int> id,
  Value<String> phone,
  Value<String?> customerName,
  Value<String?> lastMessage,
  Value<String> lastMessageType,
  Value<String?> lastTimestamp,
  Value<String?> lastDirection,
  Value<int> unreadCount,
  Value<int> totalMessages,
  Value<String?> assignedTo,
  Value<String> status,
  Value<String> priority,
  Value<String> labels,
  Value<bool> isStarred,
  Value<bool> isBlocked,
  Value<bool> isBotEnabled,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});

class $$LocalChatsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalChatsTable,
    LocalChat,
    $$LocalChatsTableFilterComposer,
    $$LocalChatsTableOrderingComposer,
    $$LocalChatsTableCreateCompanionBuilder,
    $$LocalChatsTableUpdateCompanionBuilder> {
  $$LocalChatsTableTableManager(_$LocalDatabase db, $LocalChatsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalChatsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalChatsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String?> lastMessage = const Value.absent(),
            Value<String> lastMessageType = const Value.absent(),
            Value<String?> lastTimestamp = const Value.absent(),
            Value<String?> lastDirection = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<int> totalMessages = const Value.absent(),
            Value<String?> assignedTo = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String> labels = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isBlocked = const Value.absent(),
            Value<bool> isBotEnabled = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalChatsCompanion(
            id: id,
            phone: phone,
            customerName: customerName,
            lastMessage: lastMessage,
            lastMessageType: lastMessageType,
            lastTimestamp: lastTimestamp,
            lastDirection: lastDirection,
            unreadCount: unreadCount,
            totalMessages: totalMessages,
            assignedTo: assignedTo,
            status: status,
            priority: priority,
            labels: labels,
            isStarred: isStarred,
            isBlocked: isBlocked,
            isBotEnabled: isBotEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String phone,
            Value<String?> customerName = const Value.absent(),
            Value<String?> lastMessage = const Value.absent(),
            Value<String> lastMessageType = const Value.absent(),
            Value<String?> lastTimestamp = const Value.absent(),
            Value<String?> lastDirection = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<int> totalMessages = const Value.absent(),
            Value<String?> assignedTo = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String> labels = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isBlocked = const Value.absent(),
            Value<bool> isBotEnabled = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalChatsCompanion.insert(
            id: id,
            phone: phone,
            customerName: customerName,
            lastMessage: lastMessage,
            lastMessageType: lastMessageType,
            lastTimestamp: lastTimestamp,
            lastDirection: lastDirection,
            unreadCount: unreadCount,
            totalMessages: totalMessages,
            assignedTo: assignedTo,
            status: status,
            priority: priority,
            labels: labels,
            isStarred: isStarred,
            isBlocked: isBlocked,
            isBotEnabled: isBotEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$LocalChatsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalChatsTable> {
  $$LocalChatsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastMessage => $state.composableBuilder(
      column: $state.table.lastMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastMessageType => $state.composableBuilder(
      column: $state.table.lastMessageType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastTimestamp => $state.composableBuilder(
      column: $state.table.lastTimestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastDirection => $state.composableBuilder(
      column: $state.table.lastDirection,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get unreadCount => $state.composableBuilder(
      column: $state.table.unreadCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalMessages => $state.composableBuilder(
      column: $state.table.totalMessages,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get assignedTo => $state.composableBuilder(
      column: $state.table.assignedTo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get labels => $state.composableBuilder(
      column: $state.table.labels,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isStarred => $state.composableBuilder(
      column: $state.table.isStarred,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isBlocked => $state.composableBuilder(
      column: $state.table.isBlocked,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isBotEnabled => $state.composableBuilder(
      column: $state.table.isBotEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalChatsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalChatsTable> {
  $$LocalChatsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastMessage => $state.composableBuilder(
      column: $state.table.lastMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastMessageType => $state.composableBuilder(
      column: $state.table.lastMessageType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastTimestamp => $state.composableBuilder(
      column: $state.table.lastTimestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastDirection => $state.composableBuilder(
      column: $state.table.lastDirection,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get unreadCount => $state.composableBuilder(
      column: $state.table.unreadCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalMessages => $state.composableBuilder(
      column: $state.table.totalMessages,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get assignedTo => $state.composableBuilder(
      column: $state.table.assignedTo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get labels => $state.composableBuilder(
      column: $state.table.labels,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isStarred => $state.composableBuilder(
      column: $state.table.isStarred,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isBlocked => $state.composableBuilder(
      column: $state.table.isBlocked,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isBotEnabled => $state.composableBuilder(
      column: $state.table.isBotEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalMessagesTableCreateCompanionBuilder = LocalMessagesCompanion
    Function({
  Value<int> id,
  Value<String?> messageId,
  required String phone,
  Value<String?> msgText,
  Value<String> messageType,
  required String direction,
  Value<String?> mediaId,
  Value<String?> mediaUrl,
  Value<String?> mediaMime,
  Value<String?> mediaCaption,
  Value<String?> buttonId,
  Value<String?> buttonText,
  Value<String?> buttons,
  Value<String?> contextMessageId,
  Value<bool> isForwarded,
  Value<String> status,
  Value<bool> isAutoReply,
  Value<bool> isTemplate,
  Value<String?> templateName,
  required String timestamp,
  Value<String?> deliveredAt,
  Value<String?> readAt,
  Value<String?> createdAt,
});
typedef $$LocalMessagesTableUpdateCompanionBuilder = LocalMessagesCompanion
    Function({
  Value<int> id,
  Value<String?> messageId,
  Value<String> phone,
  Value<String?> msgText,
  Value<String> messageType,
  Value<String> direction,
  Value<String?> mediaId,
  Value<String?> mediaUrl,
  Value<String?> mediaMime,
  Value<String?> mediaCaption,
  Value<String?> buttonId,
  Value<String?> buttonText,
  Value<String?> buttons,
  Value<String?> contextMessageId,
  Value<bool> isForwarded,
  Value<String> status,
  Value<bool> isAutoReply,
  Value<bool> isTemplate,
  Value<String?> templateName,
  Value<String> timestamp,
  Value<String?> deliveredAt,
  Value<String?> readAt,
  Value<String?> createdAt,
});

class $$LocalMessagesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalMessagesTable,
    LocalMessage,
    $$LocalMessagesTableFilterComposer,
    $$LocalMessagesTableOrderingComposer,
    $$LocalMessagesTableCreateCompanionBuilder,
    $$LocalMessagesTableUpdateCompanionBuilder> {
  $$LocalMessagesTableTableManager(
      _$LocalDatabase db, $LocalMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalMessagesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalMessagesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String?> msgText = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String?> mediaId = const Value.absent(),
            Value<String?> mediaUrl = const Value.absent(),
            Value<String?> mediaMime = const Value.absent(),
            Value<String?> mediaCaption = const Value.absent(),
            Value<String?> buttonId = const Value.absent(),
            Value<String?> buttonText = const Value.absent(),
            Value<String?> buttons = const Value.absent(),
            Value<String?> contextMessageId = const Value.absent(),
            Value<bool> isForwarded = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isAutoReply = const Value.absent(),
            Value<bool> isTemplate = const Value.absent(),
            Value<String?> templateName = const Value.absent(),
            Value<String> timestamp = const Value.absent(),
            Value<String?> deliveredAt = const Value.absent(),
            Value<String?> readAt = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalMessagesCompanion(
            id: id,
            messageId: messageId,
            phone: phone,
            msgText: msgText,
            messageType: messageType,
            direction: direction,
            mediaId: mediaId,
            mediaUrl: mediaUrl,
            mediaMime: mediaMime,
            mediaCaption: mediaCaption,
            buttonId: buttonId,
            buttonText: buttonText,
            buttons: buttons,
            contextMessageId: contextMessageId,
            isForwarded: isForwarded,
            status: status,
            isAutoReply: isAutoReply,
            isTemplate: isTemplate,
            templateName: templateName,
            timestamp: timestamp,
            deliveredAt: deliveredAt,
            readAt: readAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            required String phone,
            Value<String?> msgText = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            required String direction,
            Value<String?> mediaId = const Value.absent(),
            Value<String?> mediaUrl = const Value.absent(),
            Value<String?> mediaMime = const Value.absent(),
            Value<String?> mediaCaption = const Value.absent(),
            Value<String?> buttonId = const Value.absent(),
            Value<String?> buttonText = const Value.absent(),
            Value<String?> buttons = const Value.absent(),
            Value<String?> contextMessageId = const Value.absent(),
            Value<bool> isForwarded = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isAutoReply = const Value.absent(),
            Value<bool> isTemplate = const Value.absent(),
            Value<String?> templateName = const Value.absent(),
            required String timestamp,
            Value<String?> deliveredAt = const Value.absent(),
            Value<String?> readAt = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalMessagesCompanion.insert(
            id: id,
            messageId: messageId,
            phone: phone,
            msgText: msgText,
            messageType: messageType,
            direction: direction,
            mediaId: mediaId,
            mediaUrl: mediaUrl,
            mediaMime: mediaMime,
            mediaCaption: mediaCaption,
            buttonId: buttonId,
            buttonText: buttonText,
            buttons: buttons,
            contextMessageId: contextMessageId,
            isForwarded: isForwarded,
            status: status,
            isAutoReply: isAutoReply,
            isTemplate: isTemplate,
            templateName: templateName,
            timestamp: timestamp,
            deliveredAt: deliveredAt,
            readAt: readAt,
            createdAt: createdAt,
          ),
        ));
}

class $$LocalMessagesTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageId => $state.composableBuilder(
      column: $state.table.messageId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get msgText => $state.composableBuilder(
      column: $state.table.msgText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get direction => $state.composableBuilder(
      column: $state.table.direction,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mediaId => $state.composableBuilder(
      column: $state.table.mediaId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mediaUrl => $state.composableBuilder(
      column: $state.table.mediaUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mediaMime => $state.composableBuilder(
      column: $state.table.mediaMime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mediaCaption => $state.composableBuilder(
      column: $state.table.mediaCaption,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get buttonId => $state.composableBuilder(
      column: $state.table.buttonId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get buttonText => $state.composableBuilder(
      column: $state.table.buttonText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get buttons => $state.composableBuilder(
      column: $state.table.buttons,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contextMessageId => $state.composableBuilder(
      column: $state.table.contextMessageId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isForwarded => $state.composableBuilder(
      column: $state.table.isForwarded,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isAutoReply => $state.composableBuilder(
      column: $state.table.isAutoReply,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isTemplate => $state.composableBuilder(
      column: $state.table.isTemplate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get templateName => $state.composableBuilder(
      column: $state.table.templateName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get deliveredAt => $state.composableBuilder(
      column: $state.table.deliveredAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get readAt => $state.composableBuilder(
      column: $state.table.readAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalMessagesTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageId => $state.composableBuilder(
      column: $state.table.messageId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get msgText => $state.composableBuilder(
      column: $state.table.msgText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get direction => $state.composableBuilder(
      column: $state.table.direction,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mediaId => $state.composableBuilder(
      column: $state.table.mediaId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mediaUrl => $state.composableBuilder(
      column: $state.table.mediaUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mediaMime => $state.composableBuilder(
      column: $state.table.mediaMime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mediaCaption => $state.composableBuilder(
      column: $state.table.mediaCaption,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get buttonId => $state.composableBuilder(
      column: $state.table.buttonId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get buttonText => $state.composableBuilder(
      column: $state.table.buttonText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get buttons => $state.composableBuilder(
      column: $state.table.buttons,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contextMessageId => $state.composableBuilder(
      column: $state.table.contextMessageId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isForwarded => $state.composableBuilder(
      column: $state.table.isForwarded,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isAutoReply => $state.composableBuilder(
      column: $state.table.isAutoReply,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isTemplate => $state.composableBuilder(
      column: $state.table.isTemplate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get templateName => $state.composableBuilder(
      column: $state.table.templateName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get deliveredAt => $state.composableBuilder(
      column: $state.table.deliveredAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get readAt => $state.composableBuilder(
      column: $state.table.readAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalCustomersTableCreateCompanionBuilder = LocalCustomersCompanion
    Function({
  Value<int> id,
  required String phone,
  Value<String?> name,
  Value<String?> email,
  Value<String?> address,
  Value<String?> state,
  Value<String?> city,
  Value<String?> pincode,
  Value<String> segment,
  Value<String> tier,
  Value<String> labels,
  Value<int> messageCount,
  Value<int> orderCount,
  Value<double> totalSpent,
  Value<String> language,
  Value<bool> optedIn,
  Value<String?> firstSeen,
  Value<String?> lastSeen,
  Value<String?> lastOrderAt,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});
typedef $$LocalCustomersTableUpdateCompanionBuilder = LocalCustomersCompanion
    Function({
  Value<int> id,
  Value<String> phone,
  Value<String?> name,
  Value<String?> email,
  Value<String?> address,
  Value<String?> state,
  Value<String?> city,
  Value<String?> pincode,
  Value<String> segment,
  Value<String> tier,
  Value<String> labels,
  Value<int> messageCount,
  Value<int> orderCount,
  Value<double> totalSpent,
  Value<String> language,
  Value<bool> optedIn,
  Value<String?> firstSeen,
  Value<String?> lastSeen,
  Value<String?> lastOrderAt,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});

class $$LocalCustomersTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalCustomersTable,
    LocalCustomer,
    $$LocalCustomersTableFilterComposer,
    $$LocalCustomersTableOrderingComposer,
    $$LocalCustomersTableCreateCompanionBuilder,
    $$LocalCustomersTableUpdateCompanionBuilder> {
  $$LocalCustomersTableTableManager(
      _$LocalDatabase db, $LocalCustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalCustomersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalCustomersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> state = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<String?> pincode = const Value.absent(),
            Value<String> segment = const Value.absent(),
            Value<String> tier = const Value.absent(),
            Value<String> labels = const Value.absent(),
            Value<int> messageCount = const Value.absent(),
            Value<int> orderCount = const Value.absent(),
            Value<double> totalSpent = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<bool> optedIn = const Value.absent(),
            Value<String?> firstSeen = const Value.absent(),
            Value<String?> lastSeen = const Value.absent(),
            Value<String?> lastOrderAt = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalCustomersCompanion(
            id: id,
            phone: phone,
            name: name,
            email: email,
            address: address,
            state: state,
            city: city,
            pincode: pincode,
            segment: segment,
            tier: tier,
            labels: labels,
            messageCount: messageCount,
            orderCount: orderCount,
            totalSpent: totalSpent,
            language: language,
            optedIn: optedIn,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            lastOrderAt: lastOrderAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String phone,
            Value<String?> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> state = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<String?> pincode = const Value.absent(),
            Value<String> segment = const Value.absent(),
            Value<String> tier = const Value.absent(),
            Value<String> labels = const Value.absent(),
            Value<int> messageCount = const Value.absent(),
            Value<int> orderCount = const Value.absent(),
            Value<double> totalSpent = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<bool> optedIn = const Value.absent(),
            Value<String?> firstSeen = const Value.absent(),
            Value<String?> lastSeen = const Value.absent(),
            Value<String?> lastOrderAt = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalCustomersCompanion.insert(
            id: id,
            phone: phone,
            name: name,
            email: email,
            address: address,
            state: state,
            city: city,
            pincode: pincode,
            segment: segment,
            tier: tier,
            labels: labels,
            messageCount: messageCount,
            orderCount: orderCount,
            totalSpent: totalSpent,
            language: language,
            optedIn: optedIn,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            lastOrderAt: lastOrderAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$LocalCustomersTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get state => $state.composableBuilder(
      column: $state.table.state,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get city => $state.composableBuilder(
      column: $state.table.city,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pincode => $state.composableBuilder(
      column: $state.table.pincode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get segment => $state.composableBuilder(
      column: $state.table.segment,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tier => $state.composableBuilder(
      column: $state.table.tier,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get labels => $state.composableBuilder(
      column: $state.table.labels,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get messageCount => $state.composableBuilder(
      column: $state.table.messageCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get orderCount => $state.composableBuilder(
      column: $state.table.orderCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get totalSpent => $state.composableBuilder(
      column: $state.table.totalSpent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get language => $state.composableBuilder(
      column: $state.table.language,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get optedIn => $state.composableBuilder(
      column: $state.table.optedIn,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get firstSeen => $state.composableBuilder(
      column: $state.table.firstSeen,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastSeen => $state.composableBuilder(
      column: $state.table.lastSeen,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastOrderAt => $state.composableBuilder(
      column: $state.table.lastOrderAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalCustomersTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get state => $state.composableBuilder(
      column: $state.table.state,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get city => $state.composableBuilder(
      column: $state.table.city,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pincode => $state.composableBuilder(
      column: $state.table.pincode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get segment => $state.composableBuilder(
      column: $state.table.segment,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tier => $state.composableBuilder(
      column: $state.table.tier,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get labels => $state.composableBuilder(
      column: $state.table.labels,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get messageCount => $state.composableBuilder(
      column: $state.table.messageCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get orderCount => $state.composableBuilder(
      column: $state.table.orderCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get totalSpent => $state.composableBuilder(
      column: $state.table.totalSpent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get language => $state.composableBuilder(
      column: $state.table.language,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get optedIn => $state.composableBuilder(
      column: $state.table.optedIn,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get firstSeen => $state.composableBuilder(
      column: $state.table.firstSeen,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastSeen => $state.composableBuilder(
      column: $state.table.lastSeen,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastOrderAt => $state.composableBuilder(
      column: $state.table.lastOrderAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalOrdersTableCreateCompanionBuilder = LocalOrdersCompanion
    Function({
  Value<int> id,
  required String orderId,
  required String phone,
  Value<String?> customerName,
  Value<String> items,
  Value<int> itemCount,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> shippingCost,
  Value<double> tax,
  Value<double> total,
  Value<String> status,
  Value<String> paymentStatus,
  Value<String?> paymentMethod,
  Value<String?> courier,
  Value<String?> trackingId,
  Value<String?> awbNumber,
  Value<String> source,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});
typedef $$LocalOrdersTableUpdateCompanionBuilder = LocalOrdersCompanion
    Function({
  Value<int> id,
  Value<String> orderId,
  Value<String> phone,
  Value<String?> customerName,
  Value<String> items,
  Value<int> itemCount,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> shippingCost,
  Value<double> tax,
  Value<double> total,
  Value<String> status,
  Value<String> paymentStatus,
  Value<String?> paymentMethod,
  Value<String?> courier,
  Value<String?> trackingId,
  Value<String?> awbNumber,
  Value<String> source,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});

class $$LocalOrdersTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalOrdersTable,
    LocalOrder,
    $$LocalOrdersTableFilterComposer,
    $$LocalOrdersTableOrderingComposer,
    $$LocalOrdersTableCreateCompanionBuilder,
    $$LocalOrdersTableUpdateCompanionBuilder> {
  $$LocalOrdersTableTableManager(_$LocalDatabase db, $LocalOrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalOrdersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalOrdersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String> items = const Value.absent(),
            Value<int> itemCount = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> shippingCost = const Value.absent(),
            Value<double> tax = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> courier = const Value.absent(),
            Value<String?> trackingId = const Value.absent(),
            Value<String?> awbNumber = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalOrdersCompanion(
            id: id,
            orderId: orderId,
            phone: phone,
            customerName: customerName,
            items: items,
            itemCount: itemCount,
            subtotal: subtotal,
            discount: discount,
            shippingCost: shippingCost,
            tax: tax,
            total: total,
            status: status,
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod,
            courier: courier,
            trackingId: trackingId,
            awbNumber: awbNumber,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String orderId,
            required String phone,
            Value<String?> customerName = const Value.absent(),
            Value<String> items = const Value.absent(),
            Value<int> itemCount = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> shippingCost = const Value.absent(),
            Value<double> tax = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> courier = const Value.absent(),
            Value<String?> trackingId = const Value.absent(),
            Value<String?> awbNumber = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalOrdersCompanion.insert(
            id: id,
            orderId: orderId,
            phone: phone,
            customerName: customerName,
            items: items,
            itemCount: itemCount,
            subtotal: subtotal,
            discount: discount,
            shippingCost: shippingCost,
            tax: tax,
            total: total,
            status: status,
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod,
            courier: courier,
            trackingId: trackingId,
            awbNumber: awbNumber,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$LocalOrdersTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get orderId => $state.composableBuilder(
      column: $state.table.orderId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get items => $state.composableBuilder(
      column: $state.table.items,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get itemCount => $state.composableBuilder(
      column: $state.table.itemCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get shippingCost => $state.composableBuilder(
      column: $state.table.shippingCost,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get tax => $state.composableBuilder(
      column: $state.table.tax,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get paymentStatus => $state.composableBuilder(
      column: $state.table.paymentStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get paymentMethod => $state.composableBuilder(
      column: $state.table.paymentMethod,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get courier => $state.composableBuilder(
      column: $state.table.courier,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get trackingId => $state.composableBuilder(
      column: $state.table.trackingId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get awbNumber => $state.composableBuilder(
      column: $state.table.awbNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalOrdersTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get orderId => $state.composableBuilder(
      column: $state.table.orderId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get items => $state.composableBuilder(
      column: $state.table.items,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get itemCount => $state.composableBuilder(
      column: $state.table.itemCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get shippingCost => $state.composableBuilder(
      column: $state.table.shippingCost,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get tax => $state.composableBuilder(
      column: $state.table.tax,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get paymentStatus => $state.composableBuilder(
      column: $state.table.paymentStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get paymentMethod => $state.composableBuilder(
      column: $state.table.paymentMethod,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get courier => $state.composableBuilder(
      column: $state.table.courier,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get trackingId => $state.composableBuilder(
      column: $state.table.trackingId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get awbNumber => $state.composableBuilder(
      column: $state.table.awbNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalProductsTableCreateCompanionBuilder = LocalProductsCompanion
    Function({
  Value<int> id,
  required String sku,
  required String name,
  Value<String?> description,
  required double price,
  Value<double?> comparePrice,
  Value<String?> category,
  Value<int> stock,
  Value<String?> imageUrl,
  Value<String> images,
  Value<bool> isActive,
  Value<bool> isFeatured,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});
typedef $$LocalProductsTableUpdateCompanionBuilder = LocalProductsCompanion
    Function({
  Value<int> id,
  Value<String> sku,
  Value<String> name,
  Value<String?> description,
  Value<double> price,
  Value<double?> comparePrice,
  Value<String?> category,
  Value<int> stock,
  Value<String?> imageUrl,
  Value<String> images,
  Value<bool> isActive,
  Value<bool> isFeatured,
  Value<String?> createdAt,
  Value<String?> updatedAt,
});

class $$LocalProductsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalProductsTable,
    LocalProduct,
    $$LocalProductsTableFilterComposer,
    $$LocalProductsTableOrderingComposer,
    $$LocalProductsTableCreateCompanionBuilder,
    $$LocalProductsTableUpdateCompanionBuilder> {
  $$LocalProductsTableTableManager(
      _$LocalDatabase db, $LocalProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalProductsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalProductsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double?> comparePrice = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> stock = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String> images = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isFeatured = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalProductsCompanion(
            id: id,
            sku: sku,
            name: name,
            description: description,
            price: price,
            comparePrice: comparePrice,
            category: category,
            stock: stock,
            imageUrl: imageUrl,
            images: images,
            isActive: isActive,
            isFeatured: isFeatured,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String sku,
            required String name,
            Value<String?> description = const Value.absent(),
            required double price,
            Value<double?> comparePrice = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> stock = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String> images = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isFeatured = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
            Value<String?> updatedAt = const Value.absent(),
          }) =>
              LocalProductsCompanion.insert(
            id: id,
            sku: sku,
            name: name,
            description: description,
            price: price,
            comparePrice: comparePrice,
            category: category,
            stock: stock,
            imageUrl: imageUrl,
            images: images,
            isActive: isActive,
            isFeatured: isFeatured,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$LocalProductsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sku => $state.composableBuilder(
      column: $state.table.sku,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get comparePrice => $state.composableBuilder(
      column: $state.table.comparePrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get stock => $state.composableBuilder(
      column: $state.table.stock,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imageUrl => $state.composableBuilder(
      column: $state.table.imageUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get images => $state.composableBuilder(
      column: $state.table.images,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFeatured => $state.composableBuilder(
      column: $state.table.isFeatured,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalProductsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sku => $state.composableBuilder(
      column: $state.table.sku,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get comparePrice => $state.composableBuilder(
      column: $state.table.comparePrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get stock => $state.composableBuilder(
      column: $state.table.stock,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imageUrl => $state.composableBuilder(
      column: $state.table.imageUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get images => $state.composableBuilder(
      column: $state.table.images,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFeatured => $state.composableBuilder(
      column: $state.table.isFeatured,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalQuickRepliesTableCreateCompanionBuilder
    = LocalQuickRepliesCompanion Function({
  Value<int> id,
  required String shortcut,
  required String title,
  required String message,
  Value<String> messageType,
  Value<String> category,
  Value<int> useCount,
  Value<bool> isActive,
  Value<String?> createdAt,
});
typedef $$LocalQuickRepliesTableUpdateCompanionBuilder
    = LocalQuickRepliesCompanion Function({
  Value<int> id,
  Value<String> shortcut,
  Value<String> title,
  Value<String> message,
  Value<String> messageType,
  Value<String> category,
  Value<int> useCount,
  Value<bool> isActive,
  Value<String?> createdAt,
});

class $$LocalQuickRepliesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalQuickRepliesTable,
    LocalQuickReply,
    $$LocalQuickRepliesTableFilterComposer,
    $$LocalQuickRepliesTableOrderingComposer,
    $$LocalQuickRepliesTableCreateCompanionBuilder,
    $$LocalQuickRepliesTableUpdateCompanionBuilder> {
  $$LocalQuickRepliesTableTableManager(
      _$LocalDatabase db, $LocalQuickRepliesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalQuickRepliesTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LocalQuickRepliesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> shortcut = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalQuickRepliesCompanion(
            id: id,
            shortcut: shortcut,
            title: title,
            message: message,
            messageType: messageType,
            category: category,
            useCount: useCount,
            isActive: isActive,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String shortcut,
            required String title,
            required String message,
            Value<String> messageType = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalQuickRepliesCompanion.insert(
            id: id,
            shortcut: shortcut,
            title: title,
            message: message,
            messageType: messageType,
            category: category,
            useCount: useCount,
            isActive: isActive,
            createdAt: createdAt,
          ),
        ));
}

class $$LocalQuickRepliesTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalQuickRepliesTable> {
  $$LocalQuickRepliesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get shortcut => $state.composableBuilder(
      column: $state.table.shortcut,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get message => $state.composableBuilder(
      column: $state.table.message,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get useCount => $state.composableBuilder(
      column: $state.table.useCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalQuickRepliesTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalQuickRepliesTable> {
  $$LocalQuickRepliesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get shortcut => $state.composableBuilder(
      column: $state.table.shortcut,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get message => $state.composableBuilder(
      column: $state.table.message,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get useCount => $state.composableBuilder(
      column: $state.table.useCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalLabelsTableCreateCompanionBuilder = LocalLabelsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String> color,
  Value<String?> description,
  Value<int> customerCount,
  Value<int> chatCount,
  Value<bool> isActive,
  Value<String?> createdAt,
});
typedef $$LocalLabelsTableUpdateCompanionBuilder = LocalLabelsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> color,
  Value<String?> description,
  Value<int> customerCount,
  Value<int> chatCount,
  Value<bool> isActive,
  Value<String?> createdAt,
});

class $$LocalLabelsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalLabelsTable,
    LocalLabel,
    $$LocalLabelsTableFilterComposer,
    $$LocalLabelsTableOrderingComposer,
    $$LocalLabelsTableCreateCompanionBuilder,
    $$LocalLabelsTableUpdateCompanionBuilder> {
  $$LocalLabelsTableTableManager(_$LocalDatabase db, $LocalLabelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalLabelsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalLabelsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> customerCount = const Value.absent(),
            Value<int> chatCount = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalLabelsCompanion(
            id: id,
            name: name,
            color: color,
            description: description,
            customerCount: customerCount,
            chatCount: chatCount,
            isActive: isActive,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> color = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> customerCount = const Value.absent(),
            Value<int> chatCount = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> createdAt = const Value.absent(),
          }) =>
              LocalLabelsCompanion.insert(
            id: id,
            name: name,
            color: color,
            description: description,
            customerCount: customerCount,
            chatCount: chatCount,
            isActive: isActive,
            createdAt: createdAt,
          ),
        ));
}

class $$LocalLabelsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $LocalLabelsTable> {
  $$LocalLabelsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get customerCount => $state.composableBuilder(
      column: $state.table.customerCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get chatCount => $state.composableBuilder(
      column: $state.table.chatCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalLabelsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $LocalLabelsTable> {
  $$LocalLabelsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get customerCount => $state.composableBuilder(
      column: $state.table.customerCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get chatCount => $state.composableBuilder(
      column: $state.table.chatCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$LocalChatsTableTableManager get localChats =>
      $$LocalChatsTableTableManager(_db, _db.localChats);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalCustomersTableTableManager get localCustomers =>
      $$LocalCustomersTableTableManager(_db, _db.localCustomers);
  $$LocalOrdersTableTableManager get localOrders =>
      $$LocalOrdersTableTableManager(_db, _db.localOrders);
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalQuickRepliesTableTableManager get localQuickReplies =>
      $$LocalQuickRepliesTableTableManager(_db, _db.localQuickReplies);
  $$LocalLabelsTableTableManager get localLabels =>
      $$LocalLabelsTableTableManager(_db, _db.localLabels);
}
