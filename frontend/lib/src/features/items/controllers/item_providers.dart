import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/pottery_item.dart';
import '../../../data/repositories/item_repository.dart';

final itemListProvider = FutureProvider<List<PotteryItemModel>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.fetchItems();
});

final itemDetailProvider =
    FutureProvider.family<PotteryItemModel, String>((ref, itemId) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.fetchItem(itemId);
});
