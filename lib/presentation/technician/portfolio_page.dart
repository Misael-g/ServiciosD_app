import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/models/profile_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class PortfolioPage extends StatefulWidget {
  final ProfileModel technician;

  const PortfolioPage({
    super.key,
    required this.technician,
  });

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> 
    with SingleTickerProviderStateMixin {
  final StorageRemoteDataSource _storageDS = StorageRemoteDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _portfolioImages = [];
  bool _isLoading = true;
  bool _isUploading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadPortfolio();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolio() async {
    setState(() => _isLoading = true);

    try {
      final images = await _storageDS.getPortfolioImages(widget.technician.id);
      setState(() {
        _portfolioImages = images;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error al cargar portafolio');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al seleccionar imagen');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al tomar foto');
      }
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _isUploading = true);

    try {
      await _storageDS.uploadPortfolioImage(
        technicianId: widget.technician.id,
        file: file,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, '¡Imagen agregada al portafolio!');
        _loadPortfolio();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al subir imagen: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text('Eliminar Imagen'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta imagen del portafolio?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final fileName = imageUrl.split('/').last;
      await _storageDS.deletePortfolioImage(
        technicianId: widget.technician.id,
        fileName: fileName,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Imagen eliminada');
        _loadPortfolio();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al eliminar imagen');
      }
    }
  }

  void _viewImageFullscreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.black,
          appBar: AppBar(
            backgroundColor: AppColors.black,
            iconTheme: const IconThemeData(color: AppColors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteImage(imageUrl);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Agregar Foto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildImageOption(
                Icons.photo_library_rounded,
                'Seleccionar de Galería',
                AppColors.primary,
                () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),

              _buildImageOption(
                Icons.camera_alt_rounded,
                'Tomar Foto',
                AppColors.success,
                () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar Moderno
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.info,
                      AppColors.info.withOpacity(0.8),
                    ],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              size: 32,
                              color: AppColors.white,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mi Portafolio',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Muestra tus mejores trabajos',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _portfolioImages.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final imageUrl = _portfolioImages[index];
                            return FadeTransition(
                              opacity: _animationController,
                              child: _buildPortfolioItem(imageUrl),
                            );
                          },
                          childCount: _portfolioImages.length,
                        ),
                      ),
                    ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showAddOptions,
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        icon: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_photo_alternate_rounded),
        label: Text(
          _isUploading ? 'Subiendo...' : 'Agregar Foto',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_rounded,
                size: 80,
                color: AppColors.info.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tu portafolio está vacío',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Agrega fotos de tus trabajos completados para mostrar tu experiencia a los clientes',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _showAddOptions,
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 24),
                label: const Text(
                  'Agregar Primera Foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.small,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tips_and_updates_rounded,
                          color: AppColors.info,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Consejos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTip('✓ Sube fotos de buena calidad'),
                  _buildTip('✓ Muestra trabajos terminados'),
                  _buildTip('✓ Varía los tipos de trabajos'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioItem(String imageUrl) {
    return GestureDetector(
      onTap: () => _viewImageFullscreen(imageUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.medium,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.background,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.background,
                child: const Center(
                  child: Icon(Icons.error, color: AppColors.error),
                ),
              ),
            ),
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.small,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: () => _deleteImage(imageUrl),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            // View icon
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}