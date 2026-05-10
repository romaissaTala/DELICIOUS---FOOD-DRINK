import 'package:equatable/equatable.dart';

class GetProductsByMoodParams extends Equatable {
  final List<String> moods;
  
  const GetProductsByMoodParams(this.moods);
  
  @override
  List<Object> get props => [moods];
}