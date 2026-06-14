/// Domain model for a report category returned by `GET /api/categories`.
class SubCategoryModel {
  const SubCategoryModel({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.subCategories = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final List<SubCategoryModel> subCategories;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subCategories'] ?? json['specializations'];
    final subs = rawSubs is List
        ? rawSubs
              .whereType<Map>()
              .map(
                (s) => SubCategoryModel.fromJson(
                  Map<String, dynamic>.from(s),
                ),
              )
              .where((s) => s.id.isNotEmpty)
              .toList()
        : <SubCategoryModel>[];

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      iconName: json['iconName']?.toString(),
      subCategories: subs,
    );
  }
}
