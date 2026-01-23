import 'package:flutter/material.dart';
import '../../data/datasources/profiles_remote_ds.dart';
import '../../data/models/profile_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _pendingVerifications = 0;
  int _totalRequests = 0;
  int _activeRequests = 0;
  bool _isLoading = true;
  List<ProfileModel> _pendingTechnicians = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final profilesDS = ProfilesRemoteDataSource();
      final pending = await profilesDS.getPendingVerifications();
      
      // TODO: Obtener estadísticas de solicitudes
      
      setState(() {
        _pendingVerifications = pending.length;
        _pendingTechnicians = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Estadísticas Generales',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Verificaciones\nPendientes',
                          _pendingVerifications.toString(),
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Solicitudes\nActivas',
                          _activeRequests.toString(),
                          Icons.work,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total\nSolicitudes',
                          _totalRequests.toString(),
                          Icons.list_alt,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Usuarios\nActivos',
                          '0',
                          Icons.people,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  // 🆕 SECCIÓN DE TÉCNICOS PENDIENTES
                  const SizedBox(height: 32),
                  Text(
                    'Técnicos Pendientes de Aprobación',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_pendingTechnicians.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No hay técnicos pendientes de aprobación',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingTechnicians.length,
                      itemBuilder: (context, index) {
                        final technician = _pendingTechnicians[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Text(
                                technician.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              technician.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(technician.email),
                                const SizedBox(height: 4),
                                Text('Teléfono: ${technician.phone ?? "No proporcionado"}'),
                                
                                // 🆕 MOSTRAR ESPECIALIDADES
                                if (technician.specialties != null && 
                                    technician.specialties!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Icon(Icons.work_outline, size: 14, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text(
                                        'Especialidades:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: technician.specialties!.map((specialty) {
                                      return Chip(
                                        label: Text(
                                          specialty,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.orange.shade100,
                                        labelStyle: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}