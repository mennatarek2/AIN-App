import 'package:ain_graduation_project/core/network/api_client.dart';
import 'package:ain_graduation_project/core/network/api_endpoints.dart';
import 'package:ain_graduation_project/features/home/domain/category_model.dart';

class CategoriesRemoteDataSource {
  const CategoriesRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _client.getJson(ApiEndpoints.categories);
    return _parseList(response);
  }

  List<CategoryModel> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map(
            (item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((c) => c.id.isNotEmpty)
          .toList();
    }

    if (response is Map) {
      final candidate =
          response['data'] ?? response['items'] ?? response['result'];
      if (candidate is List) return _parseList(candidate);
    }

    return const [];
  }
}
