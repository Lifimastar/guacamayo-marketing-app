import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deliverable.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDeliverablesPage extends StatefulWidget {
  final String bookingId;
  const UserDeliverablesPage({super.key, required this.bookingId});

  @override
  State<UserDeliverablesPage> createState() => _UserDeliverablesPageState();
}

class _UserDeliverablesPageState extends State<UserDeliverablesPage> {
  final _supabase = Supabase.instance.client;
  List<Deliverable> _deliverables = [];
  bool _isLoading = true;
  String? _errorMessage;
  Logger logger = Logger();

  final String _bucketName = 'deliverables';

  @override
  void initState() {
    super.initState();
    _fetchDeliverables();
  }

  Future<void> _fetchDeliverables() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<Map<String, dynamic>> data = await _supabase
          .from('deliverables')
          .select('*')
          .eq('booking_id', widget.bookingId)
          .order('uploaded_at', ascending: true);
      _deliverables = data.map((json) => Deliverable.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      logger.e('Error fetching user deliverables: ${e.message}');
      setState(() {
        _errorMessage = 'Error al cargar los entregables: ${e.message}';
      });
    } catch (e) {
      logger.e('Unexpected error fetching user deliverables: $e');
      setState(() {
        _errorMessage =
            'Ocurrió un error inesperado al cargar los entregables: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openDeliverable(Deliverable deliverable) async {
    Uri? urlToLaunch;

    logger.i('Attempting to open deliverable: ${deliverable.title}');
    logger.i('File URL from DB: ${deliverable.fileUrl}');
    logger.i('Storage Path from DB: ${deliverable.storagePath}');

    if (deliverable.fileUrl != null && deliverable.fileUrl!.isNotEmpty) {
      final parsedUrl = Uri.tryParse(deliverable.fileUrl!);
      if (parsedUrl != null && parsedUrl.hasScheme) {
        urlToLaunch = parsedUrl;
      } else {
        logger.i('Invalid URL format: ${deliverable.fileUrl}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL del archivo no valida: ${deliverable.fileUrl!}'),
          ),
        );
        return;
      }
    } else if (deliverable.storagePath != null &&
        deliverable.storagePath!.isNotEmpty) {
      final String relativePathInBucket = deliverable.storagePath!;
      logger.i(
        'Generating signed URL for bucket: $_bucketName, path: $relativePathInBucket',
      );
      try {
        final String signedUrlString = await _supabase.storage
            .from(_bucketName)
            .createSignedUrl(relativePathInBucket, 60 * 5);
        logger.i('Generated signed URL: $signedUrlString');
        urlToLaunch = Uri.parse(signedUrlString);
      } on StorageException catch (e) {
        logger.e('StorageException generating signed URL: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al acceder al archivo (Storage): ${e.message}',
              ),
            ),
          );
        }
        return;
      } catch (e) {
        logger.e('Unexpected error generating signed URL: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ocurrió un error inesperado al acceder al archivo: $e',
              ),
            ),
          );
        }
        return;
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este entregable no tiene un archivo asociado.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (await canLaunchUrl(urlToLaunch)) {
      await launchUrl(urlToLaunch, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el recurso: $urlToLaunch'),
          ),
        );
      }
    }
    }

  Widget _buildDeliverableIcon(Deliverable deliverable) {
    if (deliverable.fileUrl != null && deliverable.fileUrl!.isNotEmpty) {
      if (deliverable.fileUrl!.toLowerCase().endsWith('.pdf')) {
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      }
      if (deliverable.fileUrl!.toLowerCase().endsWith('.doc') ||
          deliverable.fileUrl!.toLowerCase().endsWith('.docx')) {
        return const Icon(Icons.description, color: Colors.blue);
      }
    } else if (deliverable.storagePath != null &&
        deliverable.storagePath!.isNotEmpty) {
      final extension = deliverable.storagePath!.split('.').last.toLowerCase();
      if (extension == 'pdf') {
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      }
      if (extension == 'doc' || extension == 'docx') {
        return const Icon(Icons.description, color: Colors.blue);
      }
      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        return const Icon(Icons.image, color: Colors.green);
      }
      if (extension == 'svg') {
        return const Icon(Icons.palette_outlined, color: Colors.orange);
      }
    }
    return const Icon(Icons.insert_drive_file);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Entregables de la Reserva')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
              : _deliverables.isEmpty
              ? const Center(
                child: Text('No hay entregables para esta reserva aun.'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _deliverables.length,
                itemBuilder: (context, index) {
                  final deliverable = _deliverables[index];
                  return Card(
                    child: ListTile(
                      leading: _buildDeliverableIcon(deliverable),
                      title: Text(
                        deliverable.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (deliverable.description != null &&
                              deliverable.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                bottom: 4.0,
                              ),
                              child: Text(
                                deliverable.description!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          Text(
                            'Subido el: ${deliverable.uploadedAt.toLocal().toString().split('.')[0]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.download_for_offline_outlined),
                      onTap: () => _openDeliverable(deliverable),
                    ),
                  );
                },
              ),
    );
  }
}
