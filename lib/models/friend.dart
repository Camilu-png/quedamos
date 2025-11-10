class Friend {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? localPhotoPath;
  final DateTime addedAt;
  final bool isSynced;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.localPhotoPath,
    required this.addedAt,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'localPhotoPath': localPhotoPath,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      localPhotoPath: map['localPhotoPath'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  factory Friend.fromFirestore(Map<String, dynamic> data) {
    return Friend(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      photoUrl: data['photoUrl'] as String?,
      addedAt: data['addedAt'] != null
          ? (data['addedAt'] as dynamic).toDate()
          : DateTime.now(),
      isSynced: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'addedAt': addedAt,
    };
  }

  Friend copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? localPhotoPath,
    DateTime? addedAt,
    bool? isSynced,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      addedAt: addedAt ?? this.addedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
