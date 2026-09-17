class Category {
  final int? id;
  final String name;
  final String classification;
  final String? iconKey;
  final int? colorValue;
  final bool isArchived;

  const Category({
    this.id,
    required this.name,
    required this.classification,
    this.iconKey,
    this.colorValue,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'classification': classification,
      'icon_key': iconKey,
      'color_value': colorValue,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      classification: map['classification'] as String,
      iconKey: map['icon_key'] as String?,
      colorValue: map['color_value'] as int?,
      isArchived: (map['is_archived'] as int) == 1,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? classification,
    String? iconKey,
    int? colorValue,
    bool? isArchived,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      classification: classification ?? this.classification,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
