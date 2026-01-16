import 'package:flutter/material.dart';
import '../../data/datasources/quotations_remote_ds.dart';
import '../../data/models/service_request_model.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';

/// Pantalla para enviar cotización
class SendQuotationPage extends StatefulWidget {
  final ServiceRequestModel request;

  const SendQuotationPage({
    super.key,
    required this.request,
  });

  @override
  State<SendQuotationPage> createState() => _SendQuotationPageState();
}

class _SendQuotationPageState extends State<SendQuotationPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final QuotationsRemoteDataSource _quotationsDS = QuotationsRemoteDataSource();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _quotationsDS.createQuotation(
        serviceRequestId: widget.request.id,
        estimatedPrice: double.parse(_priceController.text),
        estimatedDuration: int.parse(_durationController.text),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '¡Cotización enviada! El cliente la revisará pronto.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error al enviar cotización: $e');
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
            // Info del servicio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.request.description),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.request.address,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Formulario de cotización
            Text(
              'Detalles de la Cotización',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio Estimado',
                prefixText: '\$ ',
                hintText: '50.00',
              ),
              validator: Validators.validatePrice,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duración Estimada (minutos)',
                hintText: '120',
              ),
              validator: Validators.validateDuration,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descripción del Trabajo',
                hintText: 'Detalla qué incluye tu servicio...',
                alignLabelWithHint: true,
              ),
              validator: (value) => Validators.validateDescription(value),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _sendQuotation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Enviar Cotización'),
            ),
          ],
        ),
      ),
    );
  }
}