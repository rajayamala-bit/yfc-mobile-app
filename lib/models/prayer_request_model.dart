class PrayerRequest {
  final String id;
  final String authorName;
  final String title;
  final String description;
  final String category;
  int prayCount;
  final List<String> prayedByUsers;
  final DateTime createdAt;

  PrayerRequest({
    required this.id,
    required this.authorName,
    required this.title,
    required this.description,
    this.category = 'General',
    required this.prayCount,
    required this.prayedByUsers,
    required this.createdAt,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    return PrayerRequest(
      id: json['id'] ?? '',
      authorName: json['author_name'] ?? 'YFC Youth',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      prayCount: json['pray_count'] ?? 0,
      prayedByUsers: List<String>.from(json['prayed_by_users'] ?? []),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
