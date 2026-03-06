import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../theme/app_theme.dart';
import '../business/dashboard_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDetailsAsync = ref.watch(userDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: userDetailsAsync.when(
        data: (user) {
          final isBusiness = user?.role == 'business';
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              if (isBusiness)
                Consumer(
                  builder: (context, ref, _) {
                    final businessAsync = ref.watch(currentBusinessProvider);
                    return businessAsync.when(
                      data: (restaurant) {
                        if (restaurant != null && restaurant.isVerified) {
                          return _buildSection(
                            context,
                            title: 'Business Tools',
                            children: [
                              _buildListTile(
                                context,
                                title: 'Dashboard',
                                icon: Icons.dashboard,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BusinessDashboardScreen(restaurant: restaurant),
                                    ),
                                  );
                                },
                              ),
                              _buildListTile(
                                context,
                                title: 'Menu Manager',
                                icon: Icons.restaurant_menu,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Menu Manager coming soon')),
                                  );
                                },
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              _buildSection(
                context,
                title: 'Account Security',
                children: [
                  _buildListTile(
                    context,
                    title: 'Change Password',
                    icon: Icons.lock_outline,
                    onTap: () {},
                  ),
                  _buildListTile(
                    context,
                    title: 'Two-Factor Authentication',
                    icon: Icons.security,
                    onTap: () {},
                  ),
                ],
              ),
              _buildSection(
                context,
                title: 'General',
                children: [
                  _buildListTile(
                    context,
                    title: 'Log Out',
                    icon: Icons.logout,
                    color: AppTheme.errorColor,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pop(context); // Optional, Auth state change handles root nav
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading settings')),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.05),
                    indent: 56,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: color == null ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}
