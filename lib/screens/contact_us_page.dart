import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  // Funcion para lanzar URLs (email, web)
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      logger.e('Could not launch $urlString');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo abrir: $urlString')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Contactanos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Estamos aqui para ayudarte!',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Si tienes alguna pregunta sobre nuestros servicios, necesitas soporte o simplemente quieres saludar, no dudes en contactarnos a traves de los siguientes medios:',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Email
            ListTile(
              leading: Icon(
                Icons.email_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text('Correo Electronico', style: textTheme.titleMedium),
              subtitle: Text(
                'hello@guacamayomarketingsolutions.com',
                style: textTheme.bodyMedium,
              ),
              onTap:
                  () => _launchUrl(
                    context,
                    'mailto:hello@guacamayomarketingsolutions.com',
                  ),
            ),
            const Divider(),

            // Telefono / WhatsApp
            ListTile(
              leading: Icon(
                Icons.phone_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text('Telefono / WhatsApp', style: textTheme.titleMedium),
              subtitle: Text('+34614449014', style: textTheme.bodyMedium),
              onTap: () => _launchUrl(context, 'tel:+34614449014'),
            ),
            const Divider(),

            // Sitio Web
            ListTile(
              leading: Icon(
                Icons.web_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Visita Nuestro Sitio Web',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Para mas informacion o usar nuestro formulario de contacto.',
                style: textTheme.bodyMedium,
              ),
              onTap:
                  () => _launchUrl(
                    context,
                    'https://guacamayomarketingsolutions.com/',
                  ),
            ),
            const Divider(),

            // Instagram
            ListTile(
              leading: Icon(
                Icons.group_work_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text('Siguenos en Redes', style: textTheme.titleMedium),
              subtitle: Row(
                children: [
                  IconButton(
                    icon: Icon(FontAwesomeIcons.instagram),
                    onPressed:
                        () => _launchUrl(
                          context,
                          'https://www.instagram.com/guacamayo.marketing.solutions/',
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(child: Image.asset('assets/images/logo.png', height: 80)),
          ],
        ),
      ),
    );
  }
}
