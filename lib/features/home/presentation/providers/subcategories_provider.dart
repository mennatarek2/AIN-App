import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../data/subcategories_remote_data_source.dart';
import '../../domain/category_model.dart';

final subcategoriesDataSourceProvider =
    Provider<SubcategoriesRemoteDataSource>((ref) {
      return SubcategoriesRemoteDataSource(ref.watch(apiClientProvider));
    });

/// Fetches subcategories for the given [categoryId].
/// Automatically re-fetches if the categoryId changes.
/// Cached per unique categoryId for the session.
final subcategoriesProvider =
    FutureProvider.family<List<SubCategoryModel>, String>((
      ref,
      categoryId,
    ) async {
      if (categoryId.isEmpty) return const [];
      final ds = ref.watch(subcategoriesDataSourceProvider);
      return ds.fetchByCategory(categoryId);
    });
