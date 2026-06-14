import 'package:ain_graduation_project/core/network/api_client.dart';
import 'package:ain_graduation_project/core/network/api_endpoints.dart';
import 'package:ain_graduation_project/features/home/domain/category_model.dart';

/// Fetches subcategories for a given category ID from
/// `GET /api/subcategories/by-category?categoryId={id}`.
class SubcategoriesRemoteDataSource {
  const SubcategoriesRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<SubCategoryModel>> fetchByCategory(String categoryId) async {
    final response = await _client.getJson(
      ApiEndpoints.subcategoriesByCategory(categoryId),
    );
    return _parseList(response);
  }

  List<SubCategoryModel> _parseList(dynamic response) {
    List<dynamic>? list;
    if (response is List) {
      list = response;
    } else if (response is Map) {
      final candidate =
          response['data'] ?? response['items'] ?? response['result'];
      if (candidate is List) list = candidate;
    }
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map(
          (item) =>
              SubCategoryModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((s) => s.id.isNotEmpty)
        .toList();
  }
}
