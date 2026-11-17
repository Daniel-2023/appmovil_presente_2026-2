import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';

const Color kPrimary = Color(0xFF0F263B);
const Color kAccent = Color(0xFF007A78);
const Color kMint = Color(0xFF5EEAD4);
const Color kFieldBg = Color(0xFFF2F5F9);

class TomarAsistenciaScreen extends StatefulWidget {
  final String cursoId;
  final String nombreCurso;
  final String claseDocId;
  final Map<String, dynamic> claseData;

  const TomarAsistenciaScreen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
    required this.claseDocId,
    required this.claseData,
  });

  @override
  State<TomarAsistenciaScreen> createState() => _TomarAsistenciaScreenState();
}

class _TomarAsistenciaScreenState extends State<TomarAsistenciaScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _motivoExcusaCtrl = TextEditingController();

  bool _camaraActiva = true;
  bool _procesandoQr = false;
  bool _mostrarExcusa = true;
  bool _mostrarHistorial = true;
  bool _enviandoExcusa = false;

  PlatformFile? _archivoPdfSeleccionado;
  Timer? _cronometroTimer;
  int _segundosRestantes = 900; // 15 minutos de ventana de sesión

  @override
  void initState() {
    super.initState();
    _iniciarCronometro();
  }

  void _iniciarCronometro() {
    _cronometroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatearCronometro(int totalSegundos) {
    final min = (totalSegundos ~/ 60).toString().padLeft(2, '0');
    final seg = (totalSegundos % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  String _horaActual12() {
    final now = DateTime.now();
    final periodo = now.hour >= 12 ? 'PM' : 'AM';
    final h12 = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    return '${h12.toString().padLeft(2, '0')}:$m $periodo';
  }

  @override
  void dispose() {
    _cronometroTimer?.cancel();
    _scannerController.dispose();
    _motivoExcusaCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesarCodigoLeido(String rawValue) async {
    if (_procesandoQr) return;
    setState(() => _procesandoQr = true);

    try {
      final userEmail =
          (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase();
      if (userEmail.isEmpty) {
        throw 'No se detectó una sesión de estudiante activa.';
      }

      // 1. Verificar formato JSON generado por clases_asignatura.dart
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map || decoded['app'] != 'PRESENTE') {
        throw 'El código QR escaneado no pertenece a Presente!';
      }

      final qrCursoId = (decoded['cursoId'] ?? '').toString();
      final qrClaseId = (decoded['claseId'] ?? '').toString();
      final qrToken = (decoded['token'] ?? '').toString();

      if (qrCursoId != widget.cursoId || qrClaseId != widget.claseDocId) {
        throw 'Este código QR corresponde a otra asignatura o sesión.';
      }

      // 2. Validar estado activo y token en Firestore
      final claseRef = FirebaseFirestore.instance
          .collection('asignaturas')
          .doc(widget.cursoId)
          .collection('clases')
          .doc(widget.claseDocId);

      final snap = await claseRef.get();
      if (!snap.exists) {
        throw 'La sesión de clase ya no existe.';
      }

      final data = snap.data()!;
      final qrActivo = (data['qrActivo'] as bool?) ?? false;
      final tokenReal = (data['qrToken'] ?? '').toString();

      if (!qrActivo) {
        throw 'El docente ya cerró el registro de asistencia para esta clase.';
      }

      if (qrToken != tokenReal) {
        throw 'El código QR es inválido o ha expirado.';
      }

      // 3. Registrar asistencia del estudiante en Firestore
      await claseRef.update({
        'presentes': FieldValue.arrayUnion([userEmail]),
        'registrosDetalle.$userEmail': {
          'hora': _horaActual12(),
          'metodo': 'QR Dinámico',
          'badge': 'Verificado',
        },
      });

      await _scannerController.stop();

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.check_circle, color: kAccent, size: 38),
                ),
                const SizedBox(height: 14),
                const Text(
                  '¡Asistencia Confirmada!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tu asistencia para ${widget.nombreCurso} quedó registrada a las ${_horaActual12()}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('Volver a Mis Cursos'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
      }
    } finally {
      if (mounted) setState(() => _procesandoQr = false);
    }
  }

  Future<void> _seleccionarPdfExcusa() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final archivo = result.files.first;

    // Validar máximo 10 MB
    if (archivo.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo PDF supera el límite de 10 MB.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _archivoPdfSeleccionado = archivo);
  }

  Future<void> _enviarExcusaPdf() async {
    final motivo = _motivoExcusaCtrl.text.trim();
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe el título o motivo de la excusa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_archivoPdfSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adjunta el documento justificante en formato PDF.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _enviandoExcusa = true);

    try {
      final userEmail =
          (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase();

      List<int>? bytesPdf = _archivoPdfSeleccionado!.bytes;
      if (bytesPdf == null && _archivoPdfSeleccionado!.path != null) {
        bytesPdf = await File(_archivoPdfSeleccionado!.path!).readAsBytes();
      }

      if (bytesPdf == null || bytesPdf.isEmpty) {
        throw 'No se pudo leer el contenido del archivo PDF.';
      }

      // Límite de 700 KB para almacenar en Firestore (plan gratuito Spark)
      if (bytesPdf.length > 700 * 1024) {
        throw 'El PDF supera 700 KB. Comprímelo o sube un archivo más ligero.';
      }

      final pdfBase64 = base64Encode(bytesPdf);

      final claseRef = FirebaseFirestore.instance
          .collection('asignaturas')
          .doc(widget.cursoId)
          .collection('clases')
          .doc(widget.claseDocId);

      await claseRef.collection('excusas').doc(userEmail).set({
        'estudianteCorreo': userEmail,
        'motivo': motivo,
        'archivoNombre': _archivoPdfSeleccionado!.name,
        'archivoBase64': pdfBase64,
        'estado': 'pendiente_revision',
        'fechaEnvio': FieldValue.serverTimestamp(),
        'horaTexto': _horaActual12(),
      });

      await claseRef.update({
        'excusas.$userEmail': {
          'motivo': motivo,
          'archivoNombre': _archivoPdfSeleccionado!.name,
          'estado': 'Excusa Enviada',
          'hora': _horaActual12(),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Justificante PDF enviado correctamente al docente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir el justificante: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoExcusa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aula = (widget.claseData['aula'] ?? 'Aula asignada').toString();
    final userEmail =
        (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BARRA SUPERIOR (Flecha atrás + Logo + PRESENTE!)
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
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.school, color: kPrimary, size: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PRESENTE!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. TÍTULO DE ASIGNATURA + SESIÓN ACTIVA + CRONÓMETRO
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.nombreCurso,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 9, color: kAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Sesión Activa • $aula',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: kAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0ECFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: kPrimary),
                        const SizedBox(width: 5),
                        Text(
                          _formatearCronometro(_segundosRestantes),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. TARJETA PRINCIPAL DE ESCANEO QR Y EXCUSA PDF
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Encabezado "Escanear Código QR" + Pill "Cámara Activa"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_scanner,
                                size: 20, color: kPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Escanear Código QR',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (_camaraActiva) {
                              await _scannerController.stop();
                            } else {
                              await _scannerController.start();
                            }
                            setState(() => _camaraActiva = !_camaraActiva);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: _camaraActiva
                                  ? const Color(0xFF99F6E4)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: _camaraActiva ? kAccent : Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _camaraActiva
                                      ? 'Cámara Activa'
                                      : 'Cámara Pausada',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: _camaraActiva
                                        ? kPrimary
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // VISOR DE CÁMARA CON MARCO PUNTEADO Y ESTADO INFERIOR
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 230,
                        width: double.infinity,
                        color: kPrimary,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_camaraActiva)
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: (capture) {
                                  final barcodes = capture.barcodes;
                                  for (final barcode in barcodes) {
                                    final value = barcode.rawValue;
                                    if (value != null && value.isNotEmpty) {
                                      _procesarCodigoLeido(value);
                                      break;
                                    }
                                  }
                                },
                              ),
                            // Recuadro guía central
                            Container(
                              width: 145,
                              height: 145,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: kMint,
                                  width: 2.2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2,
                                    color: kMint,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            // Píldora inferior "Listo para escanear (Esperando enfoque)"
                            Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _procesandoQr
                                          ? Icons.sync
                                          : Icons.check_circle_outline,
                                      size: 16,
                                      color: kAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _procesandoQr
                                            ? 'Validando código QR...'
                                            : 'Listo para escanear (Esperando enfoque)',
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // BOTÓN OSCURO "Escanear QR y Registrar Asistencia"
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (!_camaraActiva) {
                            await _scannerController.start();
                            setState(() => _camaraActiva = true);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Apunta la cámara hacia el código QR proyectado por tu docente.'),
                              ),
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 20, color: kMint),
                            SizedBox(width: 8),
                            Text(
                              'Escanear QR y Registrar Asistencia',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ACORDEÓN "Radicar Excusa Médica / Justificante"
                    InkWell(
                      onTap: () =>
                          setState(() => _mostrarExcusa = !_mostrarExcusa),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: kFieldBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.note_add_outlined,
                                size: 18, color: kAccent),
                            const SizedBox(width: 8),
                            const Text(
                              'Radicar Excusa Médica / Justificante',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _mostrarExcusa
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: kPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_mostrarExcusa) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Título o Motivo de la Excusa ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _motivoExcusaCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText:
                              'Ej. Cita médica Odontología, Calamidad...',
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: kFieldBg,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Encabezado "Adjuntar Documento" + "PDF Requerido"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 16, color: kAccent),
                              SizedBox(width: 6),
                              Text(
                                'Adjuntar Documento',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: kFieldBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'PDF Requerido',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Zona de carga de PDF
                      InkWell(
                        onTap: _seleccionarPdfExcusa,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 14),
                          decoration: BoxDecoration(
                            color: kFieldBg.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _archivoPdfSeleccionado != null
                                  ? kAccent
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _archivoPdfSeleccionado != null
                                      ? Icons.picture_as_pdf
                                      : Icons.upload_file_outlined,
                                  color: kAccent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _archivoPdfSeleccionado != null
                                    ? _archivoPdfSeleccionado!.name
                                    : 'Haz clic para seleccionar tu justificante',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _archivoPdfSeleccionado != null
                                    ? '${(_archivoPdfSeleccionado!.size / 1024).toStringAsFixed(1)} KB • Toca para cambiar'
                                    : 'Solo formato PDF, máx. 10MB',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botón para enviar la excusa PDF
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: _enviandoExcusa ? null : _enviarExcusaPdf,
                          icon: _enviandoExcusa
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _enviandoExcusa
                                ? 'Subiendo justificante...'
                                : 'Enviar Justificante PDF',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. TARJETA "Historial de Asistencia Reciente"
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(
                          () => _mostrarHistorial = !_mostrarHistorial),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: kFieldBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history,
                                size: 20, color: kPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Historial de Asistencia Reciente',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                                Text(
                                  'Verificar estado inactivo y sesiones pasadas',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _mostrarHistorial
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: kPrimary,
                          ),
                        ],
                      ),
                    ),
                    if (_mostrarHistorial) ...[
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('asignaturas')
                            .doc(widget.cursoId)
                            .collection('clases')
                            .snapshots(),
                        builder: (_, snap) {
                          final docs = snap.data?.docs ?? [];
                          final pasadas = docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            return (data['estado'] ?? '') != 'activa';
                          }).toList();

                          pasadas.sort((a, b) {
                            final nA = ((a.data()
                                    as Map<String, dynamic>)['numeroClase']
                                as int?) ??
                                0;
                            final nB = ((b.data()
                                    as Map<String, dynamic>)['numeroClase']
                                as int?) ??
                                0;
                            return nB.compareTo(nA);
                          });

                          if (pasadas.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No hay sesiones pasadas registradas en esta asignatura.',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600),
                              ),
                            );
                          }

                          return Column(
                            children: pasadas.take(5).map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              final presentes =
                                  (d['presentes'] as List<dynamic>?) ?? [];
                              final excusas =
                                  (d['excusas'] as Map<String, dynamic>?) ??
                                      {};
                              final asistio = presentes
                                  .map((e) => e.toString().toLowerCase())
                                  .contains(userEmail);
                              final tieneExcusa = excusas.containsKey(userEmail);

                              String estadoLabel = 'Ausente';
                              Color badgeBg = const Color(0xFFFEE2E2);
                              Color badgeText = Colors.redAccent;

                              if (asistio) {
                                estadoLabel = 'Presente';
                                badgeBg = const Color(0xFF99F6E4);
                                badgeText = kAccent;
                              } else if (tieneExcusa) {
                                estadoLabel = 'Excusa';
                                badgeBg = const Color(0xFFE0ECFF);
                                badgeText = const Color(0xFF1D4ED8);
                              }

                              final fechaTexto = (d['fechaTexto'] ??
                                      'Clase ${d['numeroClase'] ?? 1}')
                                  .toString();
                              final horaIni =
                                  (d['horaInicio'] ?? '08:00 AM').toString();
                              final aulaClase =
                                  (d['aula'] ?? aula).toString();

                              return Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: kFieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fechaTexto,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$horaIni • $aulaClase',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        estadoLabel,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: badgeText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}