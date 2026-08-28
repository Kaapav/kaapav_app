import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coupon.dart';
import '../services/api/coupon_api.dart';

class CouponState {
  final List<Coupon> coupons;
  final bool isLoading;
  final String? error;

  const CouponState({
    this.coupons = const [],
    this.isLoading = false,
    this.error,
  });

  CouponState copyWith({
    List<Coupon>? coupons,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CouponState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final couponProvider =
    StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier();
});

class CouponNotifier extends StateNotifier<CouponState> {
  final CouponApi _api = CouponApi();

  CouponNotifier() : super(const CouponState());

  Future<void> loadCoupons() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await _api.getCoupons();
      final body = response.data;

      final dynamic raw = body is Map
          ? (body['coupons'] ?? body['data'] ?? [])
          : [];

      final coupons = (raw as List)
          .whereType<Map>()
          .map(
            (item) => Coupon.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      state = state.copyWith(
        coupons: coupons,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createCoupon(Coupon coupon) async {
    try {
      final response = await _api.createCoupon(coupon.toJson());
      final body = response.data;

      if (body is Map && body['success'] != true) {
        state = state.copyWith(
          error: body['error']?.toString() ??
              'Failed to create offer',
        );
        return false;
      }

      await loadCoupons();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCoupon(Coupon coupon) async {
    if (coupon.id == null) return false;

    try {
      final response = await _api.updateCoupon(
        coupon.id!,
        coupon.toJson(),
      );

      final body = response.data;

      if (body is Map && body['success'] != true) {
        state = state.copyWith(
          error: body['error']?.toString() ??
              'Failed to update offer',
        );
        return false;
      }

      await loadCoupons();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> setActive(
    Coupon coupon,
    bool active,
  ) async {
    return updateCoupon(
      coupon.copyWith(isActive: active),
    );
  }

  Future<bool> removeCoupon(Coupon coupon) async {
    if (coupon.id == null) return false;

    try {
      final response = await _api.removeCoupon(coupon.id!);
      final body = response.data;

      if (body is Map && body['success'] != true) {
        state = state.copyWith(
          error: body['error']?.toString() ??
              'Failed to remove offer',
        );
        return false;
      }

      await loadCoupons();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}