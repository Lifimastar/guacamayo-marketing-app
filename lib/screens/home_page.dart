import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guacamayo_marketing_app/screens/contact_us_page.dart';
import 'package:guacamayo_marketing_app/screens/service_details_page.dart';
import 'package:guacamayo_marketing_app/widgets/service_card_content.dart';
import '../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service.dart';
import '../style/app_colors.dart';
import 'services_catalog_page.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToServices;
  const HomePage({super.key, this.onNavigateToServices});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  List<Service> _featuredServices = [];
  bool _isLoadingServices = true;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchFeaturedServices();
  }

  Future<void> _fetchFeaturedServices() async {
    if (!mounted) return;
    setState(() {
      _isLoadingServices = true;
    });
    try {
      final List<Map<String, dynamic>> data = await Supabase.instance.client
          .from('services')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(3);

      if (!mounted) return;
      _featuredServices = data.map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      if (!mounted) return;
      logger.e('Error fetching featured services: $e', error: e);
    } finally {
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  Future<void> _launchWhatsApp() async {
    String phoneNumber = '+34614449014';
    String message = Uri.encodeComponent(
      'Hola, estoy interesado en sus servicios de marketing.',
    );
    Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Whatsapp.')),
        );
      }
    }
  }

  // Widget para construir seccion con titulo y contenido
  Widget _buildSection({
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
  Widget build(BuildContext context) {
    ref.watch(authProvider);

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
      body: RefreshIndicator(
        onRefresh: _fetchFeaturedServices,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
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
                  color: AppColors.guacamayoBlue.withAlpha((255 * 0.9).round()),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Estrategias creativas para marcas con visión.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.white.withAlpha((255 * 0.86).round()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.onNavigateToServices != null) {
                          widget.onNavigateToServices!();
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
                      ),
                      child: const Text('Descubre cómo'),
                    ),
                  ],
                ),
              ),
              // Seccion "Sobre Guacamayo Marketing"
              _buildSection(
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
                    Text(
                      'Nuestros Servicios',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te ofrecemos soluciones integrales para que tu marca crezca, conecte y venda en el mundo digital.',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    _isLoadingServices
                        ? const Center(child: CircularProgressIndicator())
                        : _featuredServices.isEmpty
                        ? const Text(
                          'No hay servicios destacados en este momento.',
                        )
                        : Column(
                          children:
                              _featuredServices.map((service) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Card(
                                    elevation: 4.0,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ServiceDetailsPage(
                                                  service: service,
                                                ),
                                          ),
                                        );
                                      },
                                      child: ServiceCardContent(
                                        service: service,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                    const SizedBox(height: 16),
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
                      onPressed: _launchWhatsApp,
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
      ),
      // Boton Flotante de Whatsapp
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: AppColors.guacamayoGreen,
        tooltip: 'Contáctanos por WhatsApp',
        child: const Icon(FontAwesomeIcons.whatsapp),
      ),
    );
  }
}
