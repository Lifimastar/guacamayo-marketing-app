import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  AdminUsersPageState createState() => AdminUsersPageState();
}

class AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _supabase = Supabase.instance.client;
  List<Profile> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, bool> _isUpdatingRole = {};
  final Map<String, bool> _isDeletingUser = {};

  String? _adminJwt;

  @override
  void initState() {
    super.initState();
    _adminJwt = ref.read(authProvider).session?.accessToken;
    if (_adminJwt == null) {
      setState(() {
        _errorMessage = 'Error: JWT de administrador no disponible.';
        _isLoading = false;
      });
      return;
    }
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> data = await _supabase
          .from('profiles')
          .select('*')
          .order('name', ascending: true);

      _users = data.map((json) => Profile.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      logger.e('Error fetching users: ${e.message}', error: e);
      setState(() {
        _errorMessage = 'Error al cargar los usuarios: ${e.message}';
      });
    } catch (e) {
      logger.e('Unexpected error fetching users: $e', error: e);
      setState(() {
        _errorMessage =
            'Ocurrió un error inesperado al cargar los usuarios: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Cambio de Rol'),
          content: Text(
            '¿Estás seguro de que quieres cambiar el rol de este usuario a "$newRole"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Cambiar'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isUpdatingRole[userId] = true;
    });

    try {
      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      setState(() {
        final index = _users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          _users[index] = _users[index].copyWith(role: newRole);
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol de usuario actualizado a "$newRole".'),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error changing user role: ${e.message}', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar rol: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error changing user role: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error inesperado al cambiar rol: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingRole.remove(userId);
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación de Usuario'),
          content: const Text(
            '¡ADVERTENCIA! Eliminar este usuario es una acción permanente y eliminará todos sus datos asociados (reservas, mensajes, etc.). ¿Estás seguro?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Eliminar Permanentemente'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (_adminJwt == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: JWT de administrador no disponible para eliminar usuario.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDeletingUser[userId] = true;
    });

    try {
      final url = Uri.parse('$backendUrl/admin/users/$userId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_adminJwt'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        logger.i('User $userId deleted successfully via backend.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _users.removeWhere((user) => user.id == userId);
        });
      } else if (response.statusCode == 401) {
        if (!mounted) return;
        logger.w('Admin user deletion failed: Authentication error (401)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de autenticación al eliminar usuario. Vuelve a iniciar sesión.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 403) {
        if (!mounted) return;
        logger.w('Admin user deletion failed: Authorization error (403)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No tienes permisos para eliminar usuarios.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        logger.w(
          'Admin user deletion failed: User not found (404) for ID $userId',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario no encontrado.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _users.removeWhere((user) => user.id == userId);
        });
      } else {
        logger.w(
          'Admin user deletion failed with status ${response.statusCode}: ${response.body}',
        );
        String errorMessage =
            'Error al eliminar usuario: ${response.statusCode}';
        try {
          final errorJson = json.decode(response.body);
          if (errorJson != null && errorJson['detail'] != null) {
            errorMessage = 'Error al eliminar usuario: ${errorJson['detail']}';
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      logger.e(
        'Unexpected Error calling backend for user deletion: $e',
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ocurrió un error inesperado al eliminar usuario: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDeletingUser.remove(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body:
          _isLoading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child:
                        _errorMessage != null
                            ? Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                            : _users.isEmpty
                            ? Center(
                              child:
                                  _isLoading
                                      ? const Text('Cargando usuarios...')
                                      : const Text(
                                        'No hay usuarios registrados.',
                                      ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final userProfile = _users[index];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nombre: ${userProfile.name}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rol: ${userProfile.role}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Rol:',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  DropdownButton<String>(
                                                    value: userProfile.role,
                                                    items:
                                                        [
                                                          'client',
                                                          'admin',
                                                        ].map((String role) {
                                                          return DropdownMenuItem<
                                                            String
                                                          >(
                                                            value: role,
                                                            child: Text(role),
                                                          );
                                                        }).toList(),
                                                    onChanged:
                                                        (_isLoading ||
                                                                _isUpdatingRole
                                                                    .containsKey(
                                                                      userProfile
                                                                          .id,
                                                                    ) ||
                                                                _isDeletingUser
                                                                    .containsKey(
                                                                      userProfile
                                                                          .id,
                                                                    ))
                                                            ? null
                                                            : (
                                                              String? newValue,
                                                            ) {
                                                              if (newValue !=
                                                                      null &&
                                                                  newValue !=
                                                                      userProfile
                                                                          .role) {
                                                                _changeUserRole(
                                                                  userProfile
                                                                      .id,
                                                                  newValue,
                                                                );
                                                              }
                                                            },
                                                  ),
                                                  if (_isUpdatingRole
                                                      .containsKey(
                                                        userProfile.id,
                                                      ))
                                                    const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2.0,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon:
                                                  _isDeletingUser.containsKey(
                                                        userProfile.id,
                                                      )
                                                      ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2.0,
                                                              color: Colors.red,
                                                            ),
                                                      )
                                                      : const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                              onPressed:
                                                  (_isLoading ||
                                                          _isUpdatingRole
                                                              .containsKey(
                                                                userProfile.id,
                                                              ) ||
                                                          _isDeletingUser
                                                              .containsKey(
                                                                userProfile.id,
                                                              ))
                                                      ? null
                                                      : () => _deleteUser(
                                                        userProfile.id,
                                                      ),
                                              tooltip: 'Eliminar Usuario',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
