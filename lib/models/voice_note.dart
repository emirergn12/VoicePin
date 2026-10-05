class VoiceNote {
  int? id;
  String title;
  double latitude;
  double longitude;
  String audioPath;
  String category;
  double radius; // metre cinsinden
  DateTime createdAt;
  bool isActive;

  VoiceNote({
    this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.audioPath,
    required this.category,
    this.radius = 100.0,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  // Database'den Map'e çevirme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
      'audioPath': audioPath,
      'category': category,
      'radius': radius,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  // Map'ten VoiceNote'a çevirme
  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    return VoiceNote(
      id: map['id'],
      title: map['title'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      audioPath: map['audioPath'],
      category: map['category'],
      radius: map['radius'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }

  // JSON serialize
  Map<String, dynamic> toJson() => toMap();

  // JSON deserialize
  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote.fromMap(json);

  // Copy with (güncelleme için)
  VoiceNote copyWith({
    int? id,
    String? title,
    double? latitude,
    double? longitude,
    String? audioPath,
    String? category,
    double? radius,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      audioPath: audioPath ?? this.audioPath,
      category: category ?? this.category,
      radius: radius ?? this.radius,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'VoiceNote{id: $id, title: $title, category: $category, lat: $latitude, lng: $longitude}';
  }
}