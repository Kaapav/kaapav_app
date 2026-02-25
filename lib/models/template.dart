class Template {
  final int? id;
  final String name;
  final String? waTemplateId;
  final String waStatus;
  final String? category;
  final String? language;
  final String? headerType;
  final String? headerText;
  final String? bodyText;
  final String? footerText;
  final dynamic buttons;
  final List<String> variables;
  final int sentCount;
  final int deliveredCount;
  final int readCount;
  final String? createdAt;

  const Template({
    this.id,
    this.name = '',
    this.waTemplateId,
    this.waStatus = 'pending',
    this.category,
    this.language,
    this.headerType,
    this.headerText,
    this.bodyText,
    this.footerText,
    this.buttons,
    this.variables = const [],
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.readCount = 0,
    this.createdAt,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      waTemplateId: json['wa_template_id'] as String?,
      waStatus: json['wa_status'] as String? ?? 'pending',
      category: json['category'] as String?,
      language: json['language'] as String?,
      headerType: json['header_type'] as String?,
      headerText: json['header_text'] as String?,
      bodyText: json['body_text'] as String?,
      footerText: json['footer_text'] as String?,
      buttons: json['buttons'],
      variables: _parseStringList(json['variables']),
      sentCount: _toInt(json['sent_count']),
      deliveredCount: _toInt(json['delivered_count']),
      readCount: _toInt(json['read_count']),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'wa_template_id': waTemplateId,
        'wa_status': waStatus,
        'category': category,
        'language': language,
        'header_type': headerType,
        'header_text': headerText,
        'body_text': bodyText,
        'footer_text': footerText,
        'buttons': buttons,
        'variables': variables,
        'sent_count': sentCount,
        'delivered_count': deliveredCount,
        'read_count': readCount,
        'created_at': createdAt,
      };

  Template copyWith({
    int? id,
    String? name,
    String? waTemplateId,
    String? waStatus,
    String? category,
    String? language,
    String? headerType,
    String? headerText,
    String? bodyText,
    String? footerText,
    dynamic buttons,
    List<String>? variables,
    int? sentCount,
    int? deliveredCount,
    int? readCount,
    String? createdAt,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      waTemplateId: waTemplateId ?? this.waTemplateId,
      waStatus: waStatus ?? this.waStatus,
      category: category ?? this.category,
      language: language ?? this.language,
      headerType: headerType ?? this.headerType,
      headerText: headerText ?? this.headerText,
      bodyText: bodyText ?? this.bodyText,
      footerText: footerText ?? this.footerText,
      buttons: buttons ?? this.buttons,
      variables: variables ?? this.variables,
      sentCount: sentCount ?? this.sentCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      readCount: readCount ?? this.readCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isApproved => waStatus == 'approved';
  bool get isPending => waStatus == 'pending';
  bool get isRejected => waStatus == 'rejected';

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static List<String> _parseStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) {
      if (val.isEmpty || val == '[]') return [];
      try {
        return val
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }
}