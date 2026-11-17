import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

typedef InfoEstudiante = Map<String, String>;
typedef MapaDinamico = Map<String, dynamic>;

const Color kPrimary = Color(0xFF0F263B);
const Color kAccent = Color(0xFF007A78);
const Color kMint = Color(0xFF5EEAD4);
const Color kFieldBg = Color(0xFFF2F5F9);

class ClasesAsignaturaScreen extends StatefulWidget {
  final String cursoId;
  final MapaDinamico cursoData;

  const ClasesAsignaturaScreen({
    super.key,
    required this.cursoId,
    required this.cursoData,
  });

  @override
  State<ClasesAsignaturaScreen> createState() => _ClasesAsignaturaScreenState();
}

class _ClasesAsignaturaScreenState extends State<ClasesAsignaturaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _creandoClase = false;

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
        return Icons.calculate_outlined;
    }
  }

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

  String _formatearFechaCorta(DateTime fecha) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    final d = fecha.day.toString().padLeft(2, '0');
    return '$d ${meses[fecha.month - 1]} ${fecha.year}';
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

  String _generarPinClase(String codigoSeccion) {
    final prefijo = codigoSeccion.isNotEmpty
        ? codigoSeccion.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase()
        : 'CLS';
    final tag = prefijo.length >= 4
        ? prefijo.substring(0, 4)
        : prefijo.padRight(4, 'X');
    final num = 100 + Random().nextInt(900);
    return '#$tag-$num';
  }

  String _generarTokenUnico() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _construirPayloadQr({
    required String cursoId,
    required String claseId,
    required String qrToken,
  }) {
    return jsonEncode({
      'app': 'PRESENTE',
      'cursoId': cursoId,
      'claseId': claseId,
      'token': qrToken,
    });
  }

  Future<void> _iniciarNuevaClase({
    required MapaDinamico cursoActual,
    required int siguienteNumero,
    required int totalEstudiantes,
  }) async {
    final temaCtrl = TextEditingController(
      text: 'Sesión de Clase $siguienteNumero',
    );

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Iniciar Clase $siguienteNumero',
          style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
        ),
        content: TextField(
          controller: temaCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Tema de la clase de hoy',
            hintText: 'Ej. Teorema del Valor Medio',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generar QR e Iniciar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _creandoClase = true);

    try {
      final horarios = (cursoActual['horarios'] as List<dynamic>?) ?? [];
      final hoy = _obtenerDiaHoy().toLowerCase();
      MapaDinamico? slotHoy;

      for (final h in horarios) {
        if ((h['dia'] ?? '').toString().toLowerCase() == hoy) {
          slotHoy = h as MapaDinamico;
          break;
        }
      }
      slotHoy ??= horarios.isNotEmpty ? horarios.first as MapaDinamico : null;

      final aula = (slotHoy?['salon'] ?? 'Aula General').toString();
      final horaInicio = _formatearHora12(slotHoy?['horaInicio']?.toString());
      final horaFin = _formatearHora12(slotHoy?['horaFin']?.toString());
      final codigoSeccion = (cursoActual['codigoSeccion'] ?? '').toString();
      final metodo = (cursoActual['metodoValidacion'] ?? 'QR_DINAMICO_15S')
                  .toString() ==
              'QR_DINAMICO_15S'
          ? 'QR Dinámico'
          : 'QR Único';

      final clasesRef = FirebaseFirestore.instance
          .collection('asignaturas')
          .doc(widget.cursoId)
          .collection('clases');

      final activasPrevias =
          await clasesRef.where('estado', isEqualTo: 'activa').get();
      for (final doc in activasPrevias.docs) {
        await doc.reference.update({
          'estado': 'completada',
          'qrActivo': false,
        });
      }

      final tema = temaCtrl.text.trim().isEmpty
          ? 'Sesión de Clase $siguienteNumero'
          : temaCtrl.text.trim();
      final pinGenerado = _generarPinClase(codigoSeccion);
      final qrToken = _generarTokenUnico();

      final nuevaClaseDoc = clasesRef.doc();
      final qrPayload = _construirPayloadQr(
        cursoId: widget.cursoId,
        claseId: nuevaClaseDoc.id,
        qrToken: qrToken,
      );

      await nuevaClaseDoc.set({
        'numeroClase': siguienteNumero,
        'tema': tema,
        'estado': 'activa',
        'aula': aula,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'pin': pinGenerado,
        'metodo': metodo,
        'qrToken': qrToken,
        'qrPayload': qrPayload,
        'qrActivo': true,
        'presentes': [],
        'registrosDetalle': {},
        'excusas': {},
        'fecha': FieldValue.serverTimestamp(),
        'fechaTexto': _formatearFechaCorta(DateTime.now()),
      });

      if (mounted) {
        _mostrarModalQrClase(
          claseDocId: nuevaClaseDoc.id,
          numeroClase: siguienteNumero,
          tema: tema,
          pin: pinGenerado,
          qrPayload: qrPayload,
          totalEstudiantes: totalEstudiantes,
          nombreCurso: (cursoActual['nombreCurso'] ?? 'Asignatura').toString(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar clase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creandoClase = false);
    }
  }

  void _mostrarModalQrClase({
    required String claseDocId,
    required int numeroClase,
    required String tema,
    required String pin,
    required String qrPayload,
    required int totalEstudiantes,
    required String nombreCurso,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('asignaturas')
              .doc(widget.cursoId)
              .collection('clases')
              .doc(claseDocId)
              .snapshots(),
          builder: (modalCtx, snap) {
            int cantPresentes = 0;
            bool qrActivo = true;
            if (snap.hasData && snap.data!.exists) {
              final d = snap.data!.data() as MapaDinamico;
              final lista = (d['presentes'] as List<dynamic>?) ?? [];
              cantPresentes = lista.length;
              qrActivo = (d['qrActivo'] as bool?) ?? true;
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      qrActivo ? 'QR ACTIVO PARA ESCANEO' : 'SESIÓN FINALIZADA',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: kAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nombreCurso,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Clase $numeroClase: $tema',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kPrimary, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 225,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: kPrimary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kFieldBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'PIN DE CLASE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pin,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: Colors.grey.shade300,
                        ),
                        Column(
                          children: [
                            Text(
                              'ASISTENCIA EN VIVO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$cantPresentes / $totalEstudiantes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Los estudiantes matriculados en esta asignatura deben escanear este código desde su aplicación para registrar su asistencia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimary,
                            side: const BorderSide(color: kPrimary),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => Navigator.pop(modalCtx),
                          child: const Text(
                            'Ocultar QR',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('asignaturas')
                                .doc(widget.cursoId)
                                .collection('clases')
                                .doc(claseDocId)
                                .update({
                              'estado': 'completada',
                              'qrActivo': false,
                            });
                            if (modalCtx.mounted) Navigator.pop(modalCtx);
                          },
                          child: const Text(
                            'Cerrar Asistencia',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _abrirDetalleClase({
    required String claseDocId,
    required MapaDinamico claseData,
    required List<dynamic> estudiantes,
    required String nombreCurso,
    required String codigoSeccion,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleAsistenciaClaseScreen(
          cursoId: widget.cursoId,
          claseDocId: claseDocId,
          claseDataInicial: claseData,
          estudiantesCorreos: estudiantes,
          nombreCurso: nombreCurso,
          codigoSeccion: codigoSeccion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final anioActual = DateTime.now().year;
    final periodoActual = DateTime.now().month <= 6 ? 'I' : 'II';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('asignaturas')
              .doc(widget.cursoId)
              .snapshots(),
          builder: (context, cursoSnap) {
            final cursoData = (cursoSnap.hasData && cursoSnap.data!.exists)
                ? cursoSnap.data!.data() as MapaDinamico
                : widget.cursoData;

            final nombreCurso =
                (cursoData['nombreCurso'] ?? 'Asignatura').toString();
            final codigoSeccion =
                (cursoData['codigoSeccion'] ?? '').toString().trim();
            final colorCurso =
                _parseColorHex(cursoData['colorHex']?.toString());
            final iconoCurso =
                _getIconoPorNombre(cursoData['icono']?.toString());
            final estudiantes =
                (cursoData['estudiantes'] as List<dynamic>?) ?? [];
            final totalEstudiantes = (cursoData['totalEstudiantes'] as int?) ??
                estudiantes.length;
            final horarios = (cursoData['horarios'] as List<dynamic>?) ?? [];
            final aulaPrincipal = horarios.isNotEmpty
                ? ((horarios.first as MapaDinamico)['salon'] ?? 'Sin aula')
                    .toString()
                : 'Sin aula';

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('asignaturas')
                  .doc(widget.cursoId)
                  .collection('clases')
                  .snapshots(),
              builder: (context, clasesSnap) {
                final docsClases = clasesSnap.data?.docs ?? [];

                final clasesOrdenadas = [...docsClases];
                clasesOrdenadas.sort((a, b) {
                  final dA = a.data() as MapaDinamico;
                  final dB = b.data() as MapaDinamico;
                  final nA = (dA['numeroClase'] as int?) ?? 0;
                  final nB = (dB['numeroClase'] as int?) ?? 0;
                  return nB.compareTo(nA);
                });

                QueryDocumentSnapshot? claseActivaDoc;
                final List<QueryDocumentSnapshot> historialClases = [];

                for (final doc in clasesOrdenadas) {
                  final d = doc.data() as MapaDinamico;
                  if ((d['estado'] ?? '') == 'activa' &&
                      claseActivaDoc == null) {
                    claseActivaDoc = doc;
                  } else {
                    historialClases.add(doc);
                  }
                }

                final historialFiltrado = historialClases.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final d = doc.data() as MapaDinamico;
                  final tema = (d['tema'] ?? '').toString().toLowerCase();
                  final num = 'clase ${d['numeroClase'] ?? ''}'.toLowerCase();
                  final q = _searchQuery.toLowerCase();
                  return tema.contains(q) || num.contains(q);
                }).toList();

                final siguienteNumeroClase = clasesOrdenadas.isEmpty
                    ? 1
                    : (((clasesOrdenadas.first.data()
                                as MapaDinamico)['numeroClase'] as int?) ??
                            clasesOrdenadas.length) +
                        1;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. BARRA SUPERIOR
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  size: 18, color: kPrimary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Image.asset(
                            'lib/src/img/logo.png',
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.school,
                                size: 22,
                                color: kPrimary),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Presente!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                                Text(
                                  'TU ASISTENCIA AL INSTANTE',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                    color: kAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.ios_share,
                                  size: 17, color: kPrimary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Código del curso: ${codigoSeccion.isNotEmpty ? codigoSeccion : widget.cursoId}'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          StreamBuilder<DocumentSnapshot>(
                            stream: userEmail.isNotEmpty
                                ? FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(userEmail)
                                    .snapshots()
                                : null,
                            builder: (_, uSnap) {
                              String fotoUrl = '';
                              if (uSnap.hasData && uSnap.data!.exists) {
                                final uData = uSnap.data!.data() as MapaDinamico;
                                fotoUrl = (uData['fotoUrl'] ?? '').toString();
                              }
                              return CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: fotoUrl.isNotEmpty
                                    ? NetworkImage(fotoUrl)
                                    : null,
                                child: fotoUrl.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 19, color: kPrimary)
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. TARJETA BLANCA DE INFORMACIÓN DE LA ASIGNATURA
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colorCurso,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(iconoCurso, color: kMint, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombreCurso,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$anioActual-$periodoActual',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: kAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${codigoSeccion.isNotEmpty ? 'Código: $codigoSeccion • ' : ''}$aulaPrincipal • $totalEstudiantes Estudiantes matriculados',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. ENCABEZADO "CLASE DE HOY - ASISTENCIA EN CURSO"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.circle, size: 9, color: kAccent),
                              SizedBox(width: 6),
                              Text(
                                'CLASE DE HOY • ASISTENCIA EN CURSO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Prioridad docente',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 4. TARJETA OSCURA DESTACADA
                      _buildTarjetaClaseActiva(
                        claseActivaDoc: claseActivaDoc,
                        cursoData: cursoData,
                        totalEstudiantes: totalEstudiantes,
                        estudiantes: estudiantes,
                        siguienteNumero: siguienteNumeroClase,
                        nombreCurso: nombreCurso,
                        codigoSeccion: codigoSeccion,
                      ),
                      const SizedBox(height: 24),

                      // 5. SECCIÓN HISTORIAL DE CLASES DEL SEMESTRE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Historial de Clases del\nSemestre',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Consulta el registro de clases anteriores',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0ECFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${clasesOrdenadas.length} clases registradas',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // BUSCADOR DE CLASES
                      TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText:
                              'Buscar por clase o tema (ej. Clase 4, Derivadas...',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey.shade500),
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
                              const EdgeInsets.symmetric(vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: kAccent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // LISTA DE CLASES ANTERIORES
                      if (historialFiltrado.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.history_edu_outlined,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                historialClases.isEmpty
                                    ? 'Aún no hay clases finalizadas en el historial'
                                    : 'No se encontraron clases con "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...historialFiltrado.map((doc) {
                          final data = doc.data() as MapaDinamico;
                          return _buildTarjetaHistorial(
                            claseDocId: doc.id,
                            claseData: data,
                            totalEstudiantes: totalEstudiantes,
                            estudiantes: estudiantes,
                            nombreCurso: nombreCurso,
                            codigoSeccion: codigoSeccion,
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTarjetaClaseActiva({
    required QueryDocumentSnapshot? claseActivaDoc,
    required MapaDinamico cursoData,
    required int totalEstudiantes,
    required List<dynamic> estudiantes,
    required int siguienteNumero,
    required String nombreCurso,
    required String codigoSeccion,
  }) {
    if (claseActivaDoc == null) {
      final horarios = (cursoData['horarios'] as List<dynamic>?) ?? [];
      final primerSlot = horarios.isNotEmpty
          ? horarios.first as MapaDinamico
          : <String, dynamic>{};
      final horaIni = _formatearHora12(primerSlot['horaInicio']?.toString());
      final horaFin = _formatearHora12(primerSlot['horaFin']?.toString());
      final aula = (primerSlot['salon'] ?? 'Aula asignada').toString();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: kMint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: kPrimary),
                      SizedBox(width: 6),
                      Text(
                        'LISTA PARA\nINICIAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 15, color: kMint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$horaIni - $horaFin • Hoy',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kMint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'CLASE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                      Text(
                        '$siguienteNumero',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clase $siguienteNumero: Sesión de Hoy',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$aula • $totalEstudiantes alumnos matriculados',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMint,
                  foregroundColor: kPrimary,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: _creandoClase
                    ? null
                    : () => _iniciarNuevaClase(
                          cursoActual: cursoData,
                          siguienteNumero: siguienteNumero,
                          totalEstudiantes: totalEstudiantes,
                        ),
                child: _creandoClase
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: kPrimary),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 21),
                          SizedBox(width: 8),
                          Text(
                            'Iniciar Clase y Tomar Asistencia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    }

    final data = claseActivaDoc.data() as MapaDinamico;
    final numClase = (data['numeroClase'] as int?) ?? 1;
    final tema = (data['tema'] ?? 'Clase en curso').toString();
    final aula = (data['aula'] ?? 'Aula').toString();
    final pin = (data['pin'] ?? '#CLS-000').toString();
    final metodo = (data['metodo'] ?? 'QR Dinámico').toString();
    final horaIni = (data['horaInicio'] ?? '08:00 AM').toString();
    final horaFin = (data['horaFin'] ?? '10:00 AM').toString();
    final qrPayload = (data['qrPayload'] ??
            _construirPayloadQr(
              cursoId: widget.cursoId,
              claseId: claseActivaDoc.id,
              qrToken: (data['qrToken'] ?? 'TOKEN').toString(),
            ))
        .toString();
    final presentes = (data['presentes'] as List<dynamic>?) ?? [];
    final cantPresentes = presentes.length;
    final porcentaje =
        totalEstudiantes > 0 ? (cantPresentes / totalEstudiantes) : 0.0;
    final porcentajeTexto = (porcentaje * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kMint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: kPrimary),
                    SizedBox(width: 6),
                    Text(
                      'EN VIVO /\nACTIVA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 15, color: kMint),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$horaIni - $horaFin • Hoy',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CLASE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    Text(
                      '$numClase',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clase $numClase: $tema',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.meeting_room_outlined,
                                size: 13, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              aula,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.white70),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.vpn_key_outlined,
                                size: 13, color: kMint),
                            const SizedBox(width: 3),
                            Text(
                              'PIN: $pin',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2,
                                size: 13, color: kMint),
                            const SizedBox(width: 3),
                            Text(
                              metodo,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Asistencia Registrada al\nMomento:',
                style: TextStyle(fontSize: 11.5, color: Colors.white70),
              ),
              Text(
                '$cantPresentes de $totalEstudiantes alumnos\n($porcentajeTexto%)',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(kMint),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMint,
                foregroundColor: kPrimary,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () => _mostrarModalQrClase(
                claseDocId: claseActivaDoc.id,
                numeroClase: numClase,
                tema: tema,
                pin: pin,
                qrPayload: qrPayload,
                totalEstudiantes: totalEstudiantes,
                nombreCurso: nombreCurso,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mostrar Código QR de Asistencia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: const StadiumBorder(),
              ),
              onPressed: () => _abrirDetalleClase(
                claseDocId: claseActivaDoc.id,
                claseData: data,
                estudiantes: estudiantes,
                nombreCurso: nombreCurso,
                codigoSeccion: codigoSeccion,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ver Listado de Estudiantes y Detalles',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaHistorial({
    required String claseDocId,
    required MapaDinamico claseData,
    required int totalEstudiantes,
    required List<dynamic> estudiantes,
    required String nombreCurso,
    required String codigoSeccion,
  }) {
    final numClase = claseData['numeroClase'] ?? 1;
    final tema = (claseData['tema'] ?? 'Sesión').toString();
    final fechaTexto = (claseData['fechaTexto'] ?? '').toString();
    final horaIni = (claseData['horaInicio'] ?? '08:00 AM').toString();
    final horaFin = (claseData['horaFin'] ?? '10:00 AM').toString();
    final metodo = (claseData['metodo'] ?? 'QR Dinámico').toString();
    final presentes = (claseData['presentes'] as List<dynamic>?) ?? [];
    final cantPresentes = presentes.length;
    final cantAusentes =
        (totalEstudiantes - cantPresentes).clamp(0, totalEstudiantes);
    final porcentaje = totalEstudiantes > 0
        ? ((cantPresentes / totalEstudiantes) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kFieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Completada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: kAccent),
                    const SizedBox(width: 4),
                    Text(
                      '$porcentaje% Asistencia',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: kFieldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CLASE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$numClase',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clase $numClase: $tema',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${fechaTexto.isNotEmpty ? '$fechaTexto • ' : ''}$horaIni - $horaFin',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      children: [
                        Text(
                          '$cantPresentes presentes',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        Text(
                          '$cantAusentes ausentes',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      metodo,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: kAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _abrirDetalleClase(
                  claseDocId: claseDocId,
                  claseData: claseData,
                  estudiantes: estudiantes,
                  nombreCurso: nombreCurso,
                  codigoSeccion: codigoSeccion,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  backgroundColor: kFieldBg,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver Detalle',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PANTALLA DE DETALLE DE ASISTENCIA POR CLASE (CON EXCUSAS ADJUNTAS EN PDF)
// ============================================================================

class DetalleAsistenciaClaseScreen extends StatefulWidget {
  final String cursoId;
  final String claseDocId;
  final MapaDinamico claseDataInicial;
  final List<dynamic> estudiantesCorreos;
  final String nombreCurso;
  final String codigoSeccion;

  const DetalleAsistenciaClaseScreen({
    super.key,
    required this.cursoId,
    required this.claseDocId,
    required this.claseDataInicial,
    required this.estudiantesCorreos,
    required this.nombreCurso,
    required this.codigoSeccion,
  });

  @override
  State<DetalleAsistenciaClaseScreen> createState() =>
      _DetalleAsistenciaClaseScreenState();
}

class _DetalleAsistenciaClaseScreenState
    extends State<DetalleAsistenciaClaseScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _tabFiltro = 0; // 0: Todos, 1: Presentes, 2: Pendientes / Ausentes
  late Future<List<InfoEstudiante>> _estudiantesInfoFuture;
  bool _validandoRestantes = false;

  @override
  void initState() {
    super.initState();
    _estudiantesInfoFuture = _cargarEstudiantesOrdenados();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<InfoEstudiante>> _cargarEstudiantesOrdenados() async {
    final List<InfoEstudiante> lista = [];

    for (final raw in widget.estudiantesCorreos) {
      final correo = raw.toString().trim().toLowerCase();
      if (correo.isEmpty) continue;

      String nombre = correo.split('@').first;
      String codigo = '';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(correo)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final nombreDoc = (data['nombreCompleto'] ??
                  '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}')
              .toString()
              .trim();
          if (nombreDoc.isNotEmpty) nombre = nombreDoc;
          codigo = (data['codigo'] ?? data['identificacion'] ?? '')
              .toString()
              .trim();
        }
      } catch (_) {}

      lista.add({
        'correo': correo,
        'nombre': nombre,
        'codigo': codigo,
      });
    }

    lista.sort((a, b) =>
        a['nombre']!.toLowerCase().compareTo(b['nombre']!.toLowerCase()));

    return lista;
  }

  String _obtenerIniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'ES';
    if (partes.length == 1) {
      return partes[0]
          .substring(0, partes[0].length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  String _horaActual12() {
    final now = DateTime.now();
    final periodo = now.hour >= 12 ? 'PM' : 'AM';
    final h12 = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    return '${h12.toString().padLeft(2, '0')}:$m $periodo';
  }

  Future<void> _alternarAsistencia({
    required String correo,
    required bool marcarPresente,
    String metodoTexto = 'Validado por Docente',
    String badgeTexto = 'Verificado',
  }) async {
    final claseRef = FirebaseFirestore.instance
        .collection('asignaturas')
        .doc(widget.cursoId)
        .collection('clases')
        .doc(widget.claseDocId);

    if (marcarPresente) {
      await claseRef.update({
        'presentes': FieldValue.arrayUnion([correo]),
        'registrosDetalle.$correo': {
          'hora': _horaActual12(),
          'metodo': metodoTexto,
          'badge': badgeTexto,
        },
      });
    } else {
      await claseRef.update({
        'presentes': FieldValue.arrayRemove([correo]),
        'registrosDetalle.$correo': FieldValue.delete(),
      });
    }
  }

  Future<void> _validarRestantes({
    required List<InfoEstudiante> todos,
    required Set<String> presentesSet,
  }) async {
    final pendientes = todos
        .where((e) => !presentesSet.contains(e['correo']!))
        .map((e) => e['correo']!)
        .toList();

    if (pendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Todos los estudiantes ya están registrados.')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Validar Restantes',
          style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
        ),
        content: Text(
          '¿Deseas marcar como presentes a los ${pendientes.length} alumnos pendientes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Validar Todos'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _validandoRestantes = true);
    try {
      final claseRef = FirebaseFirestore.instance
          .collection('asignaturas')
          .doc(widget.cursoId)
          .collection('clases')
          .doc(widget.claseDocId);

      final hora = _horaActual12();
      final MapaDinamico updates = {
        'presentes': FieldValue.arrayUnion(pendientes),
      };
      for (final correo in pendientes) {
        updates['registrosDetalle.$correo'] = {
          'hora': hora,
          'metodo': 'Validado por Docente',
          'badge': 'Verificado',
        };
      }

      await claseRef.update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Se validó la asistencia de ${pendientes.length} estudiantes.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _validandoRestantes = false);
    }
  }

  // Modal para ver, abrir el PDF y aprobar/rechazar la excusa del estudiante
  Future<void> _mostrarModalDetalleExcusa({
    required String correo,
    required String nombreEstudiante,
    required MapaDinamico resumenExcusa,
  }) async {
    final claseRef = FirebaseFirestore.instance
        .collection('asignaturas')
        .doc(widget.cursoId)
        .collection('clases')
        .doc(widget.claseDocId);

    // Leer el documento completo de la subcolección 'excusas' (donde está archivoBase64)
    MapaDinamico datosCompletos = Map<String, dynamic>.from(resumenExcusa);
    try {
      final excDoc = await claseRef.collection('excusas').doc(correo).get();
      if (excDoc.exists && excDoc.data() != null) {
        datosCompletos.addAll(excDoc.data()!);
      }
    } catch (_) {}

    if (!mounted) return;

    final motivo = (datosCompletos['motivo'] ?? 'Justificante médico').toString();
    final archivoNombre =
        (datosCompletos['archivoNombre'] ?? 'Excusa_Estudiante.pdf').toString();
    final horaEnvio = (datosCompletos['horaTexto'] ??
            datosCompletos['hora'] ??
            'Hoy')
        .toString();
    final pdfBase64 = (datosCompletos['archivoBase64'] ?? '').toString();
    final estadoActual =
        (datosCompletos['estado'] ?? 'pendiente_revision').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        bool abriendoPdf = false;
        bool procesandoEstado = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: kAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreEstudiante,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                            Text(
                              'Enviada: $horaEnvio',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MOTIVO DE LA EXCUSA',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: kFieldBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      motivo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'DOCUMENTO ADJUNTO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.picture_as_pdf,
                              color: Colors.redAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                archivoNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                              Text(
                                pdfBase64.isNotEmpty
                                    ? 'Documento PDF disponible'
                                    : 'Archivo adjunto registrado',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pdfBase64.isNotEmpty)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: abriendoPdf
                                ? null
                                : () async {
                                    setModalState(() => abriendoPdf = true);
                                    try {
                                      final bytes = base64Decode(pdfBase64);
                                      final dir =
                                          await getTemporaryDirectory();
                                      final file = File(
                                          '${dir.path}/excusa_${DateTime.now().millisecondsSinceEpoch}.pdf');
                                      await file.writeAsBytes(bytes);
                                      await OpenFilex.open(file.path);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'No se pudo abrir el visor PDF: $e'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (ctx.mounted) {
                                        setModalState(
                                            () => abriendoPdf = false);
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.open_in_new, size: 15),
                            label: Text(
                              abriendoPdf ? 'Abriendo...' : 'Abrir PDF',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (estadoActual == 'aprobada')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: kAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Excusa aprobada • Estudiante marcado como Presente',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: kAccent,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: procesandoEstado
                                ? null
                                : () async {
                                    setModalState(
                                        () => procesandoEstado = true);
                                    await claseRef.update({
                                      'excusas.$correo.estado': 'rechazada',
                                    });
                                    try {
                                      await claseRef
                                          .collection('excusas')
                                          .doc(correo)
                                          .update({'estado': 'rechazada'});
                                    } catch (_) {}
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                            child: const Text(
                              'Rechazar Excusa',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: procesandoEstado
                                ? null
                                : () async {
                                    setModalState(
                                        () => procesandoEstado = true);
                                    await claseRef.update({
                                      'presentes':
                                          FieldValue.arrayUnion([correo]),
                                      'registrosDetalle.$correo': {
                                        'hora': horaEnvio,
                                        'metodo': 'Excusa Aprobada',
                                        'badge': 'Justificado',
                                      },
                                      'excusas.$correo.estado': 'aprobada',
                                    });
                                    try {
                                      await claseRef
                                          .collection('excusas')
                                          .doc(correo)
                                          .update({'estado': 'aprobada'});
                                    } catch (_) {}
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Excusa aprobada y asistencia justificada.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                            child: const Text(
                              'Aprobar y Dar Presente',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('asignaturas')
              .doc(widget.cursoId)
              .collection('clases')
              .doc(widget.claseDocId)
              .snapshots(),
          builder: (_, snap) {
            final d = (snap.hasData && snap.data!.exists)
                ? snap.data!.data() as MapaDinamico
                : widget.claseDataInicial;
            final numClase = d['numeroClase'] ?? 1;
            final tema = (d['tema'] ?? 'Detalle de Asistencia').toString();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clase $numClase: $tema',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
                Text(
                  widget.nombreCurso,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: FutureBuilder<List<InfoEstudiante>>(
        future: _estudiantesInfoFuture,
        builder: (context, estSnap) {
          if (estSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          final listaEstudiantes = estSnap.data ?? [];

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('asignaturas')
                .doc(widget.cursoId)
                .collection('clases')
                .doc(widget.claseDocId)
                .snapshots(),
            builder: (context, claseSnap) {
              final claseData = (claseSnap.hasData && claseSnap.data!.exists)
                  ? claseSnap.data!.data() as MapaDinamico
                  : widget.claseDataInicial;

              final presentesRaw =
                  (claseData['presentes'] as List<dynamic>?) ?? [];
              final presentesSet =
                  presentesRaw.map((e) => e.toString().toLowerCase()).toSet();
              final registrosDetalle =
                  (claseData['registrosDetalle'] as MapaDinamico?) ?? {};
              final excusasMap =
                  (claseData['excusas'] as MapaDinamico?) ?? {};

              final horaClase =
                  (claseData['horaInicio'] ?? '08:00 AM').toString();
              final metodoClase =
                  (claseData['metodo'] ?? 'QR Dinámico').toString();

              final totalAlumnos = listaEstudiantes.length;
              final cantPresentes = listaEstudiantes
                  .where((e) => presentesSet.contains(e['correo']))
                  .length;
              final cantPendientes =
                  (totalAlumnos - cantPresentes).clamp(0, totalAlumnos);
              final progreso =
                  totalAlumnos > 0 ? (cantPresentes / totalAlumnos) : 0.0;
              final porcentajeStr = (progreso * 100).toStringAsFixed(1);

              final estudiantesFiltrados = listaEstudiantes.where((est) {
                final correo = est['correo']!;
                final nombre = est['nombre']!.toLowerCase();
                final codigo = est['codigo']!.toLowerCase();
                final esPresente = presentesSet.contains(correo);

                if (_tabFiltro == 1 && !esPresente) return false;
                if (_tabFiltro == 2 && esPresente) return false;

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  return nombre.contains(q) ||
                      codigo.contains(q) ||
                      correo.contains(q);
                }
                return true;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TARJETA "MARCACIÓN EN TIEMPO REAL"
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MARCACIÓN EN TIEMPO REAL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$cantPresentes',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' de $totalAlumnos registrados',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt,
                                        size: 15, color: kAccent),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$porcentajeStr%',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: kAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progreso.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(kAccent),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: kFieldBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          size: 9, color: kAccent),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Presentes Confirm...',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$cantPresentes alumnos',
                                              style: const TextStyle(
                                                fontSize: 14,
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
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: kFieldBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle,
                                          size: 9, color: Colors.grey.shade500),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sin Registrar / Pen...',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$cantPendientes alumnos',
                                              style: const TextStyle(
                                                fontSize: 14,
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. PESTAÑAS DE FILTRO
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill(0, 'Todos ($totalAlumnos)'),
                          const SizedBox(width: 8),
                          _buildFilterPill(1, 'Presentes ($cantPresentes)'),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                              2, 'Pendientes / Ausentes ($cantPendientes)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. BUSCADOR Y BOTÓN "Validar Restantes"
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v.trim()),
                              decoration: InputDecoration(
                                hintText: 'Buscar alumno por no...',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 13),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 13, horizontal: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _validandoRestantes
                              ? null
                              : () => _validarRestantes(
                                    todos: listaEstudiantes,
                                    presentesSet: presentesSet,
                                  ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0ECFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.done_all,
                                    size: 18, color: kAccent),
                                const SizedBox(width: 6),
                                Text(
                                  _validandoRestantes
                                      ? 'Validando...'
                                      : 'Validar Restantes',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 4. ENCABEZADO LISTA NOMINAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LISTA NOMINAL (ORDEN ALFABÉTICO)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.sync, size: 14, color: kAccent),
                            SizedBox(width: 4),
                            Text(
                              'Sincronizado',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: kAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5. TARJETAS INDIVIDUALES DE ESTUDIANTES
                    if (estudiantesFiltrados.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          listaEstudiantes.isEmpty
                              ? 'No hay estudiantes matriculados en esta asignatura.'
                              : 'No se encontraron estudiantes con el filtro actual.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ...List.generate(estudiantesFiltrados.length, (idx) {
                        final est = estudiantesFiltrados[idx];
                        final correo = est['correo']!;
                        final nombre = est['nombre']!;
                        final codigo = est['codigo']!;
                        final esPresente = presentesSet.contains(correo);
                        final detalleEst =
                            registrosDetalle[correo] as MapaDinamico?;
                        final excusaEst = excusasMap[correo] as MapaDinamico?;

                        final horaReg =
                            (detalleEst?['hora'] ?? horaClase).toString();
                        final metodoReg =
                            (detalleEst?['metodo'] ?? metodoClase).toString();
                        final badgeDerecho =
                            (detalleEst?['badge'] ?? 'Verificado').toString();

                        final idMostrar = codigo.isNotEmpty
                            ? 'ID: $codigo'
                            : (widget.codigoSeccion.isNotEmpty
                                ? 'ID: ${widget.codigoSeccion}-${(idx + 1).toString().padLeft(3, '0')}'
                                : correo);

                        return _buildTarjetaEstudiante(
                          index: idx,
                          correo: correo,
                          nombre: nombre,
                          idMostrar: idMostrar,
                          esPresente: esPresente,
                          horaRegistro: horaReg,
                          metodoRegistro: metodoReg,
                          badgeDerecho: badgeDerecho,
                          excusaData: excusaEst,
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final seleccionado = _tabFiltro == index;
    return GestureDetector(
      onTap: () => setState(() => _tabFiltro = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: seleccionado ? kPrimary : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: seleccionado ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaEstudiante({
    required int index,
    required String correo,
    required String nombre,
    required String idMostrar,
    required bool esPresente,
    required String horaRegistro,
    required String metodoRegistro,
    required String badgeDerecho,
    MapaDinamico? excusaData,
  }) {
    final iniciales = _obtenerIniciales(nombre);
    final tieneExcusa = excusaData != null;

    // ------------------------------------------------------------------------
    // DISEÑO DE TARJETA PARA ESTUDIANTE AUSENTE CON EXCUSA ADJUNTA (image_8cb852)
    // ------------------------------------------------------------------------
    if (!esPresente && tieneExcusa) {
      final motivo = (excusaData['motivo'] ?? 'Justificante médico').toString();
      final archivoNombre =
          (excusaData['archivoNombre'] ?? 'Excusa_Adjunta.pdf').toString();
      final horaEnvio = (excusaData['hora'] ?? 'Hoy').toString();
      final estadoExc = (excusaData['estado'] ?? '').toString();
      final esRechazada = estadoExc == 'rechazada';

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFECACA),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Avatar rosa + Nombre + Badge Ausente + Botón "Dar Presente"
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFFEE2E2),
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Ausente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        idMostrar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _alternarAsistencia(
                    correo: correo,
                    marcarPresente: true,
                    metodoTexto: 'Excusa Validada',
                    badgeTexto: 'Justificado',
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0ECFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_outlined,
                            size: 16, color: kPrimary),
                        SizedBox(width: 5),
                        Text(
                          'Dar Presente',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Caja interna azul suave con detalles de la excusa y botón "Ver Excusa"
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 15, color: kAccent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Excusa Adjunta • Enviada $horaEnvio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: esRechazada
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFF99F6E4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esRechazada
                              ? Icons.cancel_outlined
                              : Icons.event_available_outlined,
                          size: 14,
                          color: esRechazada ? Colors.redAccent : kAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          esRechazada
                              ? 'Excusa Rechazada'
                              : 'Pendiente de Aprobación',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: esRechazada ? Colors.redAccent : kAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtarjeta blanca con icono PDF, nombre del archivo y botón "Ver Excusa"
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf_outlined,
                              color: Colors.redAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                archivoNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                motivo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _mostrarModalDetalleExcusa(
                            correo: correo,
                            nombreEstudiante: nombre,
                            resumenExcusa: excusaData,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0ECFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined,
                                    size: 15, color: kPrimary),
                                SizedBox(width: 5),
                                Text(
                                  'Ver Excusa',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------------------
    // DISEÑO ESTÁNDAR (PRESENTE O AUSENTE SIN EXCUSA)
    // ------------------------------------------------------------------------
    final avatarBg = !esPresente
        ? const Color(0xFFFEE2E2)
        : (index.isEven
            ? const Color(0xFF99F6E4)
            : const Color(0xFFDBEAFE));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: avatarBg,
            child: Text(
              iniciales,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: esPresente ? kPrimary : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: esPresente
                        ? const Color(0xFF99F6E4)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        esPresente ? Icons.check : Icons.schedule,
                        size: 13,
                        color: esPresente ? kAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        esPresente ? 'Presente' : 'Ausente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: esPresente ? kAccent : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  idMostrar,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      esPresente
                          ? Icons.qr_code_2
                          : Icons.radio_button_unchecked,
                      size: 13,
                      color: esPresente ? kAccent : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        esPresente
                            ? '$horaRegistro • $metodoRegistro'
                            : 'Pendiente de escaneo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              esPresente ? FontWeight.w600 : FontWeight.normal,
                          color: esPresente ? kPrimary : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _alternarAsistencia(
              correo: correo,
              marcarPresente: !esPresente,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: esPresente ? kFieldBg : const Color(0xFFE0ECFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    esPresente ? Icons.circle : Icons.touch_app_outlined,
                    size: esPresente ? 7 : 15,
                    color: esPresente ? kAccent : kPrimary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    esPresente ? badgeDerecho : 'Dar Presente',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: esPresente ? kAccent : kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}