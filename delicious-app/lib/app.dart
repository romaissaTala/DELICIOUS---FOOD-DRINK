import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Delicious_App/core/di/injection.dart';
import 'package:Delicious_App/core/router/app_router.dart';
import 'package:Delicious_App/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:Delicious_App/features/products/presentation/bloc/product_bloc.dart';
import 'package:Delicious_App/features/products/presentation/bloc/category_bloc.dart';
import 'package:Delicious_App/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:Delicious_App/features/orders/presentation/bloc/order_bloc.dart';
import 'package:Delicious_App/core/theme/app_theme.dart';

class DeliciousApp extends StatelessWidget {
  const DeliciousApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(AuthCheckRequested())),
        BlocProvider(create: (_) => sl<ProductBloc>()),
        BlocProvider(create: (_) => sl<CategoryBloc>()),
        BlocProvider(create: (_) => sl<CartBloc>()),
        BlocProvider(create: (_) => sl<OrderBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Delicious App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,  // GoRouter handles all navigation
      ),
    );
  }
}