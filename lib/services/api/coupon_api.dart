import 'package:dio/dio.dart';
import 'api_client.dart';

class CouponApi {
  final ApiClient _client = ApiClient.instance;

  Future<Response> getCoupons() {
    return _client.get(
      '/api/coupons',
      useCache: false,
    );
  }

  Future<Response> createCoupon(Map<String, dynamic> data) {
    return _client.post(
      '/api/coupons',
      data: data,
    );
  }

  Future<Response> updateCoupon(
    int id,
    Map<String, dynamic> data,
  ) {
    return _client.put(
      '/api/coupons/$id',
      data: data,
    );
  }

  Future<Response> removeCoupon(int id) {
    return _client.delete('/api/coupons/$id');
  }
}
