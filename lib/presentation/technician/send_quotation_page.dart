import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';

/// Pantalla para enviar cotización con desglose completo
class SendQuotationPage extends StatefulWidget {
  final ServiceRequestModel serviceRequest;

  const SendQuotationPage({
    super.key,
    required this.serviceRequest,
  });

  @override
  State<SendQuotationPage> createState() => _SendQuotationPageState();
}

class _SendQuotationPageState extends State<SendQuotationPage> {
  final _formKey = GlobalKey<FormState>();
  final _laborCostController = TextEditingController();
  final _materialsCostController = TextEditingController();
  final _durationController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _descriptionController = TextEditingController();

  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();

  bool _isLoading = false;
  double _totalPrice = 0.0;
  int _selectedArrivalHours = 1;

  @override
  void dispose() {
    _laborCostController.dispose();
    _materialsCostController.dispose();
    _durationController.dispose();
    _arrivalTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _arrivalTimeController.text = '1';
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

    // Confirmar envío
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cotización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estás a punto de enviar esta cotización:'),
            const SizedBox(height: 16),
            _buildConfirmationItem(
              'Mano de Obra',
              '\$${_laborCostController.text}',
            ),
            _buildConfirmationItem(
              'Materiales',
              '\$${_materialsCostController.text}',
            ),
            const Divider(),
            _buildConfirmationItem(
              'TOTAL',
              '\$${_totalPrice.toStringAsFixed(2)}',
              isTotal: true,
            ),
            const Divider(),
            _buildConfirmationItem(
              'Duración',
              '${_durationController.text} min',
            ),
            _buildConfirmationItem(
              'Tiempo de llegada',
              '~${_selectedArrivalHours}h',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Enviar Cotización'),
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

      print('📤 [SEND_QUOTATION] Enviando cotización');
      print('   Solicitud: ${widget.serviceRequest.id}');
      print('   Técnico: $technicianId');
      print('   Precio total: \$$_totalPrice');
      print('   Mano de obra: \$${_laborCostController.text}');
      print('   Materiales: \$${_materialsCostController.text}');
      print('   Duración: ${_durationController.text} min');

      // Crear cotización con desglose
      await _quotationsDS.createQuotation(
        serviceRequestId: widget.serviceRequest.id,
        estimatedPrice: _totalPrice,
        laborCost: double.parse(_laborCostController.text),
        materialsCost: double.parse(_materialsCostController.text),
        estimatedDuration: int.parse(_durationController.text),
        estimatedArrivalTime: _selectedArrivalHours,
        description: _descriptionController.text.trim(),
      );

      print('✅ [SEND_QUOTATION] Cotización enviada exitosamente');

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Cotización enviada exitosamente!',
        );
        Navigator.pop(context, true); // Regresar con true
      }
    } catch (e) {
      print('❌ [SEND_QUOTATION] Error: $e');
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

  Widget _buildConfirmationItem(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Cotización'),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info de la solicitud
            _buildRequestInfo(),
            const SizedBox(height: 24),

            // Título de desglose
            const Row(
              children: [
                Icon(Icons.calculate, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Desglose de Costos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mano de obra
            TextFormField(
              controller: _laborCostController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Mano de Obra 💪',
                prefixIcon: const Icon(Icons.build),
                prefixText: '\$ ',
                helperText: 'Costo de tu trabajo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el costo de mano de obra';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Ingresa un valor válido';
                }
                return null;
              },
              onChanged: (_) => _calculateTotal(),
            ),

            const SizedBox(height: 16),

            // Materiales
            TextFormField(
              controller: _materialsCostController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Materiales 🛠️',
                prefixIcon: const Icon(Icons.shopping_cart),
                prefixText: '\$ ',
                helperText: 'Costo de materiales necesarios',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el costo de materiales';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Ingresa un valor válido';
                }
                return null;
              },
              onChanged: (_) => _calculateTotal(),
            ),

            const SizedBox(height: 24),

            // Total
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Precio final',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tiempo estimado
            const Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Tiempo Estimado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duración del trabajo
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Duración del Trabajo ⏱️',
                prefixIcon: const Icon(Icons.access_time),
                suffixText: 'minutos',
                helperText: '¿Cuánto tiempo tomará el trabajo?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa la duración estimada';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'Ingresa un valor válido';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Tiempo de llegada
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo de Llegada 🚗',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿En cuánto tiempo puedes llegar?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildArrivalTimeChip('30 min', 0.5),
                    _buildArrivalTimeChip('1 hora', 1),
                    _buildArrivalTimeChip('2 horas', 2),
                    _buildArrivalTimeChip('3 horas', 3),
                    _buildArrivalTimeChip('Mañana', 24),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Descripción del trabajo
            const Row(
              children: [
                Icon(Icons.description, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Descripción del Trabajo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Describe brevemente qué harás, qué materiales usarás, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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

            const SizedBox(height: 32),

            // Botón enviar
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendQuotation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 24),
              label: Text(
                _isLoading ? 'Enviando...' : 'Enviar Cotización',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Solicitud',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.serviceRequest.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.serviceRequest.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalTimeChip(String label, double hours) {
    final isSelected = _selectedArrivalHours == hours.toInt() ||
        (hours == 0.5 && _selectedArrivalHours == 0);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedArrivalHours = hours == 0.5 ? 0 : hours.toInt();
          });
        }
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }
}