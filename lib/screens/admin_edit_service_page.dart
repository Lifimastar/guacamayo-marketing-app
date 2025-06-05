import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';
import '../style/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AdminEditServicePage extends StatefulWidget {
  final Service? service;
  const AdminEditServicePage({super.key, this.service});

  @override
  State<AdminEditServicePage> createState() => _AdminEditServicePageState();
}

class _AdminEditServicePageState extends State<AdminEditServicePage> {
  Logger logger = Logger();
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  bool _isActive = true;
  bool _isLoading = false;
  File? _selectedCoverImageFile;
  String? _existingCoverImageUrl;
  String? _newCoverImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.service?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.service?.price.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.service?.duration?.toString() ?? '',
    );
    _isActive = widget.service?.isActive ?? true;
    _existingCoverImageUrl = widget.service?.coverImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Metodo para seleccionar una imagen de portada
  Future<void> _pickCoverImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedCoverImageFile = File(result.files.single.path!);
        _newCoverImageUrl = null;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccion de imagen cancelada.')),
      );
    }
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim());
      final duration = int.tryParse(_durationController.text.trim());
      String? finalCoverImageUrl = _existingCoverImageUrl;

      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El precio debe ser un numero valido.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        // 1. Subir nueva imagen si se selecciono una
        if (_selectedCoverImageFile != null) {
          final file = _selectedCoverImageFile!;
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          final String storagePath = fileName;
          logger.i(
            'Uploading to Bucket: service-covers, Path for Upload: $storagePath',
          );
          await _supabase.storage
              .from('service-covers')
              .upload(storagePath, file);
          // Subir el archivo
          finalCoverImageUrl = _supabase.storage
              .from('service-covers')
              .getPublicUrl(storagePath);
          logger.i('Uploaded new cover image: $finalCoverImageUrl');
        }

        final serviceData = {
          'name': name,
          'description': description.isNotEmpty ? description : null,
          'price': price,
          'duration': duration,
          'cover_image_url': finalCoverImageUrl,
          'is_active': _isActive,
        };

        if (widget.service == null) {
          await _supabase.from('services').insert(serviceData);
        } else {
          await _supabase
              .from('services')
              .update(serviceData)
              .eq('id', widget.service!.id);
        }
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Servicio ${widget.service == null ? "creado" : "actualizado"} con exito.',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
      } on StorageException catch (e) {
        logger.e('Storage Error saving service image: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: ${e.message}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      } on PostgrestException catch (e) {
        logger.e('Error saving service: ${e.message}', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar servicio: ${e.message}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      } catch (e) {
        logger.e('Unexpected error saving service: $e', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ocurrió un error inesperado al guardar servicio: $e',
            ),
            backgroundColor: AppColors.errorColor,
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
    final textTheme = TextTheme();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service == null ? 'Anadir Nuevo Servicio' : 'Editar Servicio',
        ),
        actions: [
          IconButton(
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : const Icon(Icons.save_outlined),
            tooltip: 'Guardar Servicio',
            onPressed: _isLoading ? null : _saveService,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Campo nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Servicio',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre del servicio es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Descripcion
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion (Opcional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Campo Precio
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, introduce un numero valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Duracion (Opcional)
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duracion (ej: horas, opcional)',
                ),
                keyboardType: TextInputType.number,
              ),

              // Previsualizacion de Imagen y Boton de Seleccion
              const SizedBox(height: 16),
              Text(
                'Imagen de Portada (Opcional)',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Previsualizacion
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.mediumGrey),
                  borderRadius: BorderRadius.circular(8.0),
                  color: AppColors.lightGrey,
                ),
                child:
                    (_selectedCoverImageFile != null)
                        ? Image.file(
                          _selectedCoverImageFile!,
                          fit: BoxFit.contain,
                        )
                        : (_newCoverImageUrl != null &&
                            _newCoverImageUrl!.isNotEmpty)
                        ? Image.network(
                          _newCoverImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                color: AppColors.mediumGrey,
                                size: 40,
                              ),
                        )
                        : (_existingCoverImageUrl != null &&
                            _existingCoverImageUrl!.isNotEmpty)
                        ? Image.network(
                          _existingCoverImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                color: AppColors.mediumGrey,
                                size: 40,
                              ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.mediumGrey,
                            size: 40,
                          ),
                        ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.image_search),
                label: Text(
                  _selectedCoverImageFile == null
                      ? 'Seleccionar Imagen'
                      : 'Cambiar Imagen',
                ),
                onPressed: _isLoading ? null : _pickCoverImage,
              ),
              const SizedBox(height: 16),

              // Checkbox Activo?
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _isActive = value;
                        });
                      }
                    },
                  ),
                  const Text('Servicio Activo'),
                ],
              ),
              const SizedBox(height: 24),

              // Boton Guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _saveService,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : Text(
                          widget.service == null
                              ? 'Crear Servicio'
                              : 'Guardar Cambios',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
