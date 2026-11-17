import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tomar_asistencia.dart';

typedef RegistroCurso = Map<String, dynamic>;
typedef MapaClasesCurso = Map<String, List<QueryDocumentSnapshot>>;

const Color kPrimary = Color(0xFF0F263B);
const Color kAccent = Color(0xFF007A78);
const Color kMint = Color(0xFF5EEAD4);
const Color kFieldBg = Color(0xFFF2F5F9);

class PanelEstudianteScreen extends StatefulWidget {
  final RegistroCurso? userData;

  const PanelEstudianteScreen({super.key, this.userData});

  @override
  State<PanelEstudianteScreen> createState() => _PanelEstudianteScreenState();
}

class _PanelEstudianteScreenState extends State<PanelEstudianteScreen> {
  int _tabFiltro = 0; // 0: Todos mis cursos, 1: Hoy, 2: Por evaluar

  String _obtenerDiaHoy() {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return dias[DateTime.now().weekday - 1];
  }

  String _formatearHora12(String? hora24) {
    if (hora24 == null || !hora24.contains(':')) return '08:00 AM';
    final partes = hora24.split(':');
    final h = int.tryParse(partes[0]) ?? 8;
    final m = partes[1].padLeft(2, '0');
    final periodo = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:$m $periodo';
  }

  IconData _getIconoPorNombre(String? nombreIcono) {
    switch (nombreIcono) {
      case 'psychology':
        return Icons.psychology_outlined;
      case 'code':
        return Icons.code;
      case 'terminal':
        return Icons.terminal;
      case 'biotech':
        return Icons.biotech_outlined;
      case 'calculate':
        return Icons.calculate_outlined;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      default:
        return Icons.calculate_outlined;
    }
  }

  bool _tieneClaseHoy(RegistroCurso cursoData) {
    final horarios = (cursoData['horarios'] as List<dynamic>?) ?? [];
    final hoy = _obtenerDiaHoy().toLowerCase();
    for (final h in horarios) {
      if ((h['dia'] ?? '').toString().toLowerCase() == hoy) {
        return true;
      }
    }
    return false;
  }

  String _obtenerTextoProximaClase(RegistroCurso cursoData) {
    final horarios = (cursoData['horarios'] as List<dynamic>?) ?? [];
    if (horarios.isEmpty) return 'Sin horario asignado';

    final hoy = _obtenerDiaHoy().toLowerCase();
    for (final h in horarios) {
      if ((h['dia'] ?? '').toString().toLowerCase() == hoy) {
        final hora = _formatearHora12(h['horaInicio']?.toString());
        final salon = (h['salon'] ?? 'Aula').toString();
        return 'Próxima clase hoy $hora ($salon)';
      }
    }

    final primero = horarios.first as RegistroCurso;
    final dia = (primero['dia'] ?? 'Próxima sesión').toString();
    final hora = _formatearHora12(primero['horaInicio']?.toString());
    final salon = (primero['salon'] ?? 'Aula').toString();
    return 'Próxima clase: $dia $hora ($salon)';
  }

  void _mostrarOpcionesPerfil(
    BuildContext context,
    String currentNombres,
    String currentApellidos,
    String email,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Configuración de Perfil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.edit, color: kAccent, size: 20),
                ),
                title: const Text(
                  'Actualizar Información',
                  style: TextStyle(fontWeight: FontWeight.w600, color: kPrimary),
                ),
                subtitle: const Text('Editar nombres y apellidos'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _mostrarDialogoEditar(
                      context, currentNombres, currentApellidos, email);
                },
              ),
              const Divider(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.delete_forever,
                      color: Colors.redAccent, size: 20),
                ),
                title: const Text(
                  'Eliminar Cuenta',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.redAccent),
                ),
                subtitle: const Text('Borrar permanentemente tus datos'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmarEliminarCuenta(context, email);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoEditar(
    BuildContext context,
    String currentNombres,
    String currentApellidos,
    String email,
  ) {
    final nombresCtrl = TextEditingController(text: currentNombres);
    final apellidosCtrl = TextEditingController(text: currentApellidos);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Actualizar Información',
            style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
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
                    'nombreCompleto': '$nuevosNombres $nuevosApellidos',
                  });

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Información actualizada correctamente'),
                        backgroundColor: Colors.green,
                      ),
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

  void _confirmarEliminarCuenta(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(email)
                      .delete();
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
                      msg =
                          'Por seguridad, debes haber iniciado sesión recientemente para realizar esta acción.';
                    }
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = (currentUser?.email ?? '').toLowerCase();
    final anioActual = DateTime.now().year;
    final periodoActual = DateTime.now().month <= 6 ? '1' : '2';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: userEmail.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userEmail)
                  .snapshots()
              : null,
          builder: (context, userSnap) {
            String nombres = widget.userData?['nombres'] ?? '';
            String apellidos = widget.userData?['apellidos'] ?? '';
            String fotoUrl = widget.userData?['fotoUrl'] ?? '';

            if (userSnap.hasData && userSnap.data!.exists) {
              final data = userSnap.data!.data() as RegistroCurso;
              nombres = (data['nombres'] ?? '').toString();
              apellidos = (data['apellidos'] ?? '').toString();
              fotoUrl = (data['fotoUrl'] ?? '').toString();
            }

            final nombreMostrar = '$nombres $apellidos'.trim().isEmpty
                ? 'Estudiante'
                : '$nombres $apellidos'.trim();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('asignaturas')
                  .where('estudiantes', arrayContains: userEmail)
                  .snapshots(),
              builder: (context, cursosSnap) {
                final cursosDocs = cursosSnap.data?.docs ?? [];

                return _ContenidoEstudianteConEstadisticas(
                  userEmail: userEmail,
                  nombreMostrar: nombreMostrar,
                  nombres: nombres,
                  apellidos: apellidos,
                  fotoUrl: fotoUrl,
                  semestreTexto: 'SEMESTRE $anioActual-$periodoActual',
                  cursosDocs: cursosDocs,
                  tabFiltro: _tabFiltro,
                  onTabChanged: (idx) => setState(() => _tabFiltro = idx),
                  onAbrirPerfil: () => _mostrarOpcionesPerfil(
                      context, nombres, apellidos, userEmail),
                  tieneClaseHoy: _tieneClaseHoy,
                  obtenerTextoProximaClase: _obtenerTextoProximaClase,
                  getIconoPorNombre: _getIconoPorNombre,
                  onRegistrarAsistencia: ({
                    required String cursoId,
                    required String nombreCurso,
                    required String claseDocId,
                    required RegistroCurso claseData,
                  }) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TomarAsistenciaScreen(
                          cursoId: cursoId,
                          nombreCurso: nombreCurso,
                          claseDocId: claseDocId,
                          claseData: claseData,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET QUE ESCUCHA LAS CLASES DE LOS CURSOS MATRICULADOS EN TIEMPO REAL
// ============================================================================

class _ContenidoEstudianteConEstadisticas extends StatelessWidget {
  final String userEmail;
  final String nombreMostrar;
  final String nombres;
  final String apellidos;
  final String fotoUrl;
  final String semestreTexto;
  final List<QueryDocumentSnapshot> cursosDocs;
  final int tabFiltro;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAbrirPerfil;
  final bool Function(RegistroCurso) tieneClaseHoy;
  final String Function(RegistroCurso) obtenerTextoProximaClase;
  final IconData Function(String?) getIconoPorNombre;
  final Future<void> Function({
    required String cursoId,
    required String nombreCurso,
    required String claseDocId,
    required RegistroCurso claseData,
  }) onRegistrarAsistencia;

  const _ContenidoEstudianteConEstadisticas({
    required this.userEmail,
    required this.nombreMostrar,
    required this.nombres,
    required this.apellidos,
    required this.fotoUrl,
    required this.semestreTexto,
    required this.cursosDocs,
    required this.tabFiltro,
    required this.onTabChanged,
    required this.onAbrirPerfil,
    required this.tieneClaseHoy,
    required this.obtenerTextoProximaClase,
    required this.getIconoPorNombre,
    required this.onRegistrarAsistencia,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('clases').snapshots(),
      builder: (context, todasClasesSnap) {
        final misCursosIds = cursosDocs.map((d) => d.id).toSet();
        final MapaClasesCurso clasesPorCurso = {};

        for (final id in misCursosIds) {
          clasesPorCurso[id] = [];
        }

        if (todasClasesSnap.hasData) {
          for (final doc in todasClasesSnap.data!.docs) {
            final cursoPadreId = doc.reference.parent.parent?.id;
            if (cursoPadreId != null && misCursosIds.contains(cursoPadreId)) {
              clasesPorCurso[cursoPadreId]!.add(doc);
            }
          }
        }

        int totalClasesGlobales = 0;
        int totalAsistidasGlobales = 0;
        int cursosConClaseActivaSinMarcar = 0;
        int cursosHoyCount = 0;

        String tituloProximaSesion = 'Sin sesiones activas hoy';
        String subtituloProximaSesion = 'Revisa tus horarios matriculados';
        bool haySesionActivaBanner = false;

        final List<RegistroCurso> infoCursos = [];

        for (final cursoDoc in cursosDocs) {
          final cData = cursoDoc.data() as RegistroCurso;
          final clases = clasesPorCurso[cursoDoc.id] ?? [];

          int asistidasCurso = 0;
          QueryDocumentSnapshot? claseActiva;

          for (final cl in clases) {
            final clData = cl.data() as RegistroCurso;
            final presentes = (clData['presentes'] as List<dynamic>?) ?? [];
            final presentesLower =
                presentes.map((e) => e.toString().toLowerCase()).toList();
            if (presentesLower.contains(userEmail)) {
              asistidasCurso++;
            }
            if ((clData['estado'] ?? '') == 'activa' && claseActiva == null) {
              claseActiva = cl;
            }
          }

          totalClasesGlobales += clases.length;
          totalAsistidasGlobales += asistidasCurso;

          final esHoy = tieneClaseHoy(cData);
          if (esHoy) cursosHoyCount++;

          bool yaMarcoActiva = false;
          if (claseActiva != null) {
            final actData = claseActiva.data() as RegistroCurso;
            final pres = (actData['presentes'] as List<dynamic>?) ?? [];
            yaMarcoActiva = pres
                .map((e) => e.toString().toLowerCase())
                .contains(userEmail);
            if (!yaMarcoActiva) {
              cursosConClaseActivaSinMarcar++;
            }

            if (!haySesionActivaBanner) {
              haySesionActivaBanner = true;
              final horaIni = (actData['horaInicio'] ?? '08:00 AM').toString();
              final aula = (actData['aula'] ?? 'Aula asignada').toString();
              tituloProximaSesion =
                  '${cData['nombreCurso'] ?? 'Curso'} • $horaIni';
              subtituloProximaSesion = aula;
            }
          }

          infoCursos.add({
            'doc': cursoDoc,
            'data': cData,
            'totalClases': clases.length,
            'asistidas': asistidasCurso,
            'claseActiva': claseActiva,
            'yaMarcoActiva': yaMarcoActiva,
            'esHoy': esHoy,
          });
        }

        if (!haySesionActivaBanner && infoCursos.isNotEmpty) {
          final cursoHoy = infoCursos.firstWhere(
            (e) => e['esHoy'] == true,
            orElse: () => infoCursos.first,
          );
          final cData = cursoHoy['data'] as RegistroCurso;
          final horarios = (cData['horarios'] as List<dynamic>?) ?? [];
          if (horarios.isNotEmpty) {
            final h = horarios.first as RegistroCurso;
            final salon = (h['salon'] ?? 'Aula asignada').toString();
            tituloProximaSesion =
                '${cData['nombreCurso'] ?? 'Curso'} • ${h['horaInicio'] ?? '08:00'}';
            subtituloProximaSesion = salon;
          }
        }

        final porcentajeGlobal = totalClasesGlobales > 0
            ? ((totalAsistidasGlobales / totalClasesGlobales) * 100).round()
            : 100;

        String textoCumplimiento = 'Excelente cumplimiento';
        if (porcentajeGlobal < 75) {
          textoCumplimiento = 'Riesgo de inasistencia';
        } else if (porcentajeGlobal < 85) {
          textoCumplimiento = 'Buen cumplimiento';
        }

        final cursosFiltrados = infoCursos.where((item) {
          if (tabFiltro == 1) return item['esHoy'] == true;
          if (tabFiltro == 2) {
            return item['claseActiva'] != null && item['yaMarcoActiva'] == false;
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BARRA SUPERIOR (Logo + PRESENTE! Cursos + Cerrar Sesión)
              Row(
                children: [
                  Image.asset(
                    'lib/src/img/logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.school, color: kPrimary, size: 26),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRESENTE!',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: kAccent,
                          ),
                        ),
                        Text(
                          'Cursos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout,
                              size: 15, color: Color(0xFFB91C1C)),
                          SizedBox(width: 5),
                          Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. SALUDO + AVATAR CON INDICADOR + CAMPANA
              Row(
                children: [
                  GestureDetector(
                    onTap: onAbrirPerfil,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: fotoUrl.isNotEmpty
                              ? NetworkImage(fotoUrl)
                              : null,
                          child: fotoUrl.isEmpty
                              ? const Icon(Icons.person,
                                  color: kPrimary, size: 26)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: kAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: onAbrirPerfil,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            semestreTexto,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: kAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '¡Hola, $nombreMostrar!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none,
                              color: kPrimary, size: 22),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  cursosConClaseActivaSinMarcar > 0
                                      ? 'Tienes $cursosConClaseActivaSinMarcar clase(s) abierta(s) para marcar asistencia.'
                                      : 'No tienes asistencias pendientes en este momento.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (cursosConClaseActivaSinMarcar > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$cursosConClaseActivaSinMarcar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. TARJETA OSCURA "DESEMPEÑO GLOBAL"
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DESEMPEÑO GLOBAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '$porcentajeGlobal%',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'asistencia\nsemestral',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified,
                                  color: kMint, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                textoCumplimiento.replaceFirst(' ', '\n'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (porcentajeGlobal / 100).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(kMint),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.access_time,
                                color: kPrimary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  haySesionActivaBanner
                                      ? 'Sesión en vivo ahora'
                                      : 'Próxima sesión en vivo',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: kMint,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tituloProximaSesion,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.location_city,
                                        size: 12, color: Colors.white60),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        subtituloProximaSesion,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. PESTAÑAS DE FILTRO (Todos mis cursos, Hoy, Por evaluar)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                        0, 'Todos mis cursos (${infoCursos.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Hoy ($cursosHoyCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Por evaluar'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. TARJETAS DE ASIGNATURAS MATRICULADAS
              if (cursosFiltrados.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 44, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        infoCursos.isEmpty
                            ? 'Aún no estás matriculado en ninguna asignatura.'
                            : 'No hay cursos que coincidan con este filtro.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...cursosFiltrados.map((item) {
                  final cursoDoc = item['doc'] as QueryDocumentSnapshot;
                  final cData = item['data'] as RegistroCurso;
                  final totalClases = item['totalClases'] as int;
                  final asistidas = item['asistidas'] as int;
                  final claseActiva =
                      item['claseActiva'] as QueryDocumentSnapshot?;
                  final yaMarcoActiva = item['yaMarcoActiva'] as bool;

                  final nombreCurso =
                      (cData['nombreCurso'] ?? 'Asignatura').toString();
                  final docenteNombre =
                      (cData['docenteNombre'] ?? 'Docente asignado').toString();
                  final icono = getIconoPorNombre(cData['icono']?.toString());
                  final porcentajeCurso = totalClases > 0
                      ? ((asistidas / totalClases) * 100).round()
                      : 100;

                  if (claseActiva != null) {
                    final actData = claseActiva.data() as RegistroCurso;
                    return _buildTarjetaCursoAbierta(
                      cursoId: cursoDoc.id,
                      nombreCurso: nombreCurso,
                      docenteNombre: docenteNombre,
                      icono: icono,
                      asistidas: asistidas,
                      totalClases: totalClases,
                      porcentajeCurso: porcentajeCurso,
                      claseActivaId: claseActiva.id,
                      claseActivaData: actData,
                      yaMarcoActiva: yaMarcoActiva,
                    );
                  }

                  return _buildTarjetaCursoCerrada(
                    nombreCurso: nombreCurso,
                    docenteNombre: docenteNombre,
                    icono: icono,
                    proximaClaseTexto: obtenerTextoProximaClase(cData),
                    asistidas: asistidas,
                    totalClases: totalClases,
                    porcentajeCurso: porcentajeCurso,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final activo = tabFiltro == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: activo ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? kPrimary : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: activo ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaCursoAbierta({
    required String cursoId,
    required String nombreCurso,
    required String docenteNombre,
    required IconData icono,
    required int asistidas,
    required int totalClases,
    required int porcentajeCurso,
    required String claseActivaId,
    required RegistroCurso claseActivaData,
    required bool yaMarcoActiva,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: kPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreCurso,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      docenteNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner "¡Asistencia Abierta!"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: kAccent),
                    SizedBox(width: 8),
                    Text(
                      '¡Asistencia Abierta!',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: kAccent,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Clase ${claseActivaData['numeroClase'] ?? 1} en vivo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Asistencia acumulada: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    TextSpan(
                      text: '$porcentajeCurso%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$asistidas / $totalClases clases',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botón oscuro "Registrar Mi Asistencia Ahora ->"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: yaMarcoActiva ? kAccent : kPrimary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () => onRegistrarAsistencia(
                cursoId: cursoId,
                nombreCurso: nombreCurso,
                claseDocId: claseActivaId,
                claseData: claseActivaData,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    yaMarcoActiva
                        ? Icons.check_circle
                        : Icons.location_on_outlined,
                    size: 19,
                    color: kMint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    yaMarcoActiva
                        ? 'Asistencia Registrada • Ver Detalles'
                        : 'Registrar Mi Asistencia Ahora',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!yaMarcoActiva) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 17),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaCursoCerrada({
    required String nombreCurso,
    required String docenteNombre,
    required IconData icono,
    required String proximaClaseTexto,
    required int asistidas,
    required int totalClases,
    required int porcentajeCurso,
  }) {
    final progreso = totalClases > 0 ? (asistidas / totalClases) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kFieldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: kPrimary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreCurso,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      docenteNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: kFieldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Cerrada',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: kFieldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    proximaClaseTexto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Récord personal: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    TextSpan(
                      text: '$porcentajeCurso%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$asistidas / $totalClases clases',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
            ),
          ),
        ],
      ),
    );
  }
}