import 'package:dio/dio.dart';
import 'api_client.dart';

class TemplateApi {
  final ApiClient _api = ApiClient.instance;

  // Quick Replies
  Future<Response> getQuickReplies() {
    return _api.get('/api/quick-replies');
  }

  Future<Response> createQuickReply(Map<String, dynamic> data) {
    return _api.post('/api/quick-replies', data: data);
  }

  Future<Response> updateQuickReply(int id, Map<String, dynamic> data) {
    return _api.patch('/api/quick-replies/$id', data: data);
  }

  Future<Response> deleteQuickReply(int id) {
    return _api.delete('/api/quick-replies/$id');
  }

  // Templates
  Future<Response> getTemplates() {
    return _api.get('/api/templates');
  }

  Future<Response> createTemplate(Map<String, dynamic> data) {
    return _api.post('/api/templates', data: data);
  }

  // Labels
  Future<Response> getLabels() {
    return _api.get('/api/labels');
  }

  Future<Response> createLabel(Map<String, dynamic> data) {
    return _api.post('/api/labels', data: data);
  }

  Future<Response> deleteLabel(int id) {
    return _api.delete('/api/labels/$id');
  }
}