import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/verification_states.dart';
import '../../domain/repositories/auth_repository.dart';
import 'role_selection_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final String? selectedRole;

  const RegisterPage({
    super.key,
    this.selectedRole,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedRole;

  // 🆕 Especialidades para técnicos
  final List<String> _availableSpecialties = [
    'Electricista',
    'Plomero',
    'Carpintero',
    'Pintor',
    'Mecánico',
    'Jardinero',
    'Limpieza',
    'Reparación de Electrodomésticos',
    'Instalación de TV/Internet',
    'Aire Acondicionado',
    'Cerrajero',
    'Albañil',
  ];
  final List<String> _selectedSpecialties = [];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null) {
      SnackbarHelper.showError(context, 'Selecciona un rol');
      return;
    }

    // 🆕 Validar especialidades para técnicos
    if (_selectedRole == UserRoles.technician && _selectedSpecialties.isEmpty) {
      SnackbarHelper.showError(
        context,
        'Selecciona al menos una especialidad',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 [REGISTER] Iniciando registro');
      print('   Email: ${_emailController.text.trim()}');
      print('   Nombre: ${_fullNameController.text.trim()}');
      print('   Rol: $_selectedRole');
      print('   Teléfono: ${_phoneController.text.trim()}');
      if (_selectedRole == UserRoles.technician) {
        print('   Especialidades: $_selectedSpecialties');
      }
      
      final authRepository = context.read<AuthRepository>();
      
      await authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole!,
        phone: _phoneController.text.trim().isEmpty
            ? null 
            : _phoneController.text.trim(),
        specialties: _selectedRole == UserRoles.technician // 🆕 AGREGAR
            ? _selectedSpecialties
            : null,
      );

      print('✅ [REGISTER] Registro exitoso');

      if (mounted) {
        final message = _selectedRole == UserRoles.technician
            ? '¡Cuenta creada! Tu solicitud está pendiente de aprobación.'
            : '¡Cuenta creada! Revisa tu email para confirmar.';
            
        SnackbarHelper.showSuccess(context, message);
        
        // Volver al login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
      
    } catch (e) {
      print('❌ [REGISTER] Error: $e');
      
      if (mounted) {
        String errorMessage = 'Error al registrar: ';
        
        // Mejorar mensajes de error
        if (e.toString().contains('User already registered') || 
            e.toString().contains('already been registered')) {
          errorMessage = 'Este email ya está registrado. Intenta iniciar sesión.';
        } else if (e.toString().contains('Invalid email')) {
          errorMessage = 'Email inválido';
        } else if (e.toString().contains('Password')) {
          errorMessage = 'La contraseña debe tener al menos 6 caracteres';
        } else {
          errorMessage += e.toString().replaceAll('Exception: ', '');
        }
        
        SnackbarHelper.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTechnician = _selectedRole == UserRoles.technician;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicador de rol seleccionado
                if (_selectedRole != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedRole == UserRoles.client
                          ? Colors.blue[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedRole == UserRoles.client
                              ? Icons.person
                              : Icons.build,
                          color: _selectedRole == UserRoles.client
                              ? Colors.blue
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Registrándote como ${UserRoles.getDisplayName(_selectedRole!)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedRole == UserRoles.client
                                  ? Colors.blue[900]
                                  : Colors.orange[900],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const RoleSelectionPage(),
                                    ),
                                  );
                                },
                          child: const Text('Cambiar'),
                        ),
                      ],
                    ),
                  ),
                
                if (_selectedRole == null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RoleSelectionPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Seleccionar Rol'),
                  ),
                
                const SizedBox(height: 24),

                // Campo nombre completo
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Validators.validateFullName,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Campo email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Campo teléfono
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isTechnician ? 'Teléfono *' : 'Teléfono',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    helperText: isTechnician ? 'Obligatorio para técnicos' : null,
                  ),
                  validator: isTechnician
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El teléfono es obligatorio para técnicos';
                          }
                          return Validators.validatePhone(value);
                        }
                      : Validators.validatePhone,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Campo contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: Validators.validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Campo confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) => Validators.validatePasswordConfirmation(
                    value,
                    _passwordController.text,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // 🆕 ESPECIALIDADES (Solo para técnicos)
                if (isTechnician) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.work_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Especialidades *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona tus áreas de especialidad. Esto ayudará a los clientes a encontrarte.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                        if (_selectedSpecialties.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '⚠️ Debes seleccionar al menos una',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chips de especialidades
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSpecialties.map((specialty) {
                      final isSelected = _selectedSpecialties.contains(specialty);

                      return FilterChip(
                        label: Text(specialty),
                        selected: isSelected,
                        onSelected: _isLoading
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSpecialties.add(specialty);
                                  } else {
                                    _selectedSpecialties.remove(specialty);
                                  }
                                });
                              },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.orange.shade100,
                        checkmarkColor: Colors.orange.shade900,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.orange.shade900
                              : Colors.grey.shade700,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  if (_selectedSpecialties.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Has seleccionado ${_selectedSpecialties.length} especialidad(es)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],

                // Información para técnicos
                if (isTechnician)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Verificación de Técnico',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Después de registrarte, deberás subir los siguientes documentos:\n'
                          '• Cédula de identidad (frontal y posterior)\n'
                          '• Certificado profesional o técnico\n\n'
                          'Solo podrás enviar cotizaciones una vez que tu perfil sea verificado.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),

                // Botón de registro
                ElevatedButton(
                  onPressed: _isLoading || _selectedRole == null
                      ? null
                      : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Crear Cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}