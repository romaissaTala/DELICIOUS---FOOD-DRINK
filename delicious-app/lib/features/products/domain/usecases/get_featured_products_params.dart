import 'package:equatable/equatable.dart';

class GetFeaturedProductsParams extends Equatable {
  final int limit;
  
  const GetFeaturedProductsParams({this.limit = 10});
  
  @override
  List<Object> get props => [limit];
}
