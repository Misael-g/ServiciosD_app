import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/config/supabase_config.dart';

/// Pantalla para enviar cotización (técnico)
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
  final _descriptionController = TextEditingController();

  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();

  bool _isLoading = false;
  double _totalPrice = 0.0;

  @override
  void dispose() {
    _laborCostController.dispose();
    _materialsCostController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
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
        'El precio total debe ser mayor a 0',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final technicianId = SupabaseConfig.currentUserId;
      if (technicianId == null) {
        throw Exception('No se pudo obtener el ID del técnico');
      }

      // Crear cotización
      await _quotationsDS.createQuotation(
        serviceRequestId: widget.serviceRequest.id,
        estimatedPrice: _totalPrice,
        estimatedDuration: int.parse(_durationController.text),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Cotización enviada exitosamente!',
        );
        Navigator.pop(context, true); // Regresar con true
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Cotización'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info de la solicitud
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Solicitud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.serviceRequest.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.serviceRequest.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Título de desglose
            const Text(
              'Desglose de Costos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Mano de obra
            TextFormField(
              controller: _laborCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Mano de Obra',
                prefixIcon: Icon(Icons.build),
                prefixText: '\$ ',
                helperText: 'Costo de tu trabajo',
              ),
              validator: (value) => Validators.validateRequired(value, 'Mano de Obra'),
              onChanged: (_) => _calculateTotal(),
            ),

            const SizedBox(height: 16),

            // Materiales
            TextFormField(
              controller: _materialsCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Materiales',
                prefixIcon: Icon(Icons.shopping_cart),
                prefixText: '\$ ',
                helperText: 'Costo de materiales necesarios',
              ),
              validator: (value) => Validators.validateRequired(value, 'Materiales'),
              onChanged: (_) => _calculateTotal(),
            ),

            const SizedBox(height: 24),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PRECIO TOTAL',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '\$${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Duración estimada
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Duración Estimada',
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'minutos',
                helperText: 'Tiempo que tardarás en completar el trabajo',
              ),
              validator: (value) => Validators.validateRequired(value, 'Duración'),
            ),

            const SizedBox(height: 16),

            // Descripción del trabajo
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Descripción del Trabajo',
                hintText: 'Explica qué incluye tu servicio y cómo resolverás el problema...',
                alignLabelWithHint: true,
                helperText: 'Describe lo que harás para resolver el problema',
              ),
              validator: (value) => Validators.validateRequired(value, 'Descripción'),
            ),

            const SizedBox(height: 24),

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
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Enviando...' : 'Enviar Cotización'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nota informativa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El cliente podrá ver tu cotización y compararla con otras. '
                      'Asegúrate de ser competitivo y detallado.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}