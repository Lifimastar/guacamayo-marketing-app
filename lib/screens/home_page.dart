import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guacamayo_marketing_app/providers/services_provider.dart'; // --- CAMBIO ---
import 'package:guacamayo_marketing_app/screens/contact_us_page.dart';
import 'package:guacamayo_marketing_app/screens/services_catalog_page.dart';
import 'package:guacamayo_marketing_app/widgets/featured_service_card.dart'; // --- CAMBIO ---
import 'package:url_launcher/url_launcher.dart';
import '../style/app_colors.dart';

// sección de servicios destacados
class _FeaturedServicesSection extends ConsumerWidget {
  const _FeaturedServicesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredServicesAsync = ref.watch(featuredServicesProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nuestros Servicios Destacados',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Soluciones populares para impulsar tu marca.',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: featuredServicesAsync.when(
            loading:
                () => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder:
                      (context, index) => const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: FeaturedServiceCardSkeleton(),
                      ),
                ),
            error:
                (err, stack) =>
                    Center(child: Text('Error al cargar servicios: $err')),
            data: (services) {
              if (services.isEmpty) {
                return const Center(
                  child: Text('No hay servicios destacados.'),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: FeaturedServiceCard(service: services[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Esqueleto para la tarjeta de servicio destacado
class FeaturedServiceCardSkeleton extends StatelessWidget {
  const FeaturedServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.black.withAlpha(20),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 16,
                  width: 120,
                  color: Colors.black.withAlpha(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  final VoidCallback? onNavigateToServices;
  const HomePage({super.key, this.onNavigateToServices});

  Future<void> _launchWhatsApp(BuildContext context) async {
    String phoneNumber = '+34614449014';
    String message = Uri.encodeComponent(
      'Hola, estoy interesado en sus servicios de marketing.',
    );
    Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Whatsapp.')),
        );
      }
    }
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget content,
    Color backgroundColor = Colors.transparent,
    Color titleColor = AppColors.almostBlack,
    Color subtitleColor = AppColors.darkGrey,
    EdgeInsets padding = const EdgeInsets.all(24.0),
  }) {
    return Container(
      color: backgroundColor,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: subtitleColor),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 30),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Seccion Hero/Bienvenida
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 60.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.guacamayoBlue,
                    AppColors.primaryAction.withAlpha((255 * 0.8).round()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/hero_background.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha((255 * 0.4).round()),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Transformamos ideas en resultados digitales',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          blurRadius: 8.0,
                          color: Colors.black54,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estrategias creativas para marcas con visión',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.white.withAlpha(230),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (onNavigateToServices != null) {
                        onNavigateToServices!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServicesCatalogPage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.guacamayoYellow,
                      foregroundColor: AppColors.almostBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 5,
                    ),
                    child: const Text('Descubre cómo'),
                  ),
                ],
              ),
            ),
            // Seccion "Sobre Guacamayo Marketing"
            _buildSection(
              context: context,
              title: 'Quiénes somos...',
              subtitle: 'Sobre Guacamayo Marketing Solutions',
              backgroundColor: AppColors.guacamayoRed.withAlpha(
                (255 * 0.9).round(),
              ),
              titleColor: AppColors.guacamayoYellow,
              subtitleColor: AppColors.white,
              content: Text(
                'Ayudamos a negocios y emprendedores a crecer con estrategias efectivas de marketing digital, diseño web profesional y gestión de redes sociales. Somos una agencia creativa con enfoque en resultados reales: generamos visibilidad online, mejoramos tu presencia en redes y desarrollamos sitios web optimizados para conversión y posicionamiento SEO.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha((255 * 0.9).round()),
                ),
              ),
            ),

            // Seccion "Servicio Destacados"
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FeaturedServicesSection(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServicesCatalogPage(),
                          ),
                        );
                      },
                      child: const Text('Ver todos los servicios'),
                    ),
                  ),
                ],
              ),
            ),
            // Seccion "Creamos estrategias personalizadas para ti"
            _buildSection(
              context: context,
              title: 'Creamos estrategias personalizadas para ti',
              subtitle: 'Contenido de valor que conecta con tu audiencia.',
              backgroundColor: AppColors.almostBlack,
              titleColor: AppColors.guacamayoYellow,
              subtitleColor: AppColors.lightGrey,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', height: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '• Post diseñados para redes sociales',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '• Reels creativos y dinámicos',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '• Artículos y blogs optimizados para SEO',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Seccion "Contactanos"
            _buildSection(
              context: context,
              title: '¿Listo para crecer?',
              subtitle: 'Contáctanos para una consulta gratuita.',
              backgroundColor: colorScheme.surface,
              titleColor: colorScheme.primary,
              subtitleColor: colorScheme.onSurface,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactUsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Enviar un Mensaje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.guacamayoBlue,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _launchWhatsApp(context),
                    icon: const Icon(FontAwesomeIcons.whatsapp),
                    label: const Text('Contactar por WhatsApp'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.guacamayoGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // Boton Flotante de Whatsapp
      floatingActionButton: FloatingActionButton(
        onPressed: () => _launchWhatsApp(context),
        backgroundColor: AppColors.guacamayoGreen,
        tooltip: 'Contáctanos por WhatsApp',
        child: const Icon(FontAwesomeIcons.whatsapp),
      ),
    );
  }
}
