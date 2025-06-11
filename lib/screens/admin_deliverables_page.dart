import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deliverable.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../style/app_colors.dart';

class AdminDeliverablesPage extends StatefulWidget {
  final String bookingId;
  const AdminDeliverablesPage({super.key, required this.bookingId});

  @override
  State<AdminDeliverablesPage> createState() => _AdminDeliverablesPageState();
}

class _AdminDeliverablesPageState extends State<AdminDeliverablesPage> {
  final _supabase = Supabase.instance.client;
  List<Deliverable> _deliverables = [];
  bool _isLoading = true;
  Logger logger = Logger();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileUrlController = TextEditingController();
  File? _selectedFile;

  final String _bucketName = 'deliverables';

  @override
  void initState() {
    super.initState();
    _fetchDeliverables();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliverables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> data = await _supabase
          .from('deliverables')
          .select('*')
          .eq('booking_id', widget.bookingId)
          .order('uploaded_at', ascending: true);

      _deliverables = data.map((json) => Deliverable.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      logger.e('Error fetching deliverables: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error fetching deliverables: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileUrlController.clear();
      });
    }
  }

  Future<void> _addDeliverable() async {
    if (!mounted) return;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final fileUrl = _fileUrlController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título del entregable es obligatorio.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    if (_selectedFile == null && fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un archivo o ingresar una URL.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? finalFileUrl;
    String? finalStoragePathForDB;

    try {
      if (_selectedFile != null) {
        final file = _selectedFile!;
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final String pathForUpload = '${widget.bookingId}/$fileName';

        logger.i(
          'Uploading to Bucket: $_bucketName, Relative Path for Upload: $pathForUpload',
        );

        final String uploadedObjectKeyWithBucketPrefix = await _supabase.storage
            .from(_bucketName)
            .upload(pathForUpload, file);

        if (uploadedObjectKeyWithBucketPrefix.startsWith('$_bucketName/')) {
          finalStoragePathForDB = uploadedObjectKeyWithBucketPrefix.substring(
            _bucketName.length + 1,
          );
        } else {
          finalStoragePathForDB = uploadedObjectKeyWithBucketPrefix;
        }

        logger.i(
          'File uploaded. Path stored in DB will be: $finalStoragePathForDB',
        );
        finalFileUrl = null;
      } else {
        finalFileUrl = fileUrl;
        finalStoragePathForDB = null;
      }
      final newDeliverableData = {
        'booking_id': widget.bookingId,
        'title': title,
        'description': description.isNotEmpty ? description : null,
        'file_url': finalFileUrl,
        'storage_path': finalStoragePathForDB,
        'uploaded_by': _supabase.auth.currentUser?.id,
      };
      final Map<String, dynamic> responseDb =
          await _supabase
              .from('deliverables')
              .insert(newDeliverableData)
              .select()
              .single();
      final addedDeliverable = Deliverable.fromJson(responseDb);
      setState(() {
        _deliverables.add(addedDeliverable);
        _deliverables.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
        _titleController.clear();
        _descriptionController.clear();
        _fileUrlController.clear();
        _selectedFile = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entregable añadido con éxito.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } on StorageException catch (e) {
      logger.e('Storage Error adding deliverable: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir archivo: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } on PostgrestException catch (e) {
      logger.e('Postgrest Error adding deliverable: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar entregable: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      logger.e('Unexpected error adding deliverable: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrio un error inesperado: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDeliverable(
    String deliverableId,
    String? storagePath,
  ) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar este entregable?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        if (storagePath != null && storagePath.isNotEmpty) {
          await _supabase.storage.from('deliverables').remove([storagePath]);
          logger.i('File removed from storage: $storagePath');
        }

        await _supabase.from('deliverables').delete().eq('id', deliverableId);

        setState(() {
          _deliverables.removeWhere((d) => d.id == deliverableId);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entregable eliminado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      } on StorageException catch (e) {
        logger.e('Error deleting file from storage: ${e.message}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar archivo de Storage: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } on PostgrestException catch (e) {
        logger.e('Error deleting deliverable from DB: ${e.message}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar entregable de DB: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        logger.e('Unexpected error deleting deliverable: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ocurrió un error inesperado al eliminar entregable: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Entregables')),
      body:
          _isLoading && _deliverables.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Añadir Nuevo Entregable',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (Opcional)',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        if (_selectedFile == null)
                          TextField(
                            controller: _fileUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL del Archivo (Opcional)',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            _selectedFile == null
                                ? 'Seleccionar Archivo'
                                : 'Archivo: ${_selectedFile!.path.split('/').last}',
                          ),
                          onPressed: _isLoading ? null : _pickFile,
                        ),
                        if (_selectedFile != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Archivo local seleccionado: ${_selectedFile!.path.split('/').last}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _addDeliverable,
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
                                  : const Text('Anadir Entregable'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child:
                        _deliverables.isEmpty
                            ? Center(
                              child:
                                  _isLoading
                                      ? const Text('Cargando entregables...')
                                      : const Text(
                                        'No hay entregables para esta reserva.',
                                      ),
                            )
                            : ListView.builder(
                              itemCount: _deliverables.length,
                              itemBuilder: (context, index) {
                                final deliverable = _deliverables[index];
                                return ListTile(
                                  title: Text(deliverable.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (deliverable.description != null &&
                                          deliverable.description!.isNotEmpty)
                                        Text(deliverable.description!),
                                      if (deliverable.fileUrl != null &&
                                          deliverable.fileUrl!.isNotEmpty)
                                        Text(
                                          'URL: ${deliverable.fileUrl!}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                          ),
                                        ),
                                      if (deliverable.storagePath != null &&
                                          deliverable.storagePath!.isNotEmpty)
                                        const Text(
                                          'Archivo en Storage',
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      Text(
                                        'Subido el: ${deliverable.uploadedAt.toLocal().toString().split('.')[0]}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing:
                                      _isLoading
                                          ? null
                                          : IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                () => _deleteDeliverable(
                                                  deliverable.id,
                                                  deliverable.storagePath,
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
