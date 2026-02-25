class AppConstants {
  AppConstants._();

  // ═══════════════════════ API ═══════════════════════
  static const String baseUrl = 'https://wa.kaapav.com';
  static const String apiBaseUrl = 'https://wa.kaapav.com'; // alias
  static const String apiPrefix = '/api';

  // ═══════════════════════ WEBSOCKET ═══════════════════════
  static const String wsUrl = 'wss://wa.kaapav.com/ws';
  static const String wsNewMessage = 'new_message';
  static const String wsMessageStatus = 'message_status';
  static const String wsChatUpdate = 'chat_update';
  static const String wsOrderUpdate = 'order_update';
  static const String wsTyping = 'typing';
  static const String wsOnline = 'online';
  static const String wsPing = 'ping';
  static const String wsPong = 'pong';

  // ═══════════════════════ STORAGE KEYS ═══════════════════════
  static const String authTokenKey = 'auth_token';
  static const String tokenKey = 'auth_token'; // alias
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String pinKey = 'user_pin';
  static const String pinHashKey = 'pin_hash';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String fcmTokenKey = 'fcm_token';
  static const String userKey = 'user_data';
  static const String userDataKey = 'user_data'; // alias
  static const String lastSyncKey = 'last_sync';
  static const String firstLaunchKey = 'first_launch';

  // ═══════════════════════ MEDIA LIMITS ═══════════════════════
  static const int maxImageSize = 5 * 1024 * 1024;
  static const int maxDocSize = 16 * 1024 * 1024;
  static const int maxVideoSize = 16 * 1024 * 1024;
  static const int maxVoiceSize = 16 * 1024 * 1024;

  // ═══════════════════════ TIMEOUTS ═══════════════════════
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 120);
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  static const Duration wsMaxReconnectDelay = Duration(seconds: 60);
  static const Duration wsPingInterval = Duration(seconds: 30);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);

  // ═══════════════════════ PAGINATION ═══════════════════════
  static const int defaultPageSize = 50;
  static const int chatPageSize = 50;
  static const int messagePageSize = 50;
  static const int orderPageSize = 100;
  static const int productPageSize = 50;

  // ═══════════════════════ CIRCUIT BREAKER ═══════════════════════
  static const int circuitBreakerThreshold = 5;
  static const Duration circuitBreakerTimeout = Duration(seconds: 60);
  static const int maxRetries = 3;
  static const int maxConcurrentRequests = 6;

  // ═══════════════════════ CACHE ═══════════════════════
  static const Duration defaultCacheTTL = Duration(minutes: 5);
  static const Duration cacheTTL = Duration(minutes: 5); // alias
  static const Duration chatCacheTTL = Duration(minutes: 2);
  static const Duration productCacheTTL = Duration(minutes: 10);

  // ═══════════════════════ RETRY ═══════════════════════
  static const Duration retryMaxDelay = Duration(seconds: 30);

  // ═══════════════════════ APP INFO ═══════════════════════
  static const String appName = 'KAAPAV';
  static const String appVersion = '1.0.0';
  static const String businessPhone = '919148330016';
  static const String businessName = 'KAAPAV Fashion Jewellery';
  static const String websiteUrl = 'https://www.kaapav.com';
  static const String catalogUrl = 'https://wa.me/c/919148330016';
  static const String wameChatUrl = 'https://wa.me/919148330016';

  // ═══════════════════════ NOTIFICATION CHANNELS ═══════════════════════
  static const String messageChannelId = 'kaapav_messages';
  static const String messageChannelName = 'Messages';
  static const String orderChannelId = 'kaapav_orders';
  static const String orderChannelName = 'Orders';
  static const String generalChannelId = 'kaapav_general';
  static const String generalChannelName = 'General';
}

// ═══════════════════════════════════════════════
// API ENDPOINTS
// ═══════════════════════════════════════════════
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String refresh = '/api/auth/refresh';
  static const String refreshToken = '/api/auth/refresh'; // alias
  static const String changePassword = '/api/auth/change-password';
  static const String biometricChallenge = '/api/auth/biometric/challenge';
  static const String biometricVerify = '/api/auth/biometric/verify';
  static const String biometricRegister = '/api/auth/biometric/register';

  // Chats
  static const String chats = '/api/chats';
  static String chat(String phone) => '/api/chats/$phone';
  static String chatRead(String phone) => '/api/chats/$phone/read';
  static String chatMarkRead(String phone) => '/api/chats/$phone/read'; // alias
  static String chatStar(String phone) => '/api/chats/$phone/star';
  static String chatBlock(String phone) => '/api/chats/$phone/block';
  static String chatLabels(String phone) => '/api/chats/$phone/labels';
  static String chatLabelRemove(String phone, String label) =>
      '/api/chats/$phone/labels/$label';
  static const String chatStats = '/api/chats/stats';

  // Messages
  static String messages(String phone) => '/api/chats/$phone/messages';
  static const String sendMessage = '/api/messages/send';
  static const String sendTemplate = '/api/messages/send-template';
  static const String sendProduct = '/api/messages/send-product';
  static const String sendOrderUpdate = '/api/messages/send-order-update';
  static const String bulkSend = '/api/messages/bulk-send';
  static const String markRead = '/api/messages/mark-read';

  // Customers
  static const String customers = '/api/customers';
  static String customer(String phone) => '/api/customers/$phone';
  static String customerNotes(String phone) => '/api/customers/$phone/notes';

  // Orders
  static const String orders = '/api/orders';
  static String order(String orderId) => '/api/orders/$orderId';
  static String orderStatus(String orderId) => '/api/orders/$orderId/status';
  static String orderConfirm(String orderId) => '/api/orders/$orderId/confirm';
  static String orderCancel(String orderId) => '/api/orders/$orderId/cancel';
  static String orderPaymentLink(String orderId) =>
      '/api/orders/$orderId/payment-link';
  static String orderShip(String orderId) => '/api/orders/$orderId/ship';
  static String orderTracking(String orderId) =>
      '/api/orders/$orderId/tracking';
  static String orderNotes(String orderId) => '/api/orders/$orderId/notes';
  static const String orderStats = '/api/orders/stats';

  // Products
  static const String products = '/api/products';
  static String product(String sku) => '/api/products/$sku';
  static String productStock(String sku) => '/api/products/$sku/stock';
  static const String productCategories = '/api/products/categories';
  static const String productSearch = '/api/products/search';

  // Broadcasts
  static const String broadcasts = '/api/broadcasts';
  static String broadcast(String id) => '/api/broadcasts/$id';
  static String broadcastStart(String id) => '/api/broadcasts/$id/start';
  static String broadcastCancel(String id) => '/api/broadcasts/$id/cancel';
  static String broadcastRecipients(String id) =>
      '/api/broadcasts/$id/recipients';

  // Payments
  static const String createPaymentLink = '/api/payments/create-link';
  static String payment(String paymentId) => '/api/payments/$paymentId';
  static String paymentRefund(String paymentId) =>
      '/api/payments/$paymentId/refund';

  // Shipping
  static String shippingServiceability(String pincode) =>
      '/api/shipping/serviceability/$pincode';
  static const String shippingCreate = '/api/shipping/create';
  static String shippingTrack(String awb) => '/api/shipping/track/$awb';
  static String shippingLabel(String shipmentId) =>
      '/api/shipping/label/$shipmentId';
  static String shippingCancel(String shipmentId) =>
      '/api/shipping/cancel/$shipmentId';

  // Settings
  static const String settings = '/api/settings';
  static const String testWhatsapp = '/api/settings/test-whatsapp';

  // Templates & Quick Replies & Labels
  static const String quickReplies = '/api/quick-replies';
  static String quickReply(String id) => '/api/quick-replies/$id';
  static const String templates = '/api/templates';
  static const String labels = '/api/labels';
  static String label(String id) => '/api/labels/$id';

  // Dashboard & Analytics
  static const String stats = '/api/stats';
  static const String analytics = '/api/analytics';
  static const String activities = '/api/analytics/activities';
  static const String pending = '/api/analytics/pending';

  // Push
  static const String pushSubscribe = '/api/push/subscribe';
  static const String pushUnsubscribe = '/api/push/unsubscribe';
  static const String pushTest = '/api/push/test';

  // Media
  static const String mediaUpload = '/api/media/upload';

  // Sync
  static const String syncCheck = '/api/sync/check';
  
 }

 class AppVersion {
  static const String version = '1.0.0';
  static const int buildNumber = 2; // INCREMENT this every build
  static const String buildId = '${version}+${buildNumber}';
}