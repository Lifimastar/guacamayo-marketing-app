import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guacamayo_marketing_app/providers/auth_provider.dart';
import '../models/profile.dart';
import '../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../style/app_colors.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  // --- CERRAR SESION ---
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

  // --- DIALOG PARA EDITAR NOMBRE ---
  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    Profile currentProfile,
  ) async {
    final nameController = TextEditingController(text: currentProfile.name);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Editar Nombre'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre no puede estar vacio.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newName = nameController.text.trim();
                  Navigator.of(dialogContext).pop();
                  await _updateUserName(context, ref, newName);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- ACTUALIZA NOMBRE ---
  Future<void> _updateUserName(
    BuildContext context,
    WidgetRef ref,
    String newName,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'name': newName})
          .eq('id', userId);

      ref.read(authProvider.notifier).forceProfileReload();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Nombre actualizado con éxito!'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } on PostgrestException catch (e) {
      logger.e('Error updating user name: ${e.message}', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el nombre: ${e.message}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // --- DIALOG PARA EDITAR CONTRASENA ---
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar Contrasena'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contrasena',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La contrasena debe tener al menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contrasena',
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Las contrasenas no coinciden.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newPassword = passwordController.text.trim();
                  Navigator.of(dialogContext).pop();
                  await _updateUserPassword(context, newPassword);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- ACTUALIZA CONTRASENA ---
  Future<void> _updateUserPassword(
    BuildContext context,
    String newPassword,
  ) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Contraseña actualizada con éxito!'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } on AuthException catch (e) {
      logger.e('Error updating user password: ${e.message}', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la contrasena: ${e.message}'),
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
                if (userProfile != null) {
                  _showEditNameDialog(context, ref, userProfile);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cambiar Contraseña'),
              onTap: () {
                _showChangePasswordDialog(context);
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
