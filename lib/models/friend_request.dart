enum FriendRequestStatus {
  pending,
  sent,
  accepted,
  rejected;

  String toJson() => name;

  static FriendRequestStatus fromJson(String value) {
    return FriendRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

class FriendRequest {
  final String id;
  final String from;
  final String to;
  final String name;
  final String email;
  final String? photoUrl;
  final String? localPhotoPath;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final bool isSynced;

  FriendRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.name,
    required this.email,
    this.photoUrl,
    this.localPhotoPath,
    required this.status,
    required this.createdAt,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'localPhotoPath': localPhotoPath,
      'status': status.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      localPhotoPath: map['localPhotoPath'] as String?,
      status: FriendRequestStatus.fromJson(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  factory FriendRequest.fromFirestore(Map<String, dynamic> data) {
    return FriendRequest(
      id: data['id'] as String,
      from: data['from'] as String,
      to: data['to'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      photoUrl: data['photoUrl'] as String?,
      status: FriendRequestStatus.fromJson(data['status'] as String),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      isSynced: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'from': from,
      'to': to,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'status': status.toJson(),
      'createdAt': createdAt,
    };
  }

  FriendRequest copyWith({
    String? id,
    String? from,
    String? to,
    String? name,
    String? email,
    String? photoUrl,
    String? localPhotoPath,
    FriendRequestStatus? status,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
