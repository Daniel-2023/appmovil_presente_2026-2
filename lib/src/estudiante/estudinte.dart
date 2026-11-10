import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanelEstudianteScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const PanelEstudianteScreen({super.key, this.userData});

  // Método para actualizar Nombres y Apellidos en Firestore
  void _mostrarDialogoEditar(BuildContext context, String currentNombres, String currentApellidos, String email) {
    final nombresCtrl = TextEditingController(text: currentNombres);
    final apellidosCtrl = TextEditingController(text: currentApellidos);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Actualizar Información'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombresCtrl,
                decoration: const InputDecoration(labelText: 'Nombres'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: apellidosCtrl,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevosNombres = nombresCtrl.text.trim();
                final nuevosApellidos = apellidosCtrl.text.trim();

                if (nuevosNombres.isNotEmpty && nuevosApellidos.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(email)
                      .update({
                    'nombres': nuevosNombres,
                    'apellidos': nuevosApellidos,
                  });

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Información actualizada correctamente')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Método para eliminar usuario de Firestore y Firebase Auth
  void _confirmarEliminarCuenta(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Cuenta'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción borrará tus datos y no se podrá deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;

                  // 1. Borrar documento en Firestore
                  await FirebaseFirestore.instance.collection('usuarios').doc(email).delete();

                  // 2. Borrar usuario en Firebase Auth
                  await user?.delete();

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    Navigator.pushReplacementNamed(context, '/');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cuenta eliminada con éxito')),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    String msg = 'Error al eliminar la cuenta';
                    if (e.code == 'requires-recent-login') {
                      msg = 'Por seguridad, debes haber iniciado sesión recientemente para realizar esta acción.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F263B);
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Estudiante'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carga dinámica mediante StreamBuilder
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                String nombres = '';
                String apellidos = '';
                String nombreMostrar = 'Cargando...';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  nombres = data['nombres'] ?? '';
                  apellidos = data['apellidos'] ?? '';
                  nombreMostrar = '$nombres $apellidos'.trim();
                  if (nombreMostrar.isEmpty) nombreMostrar = 'Estudiante';
                }

                return Card(
                  color: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Hola, $nombreMostrar!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userEmail,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _mostrarDialogoEditar(context, nombres, apellidos, userEmail),
                              icon: const Icon(Icons.edit, color: Colors.amber, size: 18),
                              label: const Text('Actualizar Info', style: TextStyle(color: Colors.amber)),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _confirmarEliminarCuenta(context, userEmail),
                              icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                              label: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Resumen de Asistencias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatCard('Asistencias', '92%', Colors.green),
                const SizedBox(width: 10),
                _buildStatCard('Faltas', '3', Colors.redAccent),
                const SizedBox(width: 10),
                _buildStatCard('Retardos', '2', Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Registro Reciente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Matemáticas Aplicadas'),
                    subtitle: Text('Hoy - 08:00 AM'),
                    trailing: Text(
                      'A tiempo',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.warning, color: Colors.orange),
                    title: Text('Física II'),
                    subtitle: Text('Ayer - 10:15 AM'),
                    trailing: Text(
                      'Retardo',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title: Text('Programación Móvil'),
                    subtitle: Text('04 Oct - 12:00 PM'),
                    trailing: Text(
                      'Falta',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
