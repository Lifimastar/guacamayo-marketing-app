import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guacamayo_marketing_app/providers/auth_provider.dart';
import '../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../style/app_colors.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      logger.e('Error al cerrar sesion: ${e.message}', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesion: ${e.message}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      logger.e('Ocurrió un error inesperado al cerrar sesión: $e', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrio un error inesperado: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userProfile = authState.profile;
    final userEmail = authState.session?.user.email;

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Avatar y Nombre
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      userProfile?.name.isNotEmpty == true
                          ? userProfile!.name[0].toUpperCase()
                          : (userEmail?.isNotEmpty == true
                              ? userEmail![0].toUpperCase()
                              : '?'),
                      style: textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile?.name ?? 'Nombre no disponible',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (userEmail != null)
                    Text(
                      userEmail,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Opciones de Perfil
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar Nombre'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('TODO: Implementar edicion de nombre.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cambiar Contraseña'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('TODO: Implementar cambio de contrasena.'),
                  ),
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Boton Cerrar Sesion
            ElevatedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
