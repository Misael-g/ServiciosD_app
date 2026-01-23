import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class SendQuotationPage extends StatefulWidget {
  final ServiceRequestModel serviceRequest;

  const SendQuotationPage({
    super.key,
    required this.serviceRequest,
  });

  @override
  State<SendQuotationPage> createState() => _SendQuotationPageState();
}

class _SendQuotationPageState extends State<SendQuotationPage> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _laborCostController = TextEditingController();
  final _materialsCostController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();

  bool _isLoading = false;
  double _totalPrice = 0.0;
  int _selectedArrivalHours = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _laborCostController.dispose();
    _materialsCostController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final labor = double.tryParse(_laborCostController.text) ?? 0.0;
    final materials = double.tryParse(_materialsCostController.text) ?? 0.0;

    setState(() {
      _totalPrice = labor + materials;
    });
  }

  Future<void> _sendQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalPrice <= 0) {
      SnackbarHelper.showError(
        context,
        'El precio total debe ser mayor a \$0',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Text(
              'Confirmar Cotización',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estás a punto de enviar esta cotización:',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              
              // Desglose en card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildConfirmationItem(
                      '💪 Mano de Obra',
                      '\$${_laborCostController.text}',
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmationItem(
                      '🛠️ Materiales',
                      '\$${_materialsCostController.text}',
                    ),
                    const Divider(height: 24),
                    _buildConfirmationItem(
                      'TOTAL',
                      '\$${_totalPrice.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info adicional
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⏱️ ${_durationController.text} min  •  🚗 ~${_getArrivalTimeText(_selectedArrivalHours)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Enviar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final technicianId = SupabaseConfig.currentUserId;
      if (technicianId == null) {
        throw Exception('No se pudo obtener el ID del técnico');
      }

      await _quotationsDS.createQuotation(
        serviceRequestId: widget.serviceRequest.id,
        estimatedPrice: _totalPrice,
        laborCost: double.parse(_laborCostController.text),
        materialsCost: double.parse(_materialsCostController.text),
        estimatedDuration: int.parse(_durationController.text),
        estimatedArrivalTime: _selectedArrivalHours,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Cotización enviada exitosamente!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error al enviar cotización: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getArrivalTimeText(int hours) {
    if (hours == 0) return '30 min';
    if (hours == 1) return '1 hora';
    if (hours < 24) return '$hours horas';
    return 'Mañana';
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
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              title: const Text(
                'Nueva Cotización',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Info de la solicitud
                    _buildRequestInfo(),
                    const SizedBox(height: 24),

                    // Sección de Costos
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Desglose de Costos',
                            icon: Icons.calculate_rounded,
                          ),
                          const SizedBox(height: 16),

                          // Mano de obra
                          _buildCostField(
                            controller: _laborCostController,
                            label: 'Mano de Obra',
                            hint: 'Tu trabajo',
                            icon: Icons.engineering_rounded,
                            emoji: '💪',
                            color: AppColors.primary,
                          ),

                          const SizedBox(height: 16),

                          // Materiales
                          _buildCostField(
                            controller: _materialsCostController,
                            label: 'Materiales',
                            hint: 'Herramientas y suministros',
                            icon: Icons.shopping_cart_rounded,
                            emoji: '🛠️',
                            color: AppColors.warning,
                          ),

                          const SizedBox(height: 24),

                          // Total Card
                          _buildTotalCard(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sección de Tiempo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Tiempo Estimado',
                            icon: Icons.schedule_rounded,
                          ),
                          const SizedBox(height: 16),

                          // Duración
                          _buildDurationField(),

                          const SizedBox(height: 16),

                          // Tiempo de llegada
                          _buildArrivalTimeSection(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sección de Descripción
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Descripción del Trabajo',
                            icon: Icons.description_rounded,
                          ),
                          const SizedBox(height: 16),

                          _buildDescriptionField(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nota informativa
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InfoCard(
                        message: 'El cliente podrá ver todos los detalles antes de aceptar',
                        icon: Icons.info_rounded,
                        color: AppColors.info,
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Botón Flotante de Enviar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendQuotation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 24),
              label: Text(
                _isLoading ? 'Enviando...' : 'Enviar Cotización',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.info.withValues(alpha: 0.15),
            AppColors.info.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Solicitud del Cliente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.serviceRequest.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.serviceRequest.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.build_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.serviceRequest.serviceType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String emoji,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          labelText: '$emoji $label',
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          prefixText: '\$ ',
          prefixStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa el costo';
          }
          final amount = double.tryParse(value);
          if (amount == null || amount < 0) {
            return 'Valor inválido';
          }
          return null;
        },
        onChanged: (_) => _calculateTotal(),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success,
            AppColors.success.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Precio final',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${_totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: TextFormField(
        controller: _durationController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: '⏱️ Duración del Trabajo',
          hintText: '¿Cuánto tiempo tomará?',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: AppColors.info,
              size: 20,
            ),
          ),
          suffixText: 'min',
          suffixStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa la duración';
          }
          final duration = int.tryParse(value);
          if (duration == null || duration <= 0) {
            return 'Valor inválido';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildArrivalTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚗 Tiempo de Llegada',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '¿En cuánto tiempo puedes llegar al lugar?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildArrivalChip('30 min', 0),
            _buildArrivalChip('1 hora', 1),
            _buildArrivalChip('2 horas', 2),
            _buildArrivalChip('3 horas', 3),
            _buildArrivalChip('Mañana', 24),
          ],
        ),
      ],
    );
  }

  Widget _buildArrivalChip(String label, int hours) {
    final isSelected = _selectedArrivalHours == hours;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedArrivalHours = hours;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.warning,
                    AppColors.warning.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.warning
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.small : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.white,
              ),
            if (isSelected) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.white
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 6,
        maxLength: 500,
        decoration: const InputDecoration(
          hintText:
              'Describe brevemente qué harás, qué materiales usarás, tiempo estimado de cada etapa, etc.\n\nEjemplo: "Revisaré el sistema eléctrico, cambiaré cables defectuosos y probaré conexiones. Incluye materiales de calidad certificados."',
          hintStyle: TextStyle(
            fontSize: 13,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Agrega una descripción del trabajo';
          }
          if (value.trim().length < 20) {
            return 'La descripción debe tener al menos 20 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildConfirmationItem(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            fontSize: isTotal ? 20 : 16,
            color: isTotal ? AppColors.success : AppColors.textPrimary,
            letterSpacing: isTotal ? -0.5 : 0,
          ),
        ),
      ],
    );
  }
}