import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../style/app_colors.dart';

enum AuthView { signUp, signIn }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final _supabase = Supabase.instance.client;

  AuthView _currentView = AuthView.signIn;
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      final String name = _nameController.text.trim();

      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (!mounted) return;

      if (res.user != null) {
        await _supabase.from('profiles').insert({
          'id': res.user!.id,
          'name': name,
          'role': 'client',
        });
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso Ahora puedes iniciar sesion.'),
            backgroundColor: AppColors.successColor,
          ),
        );
        _toggleView();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error desconocido durante el registro.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en el registro: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear perfil: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrio un error inesperado: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicio de sesion exitoso.'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contrasena incorrectos.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesion: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrio un error inesperado: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleView() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();

    setState(() {
      _currentView =
          _currentView == AuthView.signIn ? AuthView.signUp : AuthView.signIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.guacamayoBlue.withAlpha((255 * 0.8).round()),
              AppColors.guacamayoRed.withAlpha((255 * 0.6).round()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 40),
                // Titulo
                Text(
                  _currentView == AuthView.signIn
                      ? 'Bienvenido de Nuevo'
                      : 'Crea tu Cuenta',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentView == AuthView.signIn
                      ? 'Ingresa tus credenciales para continuar'
                      : 'Completa los campos para registrarte',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 32),
                // campo de correo electronico
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // campo de contrasena
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colorScheme.primary,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),

                // campo de nombre (solo al registrarse)
                if (_currentView == AuthView.signUp) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // boton principal (iniciar sesion o registrarse)
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : (_currentView == AuthView.signIn
                              ? _signIn
                              : _signUp),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                          : Text(
                            _currentView == AuthView.signIn
                                ? 'Iniciar Sesión'
                                : 'Registrarse',
                          ),
                ),
                const SizedBox(height: 20),

                // boton para alternar entre vistas
                TextButton(
                  onPressed: _isLoading ? null : _toggleView,
                  child: Text(
                    _currentView == AuthView.signIn
                        ? '¿No tienes cuenta? Regístrate'
                        : '¿Ya tienes cuenta? Inicia Sesión',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
