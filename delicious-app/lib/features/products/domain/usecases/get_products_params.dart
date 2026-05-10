import 'package:equatable/equatable.dart';

class GetProductsParams extends Equatable {
  final String? categoryId;
  final String? mood;
  final String? searchQuery;
  final int page;
  final int limit;

  const GetProductsParams({
    this.categoryId,
    this.mood,
    this.searchQuery,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [categoryId, mood, searchQuery, page, limit];
}