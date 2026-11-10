import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanelDocenteScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const PanelDocenteScreen({super.key, this.userData});

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

                  // Imprime en la consola los cambios realizados
                  print('====================================================');
                  print(' DATOS DE DOCENTE ACTUALIZADOS EN FIRESTORE');
                  print(' Correo: $email');
                  print(' Nombre Anterior: $currentNombres $currentApellidos');
                  print(' Nuevo Nombre: $nuevosNombres $nuevosApellidos');
                  print('====================================================');

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
                  final uidEliminado = user?.uid;

                  // 1. Borrar documento en Firestore
                  await FirebaseFirestore.instance.collection('usuarios').doc(email).delete();

                  // 2. Borrar usuario en Firebase Auth
                  await user?.delete();

                  // Imprime en la consola la confirmación de eliminación
                  print('====================================================');
                  print(' CUENTA DE DOCENTE ELIMINADA');
                  print(' Correo eliminado: $email');
                  print(' UID eliminado: $uidEliminado');
                  print('====================================================');

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
        title: const Text('Panel de Docente'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              print('====================================================');
              print('🚪 SESIÓN CERRADA: $userEmail');
              print('====================================================');
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
            // Carga de datos personales del docente desde Firestore
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
                  if (nombreMostrar.isEmpty) nombreMostrar = 'Docente';
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
                              child: Icon(Icons.person_outline,
                                  color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Bienvenido(a), $nombreMostrar!',
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
              'Gestión de Clases',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatCard('Grupos', '4', Colors.blue),
                const SizedBox(width: 10),
                _buildStatCard('Alumnos', '128', Colors.indigo),
                const SizedBox(width: 10),
                _buildStatCard('Reportes', '5', Colors.amber.shade800),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Asignaturas Asignadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                children: [
                  Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF3F8),
                        child: Icon(Icons.class_outlined, color: primaryColor),
                      ),
                      title: const Text(
                        'Programación Móvil',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Grupo A • 32 Alumnos'),
                      trailing: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tomar Lista'),
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF3F8),
                        child: Icon(Icons.class_outlined, color: primaryColor),
                      ),
                      title: const Text(
                        'Bases de Datos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Grupo B • 28 Alumnos'),
                      trailing: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tomar Lista'),
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