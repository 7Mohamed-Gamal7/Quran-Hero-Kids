class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    this.ageBand,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? ageBand;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;

    return ChildProfile(
      id: (json['id'] ?? json['Id']).toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      ageBand: (json['ageBand'] ?? json['AgeBand'])?.toString(),
      isArchived: (json['isArchived'] ?? json['IsArchived'] ?? false) == true,
      createdAt: parseDate(json['createdAt'] ?? json['CreatedAt']),
      updatedAt: parseDate(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }
}

class ChildProfileDraft {
  const ChildProfileDraft({required this.name, this.ageBand});

  final String name;
  final String? ageBand;

  Map<String, Object?> toJson() => {
        'name': name.trim(),
        if (ageBand != null) 'ageBand': ageBand,
      };
}
