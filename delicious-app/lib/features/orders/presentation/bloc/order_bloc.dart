import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/order_models.dart';
import '../../domain/usecases/place_order_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/get_order_by_id_usecase.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final PlaceOrderUseCase placeOrder;
  final GetOrdersUseCase getOrders;
  final GetOrderByIdUseCase getOrderById;

  OrderBloc({
    required this.placeOrder,
    required this.getOrders,
    required this.getOrderById,
  }) : super(OrderInitial()) {
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<GetOrdersEvent>(_onGetOrders);
    on<GetOrderByIdEvent>(_onGetOrderById);
  }

  Future<void> _onPlaceOrder(PlaceOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await placeOrder(event.orderData);
    result.fold(
      (failure) => emit(OrderError(failure.message)),
      (order) => emit(OrderPlaced(order)),
    );
  }

  Future<void> _onGetOrders(GetOrdersEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await getOrders(event.userId);
    result.fold(
      (failure) => emit(OrderError(failure.message)),
      (orders) => emit(OrdersLoaded(orders)),
    );
  }

  Future<void> _onGetOrderById(GetOrderByIdEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await getOrderById(event.orderId);
    result.fold(
      (failure) => emit(OrderError(failure.message)),
      (order) => emit(OrderDetailLoaded(order)),
    );
  }
}