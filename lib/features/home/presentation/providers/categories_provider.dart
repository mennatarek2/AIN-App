import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../data/categories_remote_data_source.dart';
import '../../domain/category_model.dart';

final categoriesDataSourceProvider =
    Provider<CategoriesRemoteDataSource>((ref) {
  return CategoriesRemoteDataSource(ref.watch(apiClientProvider));
});

/// Fetches all categories once and caches them for the session.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final dataSource = ref.watch(categoriesDataSourceProvider);
  return dataSource.fetchCategories();
});
