import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final/src/docente/crear_asignatura.dart';
import 'package:proyecto_final/src/docente/clases_asignatura.dart';

const Color kPrimary = Color(0xFF0F263B);
const Color kAccent = Color(0xFF007A78);
const Color kFieldBg = Color(0xFFF2F5F9);

class PanelDocenteScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PanelDocenteScreen({super.key, this.userData});

  @override
  State<PanelDocenteScreen> createState() => _PanelDocenteScreenState();
}

class _PanelDocenteScreenState extends State<PanelDocenteScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _filtroSeleccionado = 0; // 0: Todos, 1: Hoy, 2: Pausados

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _parseColorHex(String? hex) {
    if (hex == null || hex.isEmpty) return kPrimary;
    final cleanHex = hex.replaceAll('#', '');
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    }
    return kPrimary;
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
        return Icons.menu_book_outlined;
    }
  }

  String _obtenerNombreDiaHoy() {
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

  String _obtenerCortoDiaHoy() {
    const cortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return cortos[DateTime.now().weekday - 1];
  }

  String _formatearHora12(String? hora24) {
    if (hora24 == null || !hora24.contains(':')) return '';
    final partes = hora24.split(':');
    final h = int.tryParse(partes[0]) ?? 8;
    final m = partes[1].padLeft(2, '0');
    final periodo = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:$m $periodo';
  }

  String _resumenHorario(List<dynamic>? horarios) {
    if (horarios == null || horarios.isEmpty) {
      return 'Horario pendiente por configurar';
    }
    final diasUnicos = <String>[];
    for (final h in horarios) {
      final dia = (h['dia'] ?? '').toString();
      if (dia.isNotEmpty) {
        final corto = dia.length >= 3 ? dia.substring(0, 3) : dia;
        if (!diasUnicos.contains(corto)) diasUnicos.add(corto);
      }
    }
    final primerSlot = horarios.first as Map<String, dynamic>;
    final inicio = _formatearHora12(primerSlot['horaInicio']?.toString());
    final fin = _formatearHora12(primerSlot['horaFin']?.toString());
    final diasTexto = diasUnicos.join(' y ');
    return '$diasTexto | $inicio - $fin';
  }

  String _resumenSalon(List<dynamic>? horarios) {
    if (horarios == null || horarios.isEmpty) {
      return 'Sin aula asignada';
    }
    final primerSlot = horarios.first as Map<String, dynamic>;
    return (primerSlot['salon'] ?? 'Sin aula asignada').toString();
  }

  bool _tieneClaseHoy(List<dynamic>? horarios) {
    if (horarios == null || horarios.isEmpty) return false;
    final hoy = _obtenerNombreDiaHoy().toLowerCase();
    return horarios.any(
      (h) => (h['dia'] ?? '').toString().toLowerCase() == hoy,
    );
  }

  int _calcularSemanaCiclo() {
    final now = DateTime.now();
    final inicioAnio = DateTime(now.year, 1, 1);
    final dias = now.difference(inicioAnio).inDays;
    return ((dias / 7).floor() % 16) + 1;
  }

  void _mostrarMenuPerfil(
      BuildContext context, String currentNombreCompleto, String email) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: kPrimary),
                  title: const Text('Actualizar Nombre Completo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _mostrarDialogoEditar(
                        context, currentNombreCompleto, email);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text(
                    'Eliminar Cuenta',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmarEliminarCuenta(context, email);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoEditar(
      BuildContext context, String currentNombreCompleto, String email) {
    final nombreCtrl = TextEditingController(text: currentNombreCompleto);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Actualizar Información'),
          content: TextField(
            controller: nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre Completo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoNombre = nombreCtrl.text.trim();
                if (nuevoNombre.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(email)
                      .update({'nombreCompleto': nuevoNombre});

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Información actualizada correctamente')),
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

  Future<void> _eliminarAsignatura(String cursoId, String nombreCurso) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar asignatura'),
        content: Text('¿Deseas eliminar el curso "$nombreCurso"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('asignaturas')
          .doc(cursoId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asignatura eliminada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email ?? '';
    final anioActual = DateTime.now().year;
    final periodoActual = DateTime.now().month <= 6 ? 'I' : 'II';
    final semanaActual = _calcularSemanaCiclo();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: userEmail.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('asignaturas')
                  .where('docenteEmail', isEqualTo: userEmail)
                  .snapshots()
              : null,
          builder: (context, cursosSnapshot) {
            final docs = cursosSnapshot.data?.docs ?? [];

            final cursosOrdenados = [...docs];
            cursosOrdenados.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final tsA = dataA['fechaCreacion'] as Timestamp?;
              final tsB = dataB['fechaCreacion'] as Timestamp?;
              if (tsA == null && tsB == null) return 0;
              if (tsA == null) return 1;
              if (tsB == null) return -1;
              return tsB.compareTo(tsA);
            });

            int cursosActivosCount = 0;
            int cursosPausadosCount = 0;
            int cursosHoyCount = 0;
            int totalEstudiantesGlobal = 0;

            for (final doc in cursosOrdenados) {
              final data = doc.data() as Map<String, dynamic>;
              final activo = data['activo'] ?? true;
              final horarios = data['horarios'] as List<dynamic>?;
              final estudiantes = data['estudiantes'] as List<dynamic>?;
              final cantEst =
                  (data['totalEstudiantes'] as int?) ?? (estudiantes?.length ?? 0);

              totalEstudiantesGlobal += cantEst;
              if (activo == true) {
                cursosActivosCount++;
              } else {
                cursosPausadosCount++;
              }
              if (_tieneClaseHoy(horarios)) {
                cursosHoyCount++;
              }
            }

            final cursosFiltrados = cursosOrdenados.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nombre = (data['nombreCurso'] ?? '').toString().toLowerCase();
              final codigo = (data['codigoSeccion'] ?? '').toString().toLowerCase();
              final horarios = data['horarios'] as List<dynamic>?;
              final salon = _resumenSalon(horarios).toLowerCase();
              final activo = data['activo'] ?? true;

              if (_filtroSeleccionado == 1 && !_tieneClaseHoy(horarios)) {
                return false;
              }
              if (_filtroSeleccionado == 2 && activo == true) {
                return false;
              }

              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                return nombre.contains(q) ||
                    codigo.contains(q) ||
                    salon.contains(q);
              }
              return true;
            }).toList();

            return CustomScrollView(
              slivers: [
                // 1. CABECERA SUPERIOR (LOGO, SALUDO Y BOTÓN SALIR)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: userEmail.isNotEmpty
                          ? FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(userEmail)
                              .snapshots()
                          : null,
                      builder: (context, userSnap) {
                        String nombreMostrar = 'Docente';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final uData =
                              userSnap.data!.data() as Map<String, dynamic>;
                          final raw = (uData['nombreCompleto'] ??
                                  '${uData['nombres'] ?? ''} ${uData['apellidos'] ?? ''}')
                              .toString()
                              .trim();
                          if (raw.isNotEmpty) nombreMostrar = raw;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _mostrarMenuPerfil(
                                      context, nombreMostrar, userEmail),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Image.asset(
                                      'lib/src/img/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.school,
                                          color: kPrimary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRESENTE!',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: kAccent,
                                      ),
                                    ),
                                    Text(
                                      'Cursos',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () async {
                                    await FirebaseAuth.instance.signOut();
                                    if (context.mounted) {
                                      Navigator.pushReplacementNamed(
                                          context, '/');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.logout,
                                            size: 16, color: Color(0xFFB91C1C)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Salir',
                                          style: TextStyle(
                                            fontSize: 13,
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
                            Text(
                              'CICLO ACADÉMICO $anioActual-$periodoActual',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.7,
                                color: kAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '¡Hola, Prof. $nombreMostrar! 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // 2. TARJETA MÉTRICAS GLOBALES
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.trending_up,
                                      color: kAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Métricas Globales',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF99F6E4),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'Semana $semanaActual',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricBox(
                                  icon: Icons.menu_book_outlined,
                                  valor: '$cursosActivosCount',
                                  etiqueta: 'Cursos Activos',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricBox(
                                  icon: Icons.groups_outlined,
                                  valor: '$totalEstudiantesGlobal',
                                  etiqueta: 'Estudiantes',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. BARRA DE BÚSQUEDA Y CHIPS DE FILTRO
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Buscar por materia, código o aula...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey.shade500),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                                  const BorderSide(color: kAccent, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                index: 0,
                                icon: Icons.grid_view_rounded,
                                label: 'Todos (${cursosOrdenados.length})',
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                index: 1,
                                icon: Icons.calendar_today_outlined,
                                label:
                                    'Hoy (${_obtenerCortoDiaHoy()}) ($cursosHoyCount)',
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                index: 2,
                                icon: Icons.pause_circle_outline,
                                label: 'Pausados ($cursosPausadosCount)',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. LISTA DE CURSOS CREADOS POR EL DOCENTE
                if (cursosSnapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    ),
                  )
                else if (cursosFiltrados.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined,
                              size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            cursosOrdenados.isEmpty
                                ? 'Aún no has creado asignaturas'
                                : 'No hay cursos que coincidan con el filtro',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cursosOrdenados.isEmpty
                                ? 'Presiona el botón "+ Crear Nuevo Curso" para registrar tu primera materia.'
                                : 'Intenta cambiar el término de búsqueda o seleccionar otra pestaña.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = cursosFiltrados[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildCursoCard(doc.id, data);
                        },
                        childCount: cursosFiltrados.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      // BOTÓN FLOTANTE "Crear Nuevo Curso"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearAsignaturaScreen(),
            ),
          );
        },
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Crear Nuevo Curso',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String valor,
    required String etiqueta,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: kFieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: kPrimary, size: 22),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final seleccionado = _filtroSeleccionado == index;
    return GestureDetector(
      onTap: () => setState(() => _filtroSeleccionado = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: seleccionado ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? kPrimary : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: seleccionado ? Colors.white : kPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: seleccionado ? Colors.white : kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursoCard(String cursoId, Map<String, dynamic> data) {
    final nombreCurso = (data['nombreCurso'] ?? 'Sin nombre').toString();
    final codigoSeccion = (data['codigoSeccion'] ?? '').toString().trim();
    final colorBorde = _parseColorHex(data['colorHex']?.toString());
    final icono = _getIconoPorNombre(data['icono']?.toString());
    final estudiantes = data['estudiantes'] as List<dynamic>?;
    final totalEstudiantes =
        (data['totalEstudiantes'] as int?) ?? (estudiantes?.length ?? 0);
    final horarios = data['horarios'] as List<dynamic>?;
    final activo = data['activo'] ?? true;
    final esHoy = _tieneClaseHoy(horarios);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClasesAsignaturaScreen(
              cursoId: cursoId,
              cursoData: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: colorBorde, width: 6),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FILA SUPERIOR: ÍCONO, BADGE CÓDIGO, ESTUDIANTES Y MENÚ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kFieldBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icono, color: colorBorde, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (codigoSeccion.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0ECFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    codigoSeccion,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              Text(
                                '$totalEstudiantes Estudiantes',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (esHoy && activo == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF99F6E4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 8, color: kAccent),
                                  SizedBox(width: 5),
                                  Text(
                                    'Clase programada hoy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      onSelected: (opcion) {
                        if (opcion == 'eliminar') {
                          _eliminarAsignatura(cursoId, nombreCurso);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Eliminar curso',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // NOMBRE DE LA ASIGNATURA
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Text(
                    nombreCurso,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // CAJA DE HORARIO Y SALÓN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kFieldBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _resumenHorario(horarios),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.meeting_room_outlined,
                              size: 16, color: kAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _resumenSalon(horarios),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // INTERRUPTOR CURSO ACTIVO / PAUSADO
                Row(
                  children: [
                    Switch(
                      value: activo == true,
                      activeTrackColor: kAccent,
                      onChanged: (nuevoEstado) async {
                        await FirebaseFirestore.instance
                            .collection('asignaturas')
                            .doc(cursoId)
                            .update({'activo': nuevoEstado});
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activo == true ? 'Curso Activo' : 'Curso Pausado',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: activo == true ? kPrimary : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}