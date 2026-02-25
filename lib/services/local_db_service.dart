import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../utils/logger.dart';
import '../models/chat.dart' as models;
import '../models/message.dart' as models;
import '../models/customer.dart' as models;
import '../models/order.dart' as models;
import '../models/product.dart' as models;
import '../models/quick_reply.dart' as models;
import '../models/label.dart' as models;
import 'dart:io';

part 'local_db_service.g.dart';

// ═══════════════════════════════════════════════════════════════
// TABLE DEFINITIONS
// ═══════════════════════════════════════════════════════════════

class LocalChats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phone => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get lastMessage => text().nullable()();
  TextColumn get lastMessageType => text().withDefault(const Constant('text'))();
  TextColumn get lastTimestamp => text().nullable()();
  TextColumn get lastDirection => text().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get totalMessages => integer().withDefault(const Constant(0))();
  TextColumn get assignedTo => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get labels => text().withDefault(const Constant('[]'))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isBotEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{phone}];
}

class LocalMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().nullable()();
  TextColumn get phone => text()();
  TextColumn get msgText => text().nullable()();
  TextColumn get messageType => text().withDefault(const Constant('text'))();
  TextColumn get direction => text()();
  TextColumn get mediaId => text().nullable()();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaMime => text().nullable()();
  TextColumn get mediaCaption => text().nullable()();
  TextColumn get buttonId => text().nullable()();
  TextColumn get buttonText => text().nullable()();
  TextColumn get buttons => text().nullable()();
  TextColumn get contextMessageId => text().nullable()();
  BoolColumn get isForwarded => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('sent'))();
  BoolColumn get isAutoReply => boolean().withDefault(const Constant(false))();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  TextColumn get templateName => text().nullable()();
  TextColumn get timestamp => text()();
  TextColumn get deliveredAt => text().nullable()();
  TextColumn get readAt => text().nullable()();
  TextColumn get createdAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{messageId}];
}

class LocalCustomers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phone => text()();
  TextColumn get name => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get pincode => text().nullable()();
  TextColumn get segment => text().withDefault(const Constant('new'))();
  TextColumn get tier => text().withDefault(const Constant('bronze'))();
  TextColumn get labels => text().withDefault(const Constant('[]'))();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  IntColumn get orderCount => integer().withDefault(const Constant(0))();
  RealColumn get totalSpent => real().withDefault(const Constant(0))();
  TextColumn get language => text().withDefault(const Constant('en'))();
  BoolColumn get optedIn => boolean().withDefault(const Constant(true))();
  TextColumn get firstSeen => text().nullable()();
  TextColumn get lastSeen => text().nullable()();
  TextColumn get lastOrderAt => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{phone}];
}

class LocalOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text()();
  TextColumn get phone => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get items => text().withDefault(const Constant('[]'))();
  IntColumn get itemCount => integer().withDefault(const Constant(1))();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get shippingCost => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get courier => text().nullable()();
  TextColumn get trackingId => text().nullable()();
  TextColumn get awbNumber => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('whatsapp'))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{orderId}];
}

class LocalProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  RealColumn get comparePrice => real().nullable()();
  TextColumn get category => text().nullable()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get images => text().withDefault(const Constant('[]'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isFeatured => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{sku}];
}

class LocalQuickReplies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortcut => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get messageType => text().withDefault(const Constant('text'))();
  TextColumn get category => text().withDefault(const Constant('general'))();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{shortcut}];
}

class LocalLabels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#DBAC35'))();
  TextColumn get description => text().nullable()();
  IntColumn get customerCount => integer().withDefault(const Constant(0))();
  IntColumn get chatCount => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{name}];
}

// ═══════════════════════════════════════════════════════════════
// DATABASE CLASS
// ═══════════════════════════════════════════════════════════════

@DriftDatabase(tables: [
  LocalChats,
  LocalMessages,
  LocalCustomers,
  LocalOrders,
  LocalProducts,
  LocalQuickReplies,
  LocalLabels,
])
class LocalDatabase extends _$LocalDatabase {
  static LocalDatabase? _instance;

  LocalDatabase._() : super(_openConnection());

  static LocalDatabase get instance {
    _instance ??= LocalDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          Logger.cache('Local database created');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          Logger.cache('Database upgrade: $from → $to');
        },
      );

  // ═══════════════════════════════════════════════════════════
  // CHAT OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<LocalChat>> getAllChats() {
    return (select(localChats)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<LocalChat?> getChatByPhone(String phone) {
    return (select(localChats)..where((t) => t.phone.equals(phone)))
        .getSingleOrNull();
  }

  Future<void> upsertChat(models.Chat chat) async {
    final now = DateTime.now().toIso8601String();
    await customStatement(
      '''INSERT INTO local_chats (phone, customer_name, last_message, last_message_type,
         last_timestamp, last_direction, unread_count, total_messages, assigned_to,
         status, priority, labels, is_starred, is_blocked, is_bot_enabled, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(phone) DO UPDATE SET
         customer_name=excluded.customer_name, last_message=excluded.last_message,
         last_message_type=excluded.last_message_type, last_timestamp=excluded.last_timestamp,
         last_direction=excluded.last_direction, unread_count=excluded.unread_count,
         total_messages=excluded.total_messages, status=excluded.status,
         priority=excluded.priority, labels=excluded.labels,
         is_starred=excluded.is_starred, is_blocked=excluded.is_blocked,
         is_bot_enabled=excluded.is_bot_enabled, updated_at=excluded.updated_at''',
      [
        chat.phone, chat.customerName, chat.lastMessage, chat.lastMessageType,
        chat.lastTimestamp, chat.lastDirection, chat.unreadCount, chat.totalMessages,
        chat.assignedTo, chat.status, chat.priority, chat.labels.join(','),
        chat.isStarred ? 1 : 0, chat.isBlocked ? 1 : 0, chat.isBotEnabled ? 1 : 0,
        chat.createdAt ?? now, chat.updatedAt ?? now,
      ],
    );
  }

  Future<void> upsertChats(List<models.Chat> chats) async {
    await transaction(() async {
      for (final chat in chats) {
        await upsertChat(chat);
      }
    });
    Logger.cache('Upserted ${chats.length} chats');
  }

  Future<void> markChatRead(String phone) async {
    await customStatement(
      'UPDATE local_chats SET unread_count = 0 WHERE phone = ?',
      [phone],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<LocalMessage>> getMessages(String phone, {int limit = 50, int offset = 0}) {
    return (select(localMessages)
          ..where((t) => t.phone.equals(phone))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<void> insertMessage(models.Message msg) async {
    final now = DateTime.now().toIso8601String();
    await customStatement(
      '''INSERT INTO local_messages (message_id, phone, msg_text, message_type, direction,
         media_id, media_url, media_mime, media_caption, button_id, button_text, buttons,
         context_message_id, is_forwarded, status, is_auto_reply, is_template, template_name,
         timestamp, delivered_at, read_at, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(message_id) DO UPDATE SET
         status=excluded.status, delivered_at=excluded.delivered_at, read_at=excluded.read_at''',
      [
        msg.messageId, msg.phone, msg.text, msg.messageType, msg.direction,
        msg.mediaId, msg.mediaUrl, msg.mediaMime, msg.mediaCaption,
        msg.buttonId, msg.buttonText, msg.buttons?.toString(),
        msg.contextMessageId, msg.isForwarded ? 1 : 0, msg.status,
        msg.isAutoReply ? 1 : 0, msg.isTemplate ? 1 : 0, msg.templateName,
        msg.timestamp, msg.deliveredAt, msg.readAt, msg.createdAt ?? now,
      ],
    );
  }

  Future<void> insertMessages(List<models.Message> messages) async {
    await transaction(() async {
      for (final msg in messages) {
        await insertMessage(msg);
      }
    });
    Logger.cache('Inserted ${messages.length} messages');
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    final now = DateTime.now().toIso8601String();
    String sql = 'UPDATE local_messages SET status = ?';
    final params = <dynamic>[status];

    if (status == 'delivered') {
      sql += ', delivered_at = ?';
      params.add(now);
    } else if (status == 'read') {
      sql += ', read_at = ?';
      params.add(now);
    }

    sql += ' WHERE message_id = ?';
    params.add(messageId);

    await customStatement(sql, params);
  }

  Future<LocalMessage?> getMessageById(String messageId) {
    return (select(localMessages)..where((t) => t.messageId.equals(messageId)))
        .getSingleOrNull();
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOMER OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<LocalCustomer?> getCustomerByPhone(String phone) {
    return (select(localCustomers)..where((t) => t.phone.equals(phone)))
        .getSingleOrNull();
  }

  Future<void> upsertCustomer(models.Customer customer) async {
    final now = DateTime.now().toIso8601String();
    await customStatement(
      '''INSERT INTO local_customers (phone, name, email, address, city, state, pincode,
         segment, tier, labels, message_count, order_count, total_spent, language,
         opted_in, first_seen, last_seen, last_order_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(phone) DO UPDATE SET
         name=excluded.name, email=excluded.email, address=excluded.address,
         city=excluded.city, state=excluded.state, pincode=excluded.pincode,
         segment=excluded.segment, tier=excluded.tier, labels=excluded.labels,
         message_count=excluded.message_count, order_count=excluded.order_count,
         total_spent=excluded.total_spent, last_seen=excluded.last_seen,
         updated_at=excluded.updated_at''',
      [
        customer.phone, customer.name, customer.email, customer.address,
        customer.city, customer.state, customer.pincode,
        customer.segment, customer.tier, customer.labels.join(','),
        customer.messageCount, customer.orderCount, customer.totalSpent,
        customer.language, customer.optedIn ? 1 : 0,
        customer.firstSeen, customer.lastSeen, customer.lastOrderAt,
        customer.createdAt ?? now, customer.updatedAt ?? now,
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ORDER OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<LocalOrder>> getAllOrders() {
    return (select(localOrders)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> upsertOrders(List<models.Order> orders) async {
    await transaction(() async {
      for (final order in orders) {
        final now = DateTime.now().toIso8601String();
        await customStatement(
          '''INSERT INTO local_orders (order_id, phone, customer_name, items, item_count,
             subtotal, discount, shipping_cost, tax, total, status, payment_status,
             payment_method, courier, tracking_id, awb_number, source, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(order_id) DO UPDATE SET
             status=excluded.status, payment_status=excluded.payment_status,
             courier=excluded.courier, tracking_id=excluded.tracking_id,
             awb_number=excluded.awb_number, updated_at=excluded.updated_at''',
          [
            order.orderId, order.phone, order.customerName, order.items.toString(),
            order.itemCount, order.subtotal, order.discount, order.shippingCost,
            order.tax, order.total, order.status, order.paymentStatus,
            order.paymentMethod, order.courier, order.trackingId,
            order.awbNumber, order.source, order.createdAt ?? now, order.updatedAt ?? now,
          ],
        );
      }
    });
    Logger.cache('Upserted ${orders.length} orders');
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await customStatement(
      'UPDATE local_orders SET status = ?, updated_at = ? WHERE order_id = ?',
      [status, DateTime.now().toIso8601String(), orderId],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PRODUCT OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<LocalProduct>> getAllProducts() {
    return (select(localProducts)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> upsertProducts(List<models.Product> products) async {
    await transaction(() async {
      for (final product in products) {
        final now = DateTime.now().toIso8601String();
        await customStatement(
          '''INSERT INTO local_products (sku, name, description, price, compare_price,
             category, stock, image_url, images, is_active, is_featured, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(sku) DO UPDATE SET
             name=excluded.name, description=excluded.description, price=excluded.price,
             compare_price=excluded.compare_price, category=excluded.category,
             stock=excluded.stock, image_url=excluded.image_url,
             is_active=excluded.is_active, updated_at=excluded.updated_at''',
          [
            product.sku, product.name, product.description, product.price,
            product.comparePrice, product.category, product.stock,
            product.imageUrl, product.images.join(','),
            product.isActive ? 1 : 0, product.isFeatured ? 1 : 0,
            product.createdAt ?? now, product.updatedAt ?? now,
          ],
        );
      }
    });
    Logger.cache('Upserted ${products.length} products');
  }

  // ═══════════════════════════════════════════════════════════
  // QUICK REPLY OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<LocalQuickReply>> getAllQuickReplies() {
    return (select(localQuickReplies)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.useCount)]))
        .get();
  }

  Future<void> upsertQuickReplies(List<models.QuickReply> replies) async {
    await transaction(() async {
      for (final reply in replies) {
        await customStatement(
          '''INSERT INTO local_quick_replies (shortcut, title, message, message_type,
             category, use_count, is_active, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(shortcut) DO UPDATE SET
             title=excluded.title, message=excluded.message,
             message_type=excluded.message_type, category=excluded.category,
             use_count=excluded.use_count, is_active=excluded.is_active''',
          [
            reply.shortcut, reply.title, reply.message, reply.messageType,
            reply.category, reply.useCount, reply.isActive ? 1 : 0,
            reply.createdAt ?? DateTime.now().toIso8601String(),
          ],
        );
      }
    });
    Logger.cache('Upserted ${replies.length} quick replies');
  }

  // ═══════════════════════════════════════════════════════════
  // LABEL OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<LocalLabel>> getAllLabels() {
    return (select(localLabels)..where((t) => t.isActive.equals(true))).get();
  }

  Future<void> upsertLabels(List<models.Label> labelList) async {
    await transaction(() async {
      for (final label in labelList) {
        await customStatement(
          '''INSERT INTO local_labels (name, color, description, customer_count,
             chat_count, is_active, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(name) DO UPDATE SET
             color=excluded.color, description=excluded.description,
             customer_count=excluded.customer_count, chat_count=excluded.chat_count,
             is_active=excluded.is_active''',
          [
            label.name, label.color, label.description,
            label.customerCount, label.chatCount,
            label.isActive ? 1 : 0, label.createdAt ?? DateTime.now().toIso8601String(),
          ],
        );
      }
    });
    Logger.cache('Upserted ${labelList.length} labels');
  }

  // ═══════════════════════════════════════════════════════════
  // CLEAR ALL
  // ═══════════════════════════════════════════════════════════

  Future<void> clearAll() async {
    await customStatement('DELETE FROM local_messages');
    await customStatement('DELETE FROM local_chats');
    await customStatement('DELETE FROM local_customers');
    await customStatement('DELETE FROM local_orders');
    await customStatement('DELETE FROM local_products');
    await customStatement('DELETE FROM local_quick_replies');
    await customStatement('DELETE FROM local_labels');
    Logger.cache('All local data cleared');
  }

  // ═══════════════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════════════

  Future<int> getChatCount() async {
    final count = await customSelect('SELECT COUNT(*) AS c FROM local_chats').getSingle();
    return count.read<int>('c');
  }

  Future<int> getMessageCount() async {
    final count = await customSelect('SELECT COUNT(*) AS c FROM local_messages').getSingle();
    return count.read<int>('c');
  }

  Future<int> getUnreadTotal() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(unread_count), 0) AS total FROM local_chats',
    ).getSingle();
    return result.read<int>('total');
  }
}

// ═══════════════════════════════════════════════════════════════
// DATABASE CONNECTION
// ═══════════════════════════════════════════════════════════════

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'kaapav.db'));
    Logger.cache('Database path: ${file.path}');
    return NativeDatabase.createInBackground(file);
  });
}