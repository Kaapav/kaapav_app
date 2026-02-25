import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_reply.dart';
import '../models/label.dart';
import '../models/template.dart';
import '../services/api/settings_api.dart';
import '../services/api/template_api.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

class SettingsState {
  final Map<String, dynamic> settings;
  final List<QuickReply> quickReplies;
  final List<Label> labels;
  final List<Template> templates;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.settings = const {},
    this.quickReplies = const [],
    this.labels = const [],
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    Map<String, dynamic>? settings,
    List<QuickReply>? quickReplies,
    List<Label>? labels,
    List<Template>? templates,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      quickReplies: quickReplies ?? this.quickReplies,
      labels: labels ?? this.labels,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Convenience getters
  String get businessName =>
      settings['business_name'] as String? ?? 'KAAPAV';
  String get businessPhone =>
      settings['business_phone'] as String? ?? '';
  String get businessEmail =>
      settings['business_email'] as String? ?? '';
  bool get autoReplyEnabled =>
      settings['ai_auto_reply'] == 'true' ||
      settings['ai_auto_reply'] == true;

  List<QuickReply> get activeQuickReplies =>
      quickReplies.where((q) => q.isActive).toList();

  List<Label> get activeLabels =>
      labels.where((l) => l.isActive).toList();

  List<Template> get approvedTemplates =>
      templates.where((t) => t.isApproved).toList();
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsApi _settingsApi = SettingsApi();
  final TemplateApi _templateApi = TemplateApi();

  SettingsNotifier() : super(const SettingsState());

  // ── Load all (mirrors setQuickReplies, setTemplates, setLabels) ──
 Future<void> loadAll() async {
  if (state.isLoading) return;

  state = state.copyWith(isLoading: true, clearError: true);

  try {
    // Fetch settings (this endpoint exists)
    Map<String, dynamic> settings = {};
    try {
      final settingsRes = await _settingsApi.get();
      final settingsData = settingsRes.data;
      settings = settingsData is Map<String, dynamic>
          ? settingsData
          : <String, dynamic>{};
    } catch (e) {
      // Settings endpoint failed - continue with defaults
      debugPrint('Settings load warning: $e');
    }

    // Fetch quick replies (endpoint may not exist)
    List<QuickReply> quickReplies = [];
    try {
      final qrRes = await _templateApi.getQuickReplies();
      final qrRaw = qrRes.data;
      final List<dynamic> qrList =
          qrRaw is List ? qrRaw : (qrRaw['quick_replies'] ?? qrRaw['data'] ?? []);
      quickReplies = qrList.map((j) => QuickReply.fromJson(j)).toList();
    } catch (e) {
      // Quick replies endpoint doesn't exist - ignore
      debugPrint('Quick replies not available: $e');
    }

    // Fetch labels (endpoint may not exist)
    List<Label> labels = [];
    try {
      final labelRes = await _templateApi.getLabels();
      final labelRaw = labelRes.data;
      final List<dynamic> labelList =
          labelRaw is List ? labelRaw : (labelRaw['labels'] ?? labelRaw['data'] ?? []);
      labels = labelList.map((j) => Label.fromJson(j)).toList();
    } catch (e) {
      // Labels endpoint doesn't exist - ignore
      debugPrint('Labels not available: $e');
    }

    // Fetch templates (endpoint may not exist)
    List<Template> templates = [];
    try {
      final tplRes = await _templateApi.getTemplates();
      final tplRaw = tplRes.data;
      final List<dynamic> tplList =
          tplRaw is List ? tplRaw : (tplRaw['templates'] ?? tplRaw['data'] ?? []);
      templates = tplList.map((j) => Template.fromJson(j)).toList();
    } catch (e) {
      // Templates endpoint doesn't exist - ignore
      debugPrint('Templates not available: $e');
    }

    state = state.copyWith(
      settings: settings,
      quickReplies: quickReplies,
      labels: labels,
      templates: templates,
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}

  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      await _settingsApi.update(newSettings);
      final merged = {...state.settings, ...newSettings};
      state = state.copyWith(settings: merged);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Quick Replies (mirrors add/update/incrementQuickReplyUse) ──
  Future<bool> createQuickReply(Map<String, dynamic> data) async {
    try {
      await _templateApi.createQuickReply(data);
      final response = await _templateApi.getQuickReplies();
      final raw = response.data;
      final List<dynamic> list =
          raw is List ? raw : (raw['quick_replies'] ?? raw['data'] ?? []);
      state = state.copyWith(
        quickReplies: list.map((j) => QuickReply.fromJson(j)).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateQuickReply(int id, Map<String, dynamic> data) async {
    try {
      await _templateApi.updateQuickReply(id, data);
      final response = await _templateApi.getQuickReplies();
      final raw = response.data;
      final List<dynamic> list =
          raw is List ? raw : (raw['quick_replies'] ?? raw['data'] ?? []);
      state = state.copyWith(
        quickReplies: list.map((j) => QuickReply.fromJson(j)).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteQuickReply(int id) async {
    try {
      await _templateApi.deleteQuickReply(id);
      final updated = state.quickReplies.where((q) => q.id != id).toList();
      state = state.copyWith(quickReplies: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mirrors incrementQuickReplyUse (by shortcut)
  void incrementQuickReplyUse(String shortcut) {
    final updated = state.quickReplies.map((q) {
      if (q.shortcut == shortcut) {
        return q.copyWith(useCount: q.useCount + 1);
      }
      return q;
    }).toList();
    state = state.copyWith(quickReplies: updated);
  }

  // ── Labels ──
  Future<bool> createLabel(Map<String, dynamic> data) async {
    try {
      await _templateApi.createLabel(data);
      final response = await _templateApi.getLabels();
      final raw = response.data;
      final List<dynamic> list =
          raw is List ? raw : (raw['labels'] ?? raw['data'] ?? []);
      state = state.copyWith(
        labels: list.map((j) => Label.fromJson(j)).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLabel(int id) async {
    try {
      await _templateApi.deleteLabel(id);
      final updated = state.labels.where((l) => l.id != id).toList();
      state = state.copyWith(labels: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Templates ──
  Future<bool> createTemplate(Map<String, dynamic> data) async {
    try {
      await _templateApi.createTemplate(data);
      final response = await _templateApi.getTemplates();
      final raw = response.data;
      final List<dynamic> list =
          raw is List ? raw : (raw['templates'] ?? raw['data'] ?? []);
      state = state.copyWith(
        templates: list.map((j) => Template.fromJson(j)).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Test WhatsApp ──
  Future<bool> testWhatsApp(String phone) async {
    try {
      await _settingsApi.testWhatsApp(phone);
      return true;
    } catch (e) {
      return false;
    }
  }
}