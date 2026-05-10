import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildProfileContent(context, state.user);
          } else if (state is AuthGuest) {
            return _buildGuestContent(context);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name ?? user.email,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // Menu Items
          _buildMenuItem(
            icon: Icons.history,
            title: 'Order History',
            onTap: () => context.push('/orders'),
          ),
          _buildMenuItem(
            icon: Icons.location_on,
            title: 'Saved Addresses',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.face,
            title: 'Face Recognition Setup',
            onTap: () => context.push('/face-setup'),
            subtitle: user.hasFaceAuth ? 'Enabled' : 'Not set up',
          ),
          _buildMenuItem(
            icon: Icons.credit_card,
            title: 'Payment Methods',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: 'Language',
            onTap: () {},
            subtitle: 'English',
          ),
          const Divider(height: 32),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              _showLogoutDialog(context);
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'You are browsing as a guest',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account to save your addresses, track orders, and get faster checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Sign In / Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.green.shade700),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}