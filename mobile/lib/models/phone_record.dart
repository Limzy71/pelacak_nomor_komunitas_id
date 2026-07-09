class TagItem {
  final String id;
  final String phoneNumberId;
  final String labelName;
  final String? userId;
  final bool isSpam;
  int upvotes;
  int downvotes;
  final DateTime? createdAt;

  TagItem({
    required this.id,
    required this.phoneNumberId,
    required this.labelName,
    this.userId,
    this.isSpam = false,
    this.upvotes = 0,
    this.downvotes = 0,
    this.createdAt,
  });

  factory TagItem.fromJson(Map<String, dynamic> json) {
    return TagItem(
      id: json['id']?.toString() ?? '',
      phoneNumberId: json['phoneNumberId']?.toString() ?? '',
      labelName: json['labelName']?.toString() ?? 'Unknown Tag',
      userId: json['userId']?.toString(),
      isSpam: json['isSpam'] == true,
      upvotes: json['upvotes'] is int
          ? json['upvotes']
          : int.tryParse(json['upvotes']?.toString() ?? '0') ?? 0,
      downvotes: json['downvotes'] is int
          ? json['downvotes']
          : int.tryParse(json['downvotes']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class PhoneRecord {
  final String id;
  final String phoneNumber;
  final String countryCode;
  final int searchCount;
  final double trustScore;
  final List<TagItem> tags;

  PhoneRecord({
    required this.id,
    required this.phoneNumber,
    required this.countryCode,
    required this.searchCount,
    required this.trustScore,
    required this.tags,
  });

  factory PhoneRecord.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? [];
    return PhoneRecord(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? 'ID',
      searchCount: json['searchCount'] is int
          ? json['searchCount']
          : int.tryParse(json['searchCount']?.toString() ?? '1') ?? 1,
      trustScore: json['trustScore'] is num
          ? (json['trustScore'] as num).toDouble()
          : double.tryParse(json['trustScore']?.toString() ?? '80.0') ?? 80.0,
      tags: rawTags
          .map((t) => TagItem.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LookupResponse {
  final bool found;
  final String phoneNumber;
  final String message;
  final PhoneRecord? data;

  LookupResponse({
    required this.found,
    required this.phoneNumber,
    required this.message,
    this.data,
  });

  factory LookupResponse.fromJson(Map<String, dynamic> json) {
    return LookupResponse(
      found: json['found'] == true,
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? PhoneRecord.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SyncContactResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncContactResult({
    required this.success,
    required this.message,
    required this.syncedCount,
  });

  factory SyncContactResult.fromJson(Map<String, dynamic> json) {
    return SyncContactResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      syncedCount: json['syncedCount'] is int
          ? json['syncedCount']
          : int.tryParse(json['syncedCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class AnalyticsResponse {
  final int totalNumbers;
  final int totalTags;
  final List<PhoneRecord> topSearchedNumbers;

  AnalyticsResponse({
    required this.totalNumbers,
    required this.totalTags,
    required this.topSearchedNumbers,
  });

  factory AnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final rawTop = json['topSearchedNumbers'] as List<dynamic>? ?? [];
    return AnalyticsResponse(
      totalNumbers: json['totalNumbers'] is int
          ? json['totalNumbers']
          : int.tryParse(json['totalNumbers']?.toString() ?? '0') ?? 0,
      totalTags: json['totalTags'] is int
          ? json['totalTags']
          : int.tryParse(json['totalTags']?.toString() ?? '0') ?? 0,
      topSearchedNumbers: rawTop
          .map((item) => PhoneRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
