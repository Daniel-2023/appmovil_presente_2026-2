import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xls;
import 'package:proyecto_final/src/docente/crear_asignatura2.dart';

const Color kPrimary = Color(0xFF0F263B);
const Color kAccent = Color(0xFF007A78);
const Color kFieldBg = Color(0xFFF2F5F9);

class CrearAsignaturaScreen extends StatefulWidget {
  const CrearAsignaturaScreen({super.key});

  @override
  State<CrearAsignaturaScreen> createState() => _CrearAsignaturaScreenState();
}

class _CrearAsignaturaScreenState extends State<CrearAsignaturaScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreCursoController = TextEditingController();
  final TextEditingController _codigoSeccionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  final _facultades = [
    'Facultad de Ingeniería',
    'Facultad de Ciencias Contables, Económicas y Administrativas',
    'Facultad de Ciencias de la Educación',
    'Facultad de Ciencias Agropecuarias',
    'Facultad de Ciencias Básicas',
    'Facultad de Ciencias de la Salud',
    'Facultad de Derecho y Ciencias Políticas',
  ];

  String? _facultadSeleccionada;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  File? _archivoExcel;
  String? _nombreArchivoExcel;

  final _paletaColores = [
    const Color(0xFF0F263B),
    const Color(0xFF007A78),
    const Color(0xFF0A3656),
    const Color(0xFF47607A),
    const Color(0xFF233245),
  ];
  int _colorSeleccionadoIndex = 0;

  final _nombresIconos = [
    'psychology',
    'code',
    'terminal',
    'biotech',
    'calculate',
    'lightbulb',
  ];

  final _iconosDistintivos = [
    Icons.psychology_outlined,
    Icons.code,
    Icons.terminal,
    Icons.biotech_outlined,
    Icons.calculate_outlined,
    Icons.lightbulb_outline,
  ];
  int _iconoSeleccionadoIndex = 0;

  bool _isLoading = false;
  String _estadoProgreso = '';

  @override
  void dispose() {
    _nombreCursoController.dispose();
    _codigoSeccionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '';
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final dia = fecha.day.toString().padLeft(2, '0');
    return '$dia ${meses[fecha.month - 1]} ${fecha.year}';
  }

  Future<void> _seleccionarFecha({required bool esInicio}) async {
    final ahora = DateTime.now();
    final inicial = esInicio
        ? (_fechaInicio ?? ahora)
        : (_fechaFin ?? (_fechaInicio ?? ahora).add(const Duration(days: 120)));

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: kPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = seleccionada;
          if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
            _fechaFin = null;
          }
        } else {
          _fechaFin = seleccionada;
        }
      });
    }
  }

  // Future<void> _seleccionarArchivoExcel() async {
  //   final result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['xlsx', 'csv'],
  //   );

  //   if (result != null && result.files.single.path != null) {
  //     final file = File(result.files.single.path!);
  //     final bytes = await file.length();
  //     const maxBytes = 5 * 1024 * 1024;

  //     if (bytes > maxBytes) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('El archivo supera el tamaño máximo permitido de 5MB.'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //       return;
  //     }

  //     setState(() {
  //       _archivoExcel = file;
  //       _nombreArchivoExcel = result.files.single.name;
  //     });
  //   }
  // }
     Future<void> _seleccionarArchivoExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final fileName = result.files.single.name;
      final lowerName = fileName.toLowerCase();

      if (!lowerName.endsWith('.xlsx') &&
          !lowerName.endsWith('.xls') &&
          !lowerName.endsWith('.csv')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formato no válido. Selecciona un archivo .xlsx, .xls o .csv'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final file = File(result.files.single.path!);
      final bytes = await file.length();
      const maxBytes = 5 * 1024 * 1024;

      if (bytes > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo supera el tamaño máximo permitido de 5MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _archivoExcel = file;
        _nombreArchivoExcel = fileName;
      });
    }
  }  

  void _mostrarPlantillaSugerida() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.table_chart_outlined, color: kAccent),
              SizedBox(width: 8),
              Text(
                'Columnas Reconocidas',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El sistema lee automáticamente las columnas institucionales de tu archivo (.xlsx o .csv):',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kFieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• CODIGOESTUDIANTE (código y contraseña)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kPrimary)),
                    Text('• MAIL_INST (correo institucional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kPrimary)),
                    Text('• NOMBRECOMPLETO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kPrimary)),
                    Text('• TELEFONO (celular)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kPrimary)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  /// Extrae los estudiantes desde .xlsx o .csv leyendo los encabezados institucionales
  Future<List> _extraerEstudiantesDeArchivo(File file, String fileName) async {
    final bytes = await file.readAsBytes();
    final estudiantes = [];

    if (fileName.toLowerCase().endsWith('.csv')) {
      final contenido = utf8.decode(bytes, allowMalformed: true);
      final lineas = const LineSplitter().convert(contenido);
      if (lineas.length < 2) return estudiantes;

      final separador = lineas.first.contains(';') ? ';' : ',';
      final headers = lineas.first
          .split(separador)
          .map((h) => h.trim().toUpperCase())
          .toList();

      final idxCodigo = headers.indexOf('CODIGOESTUDIANTE');
      final idxMail = headers.indexOf('MAIL_INST');
      final idxNombre = headers.indexOf('NOMBRECOMPLETO');
      final idxTel = headers.indexOf('TELEFONO');

      for (int i = 1; i < lineas.length; i++) {
        if (lineas[i].trim().isEmpty) continue;
        final cols = lineas[i].split(separador);
        final mail = (idxMail >= 0 && idxMail < cols.length) ? cols[idxMail].trim().toLowerCase() : '';
        final codigo = (idxCodigo >= 0 && idxCodigo < cols.length) ? cols[idxCodigo].trim() : '';
        final nombre = (idxNombre >= 0 && idxNombre < cols.length) ? cols[idxNombre].trim() : '';
        final tel = (idxTel >= 0 && idxTel < cols.length) ? cols[idxTel].trim() : '';

        if (mail.isNotEmpty && codigo.isNotEmpty) {
          estudiantes.add({
            'correo': mail,
            'codigo': codigo,
            'nombreCompleto': nombre,
            'celular': tel,
          });
        }
      }
    } else {
      final excel = xls.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return estudiantes;

      final sheet = excel.tables[excel.tables.keys.first]!;
      if (sheet.rows.length < 2) return estudiantes;

      final headerRow = sheet.rows.first;
      int idxCodigo = -1;
      int idxMail = -1;
      int idxNombre = -1;
      int idxTel = -1;

      for (int c = 0; c < headerRow.length; c++) {
        final val = headerRow[c]?.value?.toString().trim().toUpperCase() ?? '';
        if (val == 'CODIGOESTUDIANTE') idxCodigo = c;
        if (val == 'MAIL_INST') idxMail = c;
        if (val == 'NOMBRECOMPLETO') idxNombre = c;
        if (val == 'TELEFONO') idxTel = c;
      }

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        String getCell(int idx) {
          if (idx < 0 || idx >= row.length) return '';
          final raw = row[idx]?.value?.toString().trim() ?? '';
          return raw.endsWith('.0') ? raw.substring(0, raw.length - 2) : raw;
        }

        final mail = getCell(idxMail).toLowerCase();
        final codigo = getCell(idxCodigo);
        final nombre = getCell(idxNombre);
        final tel = getCell(idxTel);

        if (mail.isNotEmpty && codigo.isNotEmpty) {
          estudiantes.add({
            'correo': mail,
            'codigo': codigo,
            'nombreCompleto': nombre,
            'celular': tel,
          });
        }
      }
    }

    return estudiantes;
  }

  Future<void> _guardarCurso() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona las fechas de inicio y finalización de clases.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_archivoExcel == null || _nombreArchivoExcel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes subir la lista de estudiantes en Excel (.xlsx o .csv).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    if (userEmail.isEmpty) return;

    setState(() {
      _isLoading = true;
      _estadoProgreso = 'Leyendo nómina de estudiantes...';
    });

    FirebaseApp? secondaryApp;

    try {
      final listaEstudiantes =
          await _extraerEstudiantesDeArchivo(_archivoExcel!, _nombreArchivoExcel!);

      if (listaEstudiantes.isEmpty) {
        throw 'No se encontraron estudiantes válidos. Verifica que el archivo tenga las columnas CODIGOESTUDIANTE, MAIL_INST, NOMBRECOMPLETO y TELEFONO.';
      }

      final docRef = FirebaseFirestore.instance.collection('asignaturas').doc();
      final cursoId = docRef.id;
      final nombreCurso = _nombreCursoController.text.trim();

      final colorHex =
          '#${_paletaColores[_colorSeleccionadoIndex].toARGB32().toRadixString(16).substring(2).toUpperCase()}';

      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryAuthApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final correosInscritos = [];
      final firestore = FirebaseFirestore.instance;

      for (int i = 0; i < listaEstudiantes.length; i++) {
        final est = listaEstudiantes[i];
        final correo = est['correo'].toString();
        final codigo = est['codigo'].toString();
        final nombreCompleto = est['nombreCompleto'].toString();
        final celular = est['celular'].toString();

        if (mounted) {
          setState(() {
            _estadoProgreso = 'Verificando estudiante ${i + 1} de ${listaEstudiantes.length}...';
          });
        }

        final userDocRef = firestore.collection('usuarios').doc(correo);
        final userSnap = await userDocRef.get();

        // Solo crea cuenta en Auth y documento en Firestore si el correo NO existe
        if (!userSnap.exists) {
          try {
            await secondaryAuth.createUserWithEmailAndPassword(
              email: correo,
              password: codigo,
            );
            await secondaryAuth.signOut();
          } on FirebaseAuthException catch (authErr) {
            if (authErr.code != 'email-already-in-use') {
              debugPrint('Aviso Auth para $correo: ${authErr.message}');
            }
          }

          await userDocRef.set({
            'carrera': _facultadSeleccionada ?? '',
            'celular': celular,
            'codigo': codigo,
            'fotoUrl': '',
            'nombreCompleto': nombreCompleto,
            'rol': 'estudiante',
          });
        }

        // Siempre se asocia el correo del estudiante al curso creado
        correosInscritos.add(correo);
      }

      await docRef.set({
        'id': cursoId,
        'docenteEmail': userEmail,
        'nombreCurso': nombreCurso,
        'codigoSeccion': _codigoSeccionController.text.trim(),
        'facultad': _facultadSeleccionada,
        'fechaInicio': Timestamp.fromDate(_fechaInicio!),
        'fechaFin': Timestamp.fromDate(_fechaFin!),
        'descripcion': _descripcionController.text.trim(),
        'estudiantes': correosInscritos,
        'totalEstudiantes': correosInscritos.length,
        'colorHex': colorHex,
        'icono': _nombresIconos[_iconoSeleccionadoIndex],
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Curso creado con ${correosInscritos.length} estudiantes asociados!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CrearAsignatura2Screen(
            cursoId: cursoId,
            nombreCurso: nombreCurso,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el curso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _estadoProgreso = '';
        });
      }
    }
  }

  void _descartarBorrador() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar borrador'),
        content: const Text('¿Deseas salir sin guardar los datos del curso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continuar editando'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final nombreActual = _nombreCursoController.text.trim();
    final esNombreValido = nombreActual.length >= 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BARRA SUPERIOR
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: kPrimary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'lib/src/img/logo.png',
                      height: 26,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.school, color: kPrimary),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PRESENTE!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<DocumentSnapshot>(
                      stream: userEmail.isNotEmpty
                          ? FirebaseFirestore.instance.collection('usuarios').doc(userEmail).snapshots()
                          : null,
                      builder: (context, snapshot) {
                        String fotoUrl = '';
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          fotoUrl = data['fotoUrl'] ?? '';
                        }
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                          child: fotoUrl.isEmpty
                              ? const Icon(Icons.person, size: 20, color: kPrimary)
                              : null,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SUBTÍTULO, TÍTULO Y BARRA DE PROGRESO
                const Text(
                  'CONFIGURACIÓN ACADÉMICA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: kAccent,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Paso 1 de 2: Información General',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.school, color: kAccent, size: 24),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
                  ),
                ),
                const SizedBox(height: 22),

                // 1. NOMBRE DEL CURSO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRequiredLabel('Nombre del Curso '),
                    Text(
                      '${_nombreCursoController.text.length}/70',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nombreCursoController,
                  maxLength: 70,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre del curso';
                    }
                    if (value.trim().length < 4) {
                      return 'El nombre debe tener al menos 4 caracteres';
                    }
                    return null;
                  },
                  decoration: _buildBoxDecoration(
                    hint: 'Ej. Inteligencia Artificial y Machine Learning',
                    prefixIcon: Icons.menu_book_outlined,
                    suffixIcon: esNombreValido
                        ? const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor: kAccent,
                              child: Icon(Icons.check, size: 14, color: Colors.white),
                            ),
                          )
                        : null,
                  ).copyWith(counterText: ''),
                ),
                if (esNombreValido)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 14, color: kAccent),
                        SizedBox(width: 4),
                        Text(
                          'Nombre visible y válido en catálogo docente',
                          style: TextStyle(fontSize: 11.5, color: kAccent, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // 2. CÓDIGO O SECCIÓN
                RichText(
                  text: TextSpan(
                    text: 'Código o Sección ',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary),
                    children: [
                      TextSpan(
                        text: '(Opcional)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _codigoSeccionController,
                  decoration: _buildBoxDecoration(
                    hint: 'Ej. INF-402 - Sección B',
                    prefixIcon: Icons.tag,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. FACULTAD / DEPARTAMENTO
                _buildRequiredLabel('Facultad / Departamento '),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _facultadSeleccionada,
                  isExpanded: true,
                  icon: const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
                  decoration: _buildBoxDecoration(
                    hint: 'Selecciona la Facultad',
                    prefixIcon: Icons.account_balance_outlined,
                  ),
                  items: _facultades.map((facultad) {
                    return DropdownMenuItem<String>(
                      value: facultad,
                      child: Text(
                        facultad,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, color: kPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _facultadSeleccionada = val),
                  validator: (val) => val == null ? 'Selecciona una facultad' : null,
                ),
                const SizedBox(height: 16),

                // 4. FECHA DE INICIO DE CLASES
                _buildRequiredLabel('Fecha de Inicio de Clases '),
                const SizedBox(height: 6),
                _buildDateSelector(
                  texto: _fechaInicio == null ? 'Seleccionar fecha de inicio' : _formatearFecha(_fechaInicio),
                  tieneValor: _fechaInicio != null,
                  onTap: () => _seleccionarFecha(esInicio: true),
                ),
                const SizedBox(height: 16),

                // 5. FECHA DE FINALIZACIÓN
                _buildRequiredLabel('Fecha de Finalización '),
                const SizedBox(height: 6),
                _buildDateSelector(
                  texto: _fechaFin == null ? 'Seleccionar fecha de finalización' : _formatearFecha(_fechaFin),
                  tieneValor: _fechaFin != null,
                  onTap: () => _seleccionarFecha(esInicio: false),
                ),
                const SizedBox(height: 16),

                // 6. DESCRIPCIÓN DEL CURSO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Descripción del curso ',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary),
                        children: [
                          TextSpan(
                            text: '(Resumen pedagógico)',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.normal, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_descripcionController.text.length}/300',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  maxLength: 300,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Curso introductorio a modelos predictivos, redes neuronales...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: kAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 7. LISTA DE ESTUDIANTES (CARGA MASIVA)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.group_add_outlined, color: kAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Lista de Estudiantes (Carga Masiva)',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: kPrimary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0ECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Obligatorio',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sube el archivo de Excel (.xlsx, .csv) con la nómina institucional para registrar automáticamente a los estudiantes nuevos.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _seleccionarArchivoExcel,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: _archivoExcel != null ? kAccent : Colors.grey.shade400,
                      strokeWidth: 1.5,
                      gap: 5,
                      radius: 18,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5EEAD4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _archivoExcel != null ? Icons.check_circle_outline : Icons.upload_file_outlined,
                              color: kPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nombreArchivoExcel ?? 'Subir nómina en Excel o arrastrar aquí',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _archivoExcel != null
                                ? 'Toca para cambiar el archivo seleccionado'
                                : 'Formatos soportados: .xlsx, .csv (Máx. 5MB)',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _mostrarPlantillaSugerida,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: kAccent),
                                SizedBox(width: 4),
                                Text(
                                  'Ver columnas institucionales requeridas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: kAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 8. IDENTIDAD VISUAL DE LA TARJETA
                Container(
                  padding: const EdgeInsets.all(18),
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
                          const Row(
                            children: [
                              Icon(Icons.palette_outlined, color: kAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Identidad Visual de la Tarjeta',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimary),
                              ),
                            ],
                          ),
                          Text(
                            'Color e Icono',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Paleta temática:',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(_paletaColores.length, (index) {
                          final seleccionado = _colorSeleccionadoIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _colorSeleccionadoIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _paletaColores[index],
                                shape: BoxShape.circle,
                                border: seleccionado
                                    ? Border.all(color: kAccent, width: 2.5)
                                    : null,
                              ),
                              child: seleccionado
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ícono distintivo:',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_iconosDistintivos.length, (index) {
                          final seleccionado = _iconoSeleccionadoIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _iconoSeleccionadoIndex = index),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: seleccionado ? const Color(0xFFE6F4F1) : kFieldBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: seleccionado ? kAccent : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                _iconosDistintivos[index],
                                color: seleccionado ? kAccent : kPrimary,
                                size: 20,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // 9. BOTÓN GUARDAR Y CONFIGURAR CLASE
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2.5),
                            ),
                            if (_estadoProgreso.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                _estadoProgreso,
                                style: const TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 2,
                          ),
                          onPressed: _guardarCurso,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Guardar y Configurar Clase',
                                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20, color: Color(0xFF5EEAD4)),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 14),

                // 10. DESCARTAR BORRADOR
                Center(
                  child: TextButton.icon(
                    onPressed: _descartarBorrador,
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade600),
                    label: Text(
                      'Descartar borrador',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildBoxDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
      prefixIcon: Icon(prefixIcon, color: kPrimary.withValues(alpha: 0.7), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
    );
  }

  Widget _buildDateSelector({
    required String texto,
    required bool tieneValor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 19, color: kPrimary.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Text(
              texto,
              style: TextStyle(
                fontSize: 13.5,
                color: tieneValor ? kPrimary : Colors.grey.shade400,
                fontWeight: tieneValor ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + gap;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance.clamp(0.0, metric.length)),
          paint,
        );
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}