import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/chats/chats_screen.dart';
import '../screens/chats/chat_window_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/broadcasts/broadcasts_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String chats = '/chats';
  static const String chatWindow = '/chat-window';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String customers = '/customers';
  static const String broadcasts = '/broadcasts';
  static const String analytics = '/analytics';
  static const String settings = '/settings';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>? ?? {};

    switch (routeSettings.name) {
      case splash:
        return _page(const SplashScreen(), routeSettings);
      case login:
        return _page(const LoginScreen(), routeSettings);
      case home:
        return _page(const HomeScreen(), routeSettings);
      case dashboard:
        return _page(const DashboardScreen(), routeSettings);
      case chats:
        return _page(const ChatsScreen(), routeSettings);
      case chatWindow:
        return _page(
          ChatWindowScreen(phone: args['phone'] as String? ?? ''),
          routeSettings,
        );
      case orders:
        return _page(const OrdersScreen(), routeSettings);
      case orderDetail:
        return _page(
          OrderDetailScreen(orderId: args['orderId'] as String? ?? ''),
          routeSettings,
        );
      case products:
        return _page(const ProductsScreen(), routeSettings);
      case productDetail:
        return _page(
          ProductDetailScreen(sku: args['sku'] as String? ?? ''),
          routeSettings,
        );
      case customers:
        return _page(const CustomersScreen(), routeSettings);
      case broadcasts:
        return _page(const BroadcastsScreen(), routeSettings);
      case analytics:
        return _page(const AnalyticsScreen(), routeSettings);
      case settings:
        return _page(const SettingsScreen(), routeSettings);
      default:
        return _page(const SplashScreen(), routeSettings);
    }
  }

  static MaterialPageRoute _page(Widget screen, RouteSettings s) {
    return MaterialPageRoute(settings: s, builder: (_) => screen);
  }

  // ═══════ WITH CONTEXT ═══════
  static void openChat(BuildContext context, String phone, {String? name}) {
    Navigator.pushNamed(context, chatWindow,
        arguments: {'phone': phone, if (name != null) 'name': name});
  }

  static void openOrder(BuildContext context, String orderId) {
    Navigator.pushNamed(context, orderDetail,
        arguments: {'orderId': orderId});
  }

  static void openProduct(BuildContext context, String sku) {
    Navigator.pushNamed(context, productDetail, arguments: {'sku': sku});
  }

  static void pushAndClearStack(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }

  static void navigateTo(BuildContext context, String route,
      {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  static void goBack(BuildContext context) => Navigator.pop(context);

  static void replaceWith(BuildContext context, String route,
      {Object? arguments}) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  // ═══════ WITHOUT CONTEXT (from services/notifications) ═══════
  static void openChatFromService(String phone, {String? customerName}) {
    navigatorKey.currentState?.pushNamed(chatWindow, arguments: {
      'phone': phone,
      if (customerName != null) 'name': customerName,
    });
  }

  static void openOrderFromService(String orderId) {
    navigatorKey.currentState
        ?.pushNamed(orderDetail, arguments: {'orderId': orderId});
  }

  static void pushAndClearStackFromService(String route) {
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(route, (r) => false);
  }
}