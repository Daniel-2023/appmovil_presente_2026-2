// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:proyecto_final/src/validator_Form.dart';

// const Color kPrimary = Color(0xFF0F263B);
// const Color kAccent = Color(0xFF007A78);
// const Color kFieldBg = Color(0xFFF2F5F9);

// class RegistroScreen extends StatefulWidget {
//   const RegistroScreen({super.key});

//   @override
//   State<RegistroScreen> createState() => _RegistroScreenState();
// }

// class _RegistroScreenState extends State<RegistroScreen> {
//   final _formKey = GlobalKey<FormState>();

//   // Controladores de texto
//   final TextEditingController _nombresController = TextEditingController();
//   final TextEditingController _apellidosController = TextEditingController();
//   final TextEditingController _codigoController = TextEditingController();
//   final TextEditingController _celularController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();

//   String selectedRole = 'estudiante'; // 'estudiante' o 'docente'
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _aceptaTerminos = false;
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _nombresController.dispose();
//     _apellidosController.dispose();
//     _codigoController.dispose();
//     _celularController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   // Lógica de registro en Firebase Auth y guardado en Firestore
//   Future<void> _registrarUsuario() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (!_aceptaTerminos) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Debes aceptar los Términos de Servicio y la Política de Tratamiento de Datos.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final email = _emailController.text.trim().toLowerCase();
//     final password = _passwordController.text.trim();

//     setState(() => _isLoading = true);

//     try {
// // 1. Crear usuario en Firebase Authentication
// await FirebaseAuth.instance
//     .createUserWithEmailAndPassword(email: email, password: password);

//       // 2. Guardar información en Firestore (ID del documento = Correo)
//       await FirebaseFirestore.instance.collection('usuarios').doc(email).set({
//         'nombres': _nombresController.text.trim(),
//         'apellidos': _apellidosController.text.trim(),
//         'codigo': _codigoController.text.trim(),
//         'celular': _celularController.text.trim(),
//         'rol': selectedRole,
//       });

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('¡Cuenta creada exitosamente! Redirigiendo...'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       // Redirigir según el rol seleccionado
//       if (selectedRole == 'estudiante') {
//         Navigator.pushNamedAndRemoveUntil(context, '/estudiante', (route) => false);
//       } else {
//         Navigator.pushNamedAndRemoveUntil(context, '/docente', (route) => false);
//       }
//     } on FirebaseAuthException catch (e) {
//       String mensaje = 'Error al registrar usuario.';
//       if (e.code == 'email-already-in-use') {
//         mensaje = 'El correo electrónico ya está registrado.';
//       } else if (e.code == 'weak-password') {
//         mensaje = 'La contraseña debe tener al menos 6 caracteres.';
//       } else if (e.code == 'invalid-email') {
//         mensaje = 'El formato del correo no es válido.';
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F6FA),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
//           child: Column(
//             children: [
//               // ENCABEZADO SUPERIOR CON BOTÓN ATRÁS Y LOGO
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: kPrimary),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                    const SizedBox(width: 8.0),
//                   Image.asset('lib/src/img/logo.png', height: 28, fit: BoxFit.contain),
//                   const SizedBox(width: 8.0),
//                   const Text(
//                     'PRESENTE!',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: kPrimary,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16.0),

//               // SECCIÓN CABECERA "Crear Cuenta" Y AVATAR
//               Center(
//                 child: Column(
//                   children: [
//                     Container(
//                       width: 10,
//                       height: 10,
//                       decoration: const BoxDecoration(
//                         color: kAccent,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     const Text(
//                       'Crear Cuenta',
//                       style: TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.bold,
//                         color: kPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 6.0),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: Text(
//                         'Únete a la plataforma institucional de control de asistencia al instante.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20.0),

//                     // AVATAR OPCIONAL
//                     Stack(
//                       alignment: Alignment.bottomRight,
//                       children: [
//                         Container(
//                           width: 85,
//                           height: 85,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: Colors.grey.shade300,
//                               style: BorderStyle.solid,
//                               width: 2,
//                             ),
//                           ),
//                           child: CircleAvatar(
//                             backgroundColor: Colors.grey.shade100,
//                             child: Icon(
//                               Icons.person_outline,
//                               size: 45,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: const BoxDecoration(
//                             color: kPrimary,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.add_a_photo_outlined,
//                             size: 14,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8.0),
//                     Text(
//                       'Foto o avatar institucional (Opcional)',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                     Text(
//                       'JPG o PNG hasta 5MB • Tomar foto o galería',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20.0),

//               // TARJETA PRINCIPAL DEL FORMULARIO
//               Container(
//                 constraints: const BoxConstraints(maxWidth: 450),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(24.0),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.06),
//                       blurRadius: 20,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
//                 child: Form(
//                   key: _formKey,
//                   autovalidateMode: AutovalidateMode.onUserInteraction,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // ETISQUETA ROLES
//                       Text(
//                         'SELECCIONA TU PERFIL',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.8,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       const SizedBox(height: 10.0),

//                       // SELECTOR DE ROL (SOY ESTUDIANTE / SOY DOCENTE)
//                       Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFEFF3F8),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: _buildRoleButton(
//                                 label: 'Soy Estudiante',
//                                 icon: Icons.school_outlined,
//                                 isSelect: selectedRole == 'estudiante',
//                                 onTap: () => setState(() => selectedRole = 'estudiante'),
//                               ),
//                             ),
//                             Expanded(
//                               child: _buildRoleButton(
//                                 label: 'Soy Docente',
//                                 icon: Icons.badge_outlined,
//                                 isSelect: selectedRole == 'docente',
//                                 onTap: () => setState(() => selectedRole = 'docente'),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 14.0),

//                       // BANNER INFORMATIVO SEGÚN EL ROL
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFEBF3FA),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.info_outline, size: 18, color: kAccent),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 selectedRole == 'estudiante'
//                                     ? 'Registro estudiante: validación con matrícula institucional.'
//                                     : 'Registro docente: validación con credenciales departamentales.',
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: kPrimary,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20.0),

//                       // NOMBRES
//                       _buildLabel('Nombres *'),
//                       TextFormField(
//                         controller: _nombresController,
//                         validator: (value) =>
//                             value == null || value.trim().isEmpty ? 'Ingresa tus nombres' : null,
//                         decoration: _buildInputDecoration(
//                           hint: 'Ej. Carlos Andrés',
//                           icon: Icons.person_outline,
//                         ),
//                       ),
//                       const SizedBox(height: 14.0),

//                       // APELLIDOS
//                       _buildLabel('Apellidos *'),
//                       TextFormField(
//                         controller: _apellidosController,
//                         validator: (value) =>
//                             value == null || value.trim().isEmpty ? 'Ingresa tus apellidos' : null,
//                         decoration: _buildInputDecoration(
//                           hint: 'Ej. Gómez Pérez',
//                           icon: Icons.person_outline,
//                         ),
//                       ),
//                       const SizedBox(height: 14.0),

//                       // CÓDIGO DOCENTE / ESTUDIANTE
//                       _buildLabel(
//                         selectedRole == 'estudiante'
//                             ? 'Código Estudiantil *'
//                             : 'Código Docente / Identificación *',
//                       ),
//                       TextFormField(
//                         controller: _codigoController,
//                         validator: (value) =>
//                             value == null || value.trim().isEmpty ? 'Ingresa tu código' : null,
//                         decoration: _buildInputDecoration(
//                           hint: selectedRole == 'estudiante' ? 'Ej. EST-104928' : 'Ej. DOC-882910',
//                           icon: Icons.badge_outlined,
//                         ),
//                       ),
//                       const SizedBox(height: 14.0),

//                       // NÚMERO DE CELULAR
//                       _buildLabel('Número de Celular *'),
//                       TextFormField(
//                         controller: _celularController,
//                         keyboardType: TextInputType.phone,
//                         validator: (value) =>
//                             value == null || value.trim().isEmpty ? 'Ingresa tu celular' : null,
//                         decoration: _buildInputDecoration(
//                           hint: '300 123 4567',
//                           icon: Icons.smartphone,
//                         ),
//                       ),
//                       const SizedBox(height: 14.0),

//                       // CORREO INSTITUCIONAL
//                       _buildLabel('Correo Institucional *'),
//                       TextFormField(
//                         controller: _emailController,
//                         validator: ValidatorForm.validatorEmail,
//                         keyboardType: TextInputType.emailAddress,
//                         decoration: _buildInputDecoration(
//                           hint: selectedRole == 'estudiante'
//                               ? 'estudiante@alumnos.edu'
//                               : 'profesor@universidad.edu.co',
//                           icon: Icons.alternate_email,
//                         ),
//                       ),
//                       const SizedBox(height: 14.0),

//                       // CONTRASEÑA
//                       _buildLabel('Contraseña *'),
//                       TextFormField(
//                         controller: _passwordController,
//                         obscureText: _obscurePassword,
//                         validator: ValidatorForm.validatorPassword,
//                         decoration: _buildInputDecoration(
//                           hint: '••••••••••••',
//                           icon: Icons.lock_outline,
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _obscurePassword
//                                   ? Icons.visibility_outlined
//                                   : Icons.visibility_off_outlined,
//                               color: Colors.grey,
//                               size: 20,
//                             ),
//                             onPressed: () =>
//                                 setState(() => _obscurePassword = !_obscurePassword),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 14.0),

//                       // CONFIRMAR CONTRASEÑA
//                       _buildLabel('Confirmar Contraseña *'),
//                       TextFormField(
//                         controller: _confirmPasswordController,
//                         obscureText: _obscureConfirmPassword,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Confirma tu contraseña';
//                           }
//                           if (value != _passwordController.text) {
//                             return 'Las contraseñas no coinciden';
//                           }
//                           return null;
//                         },
//                         decoration: _buildInputDecoration(
//                           hint: '••••••••••••',
//                           icon: Icons.history,
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _obscureConfirmPassword
//                                   ? Icons.visibility_outlined
//                                   : Icons.visibility_off_outlined,
//                               color: Colors.grey,
//                               size: 20,
//                             ),
//                             onPressed: () => setState(
//                                 () => _obscureConfirmPassword = !_obscureConfirmPassword),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 18.0),

//                       // CHECKBOX TÉRMINOS Y CONDICIONES
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: Checkbox(
//                               value: _aceptaTerminos,
//                               activeColor: kAccent,
//                               onChanged: (value) =>
//                                   setState(() => _aceptaTerminos = value ?? false),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text.rich(
//                               TextSpan(
//                                 text: 'Acepto los ',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade700,
//                                 ),
//                                 children: const [
//                                   TextSpan(
//                                     text: 'Términos de Servicio ',
//                                     style: TextStyle(
//                                       color: kAccent,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   TextSpan(text: 'y la '),
//                                   TextSpan(
//                                     text: 'Política de Tratamiento de Datos Personales.',
//                                     style: TextStyle(
//                                       color: kAccent,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24.0),

//                       // BOTÓN REGISTRARME E INICIAR
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: _isLoading
//                             ? const Center(child: CircularProgressIndicator())
//                             : ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: kPrimary,
//                                   foregroundColor: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(30),
//                                   ),
//                                   elevation: 0,
//                                 ),
//                                 onPressed: _registrarUsuario,
//                                 child: const Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Text(
//                                       'Registrarme e Iniciar',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     SizedBox(width: 8),
//                                     Icon(Icons.arrow_forward, size: 20),
//                                   ],
//                                 ),
//                               ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 24.0),

//               // PIE DE PÁGINA
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.verified_user_outlined,
//                     size: 14,
//                     color: Colors.grey.shade500,
//                   ),
//                   const SizedBox(width: 4.0),
//                   Text(
//                     'Presente! • Tu asistencia al instante',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // WIDGET AUXILIAR PARA ETIQUETAS DE CAMPOS
//   Widget _buildLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6.0),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 13.0,
//           fontWeight: FontWeight.w600,
//           color: kPrimary,
//         ),
//       ),
//     );
//   }

//   // DECORACIÓN HOMOGÉNEA DE LOS CAMPOS DE TEXTO
//   InputDecoration _buildInputDecoration({
//     required String hint,
//     required IconData icon,
//     Widget? suffixIcon,
//   }) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: TextStyle(
//         color: Colors.grey.shade400,
//         fontSize: 14.0,
//       ),
//       prefixIcon: Icon(icon, color: Colors.grey, size: 20),
//       suffixIcon: suffixIcon,
//       filled: true,
//       fillColor: kFieldBg,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(16),
//         borderSide: BorderSide.none,
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//     );
//   }

//   // BOTONES DEL SELECTOR DE ROL
//   Widget _buildRoleButton({
//     required String label,
//     required IconData icon,
//     required bool isSelect,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         decoration: BoxDecoration(
//           color: isSelect ? kPrimary : Colors.transparent,
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 16, color: isSelect ? Colors.white : kPrimary),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: isSelect ? Colors.white : kPrimary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_final/src/validator_Form.dart';

const Color kPrimary = Color(0xFF0F263B);
const Color kAccent = Color(0xFF007A78);
const Color kFieldBg = Color(0xFFF2F5F9);

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String selectedRole = 'estudiante'; // 'estudiante' o 'docente'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _aceptaTerminos = false;
  bool _isLoading = false;

  // Variables para la imagen seleccionada
  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _codigoController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Método para seleccionar imagen de la galería
  Future<void> _seleccionarImagen() async {
    final XFile? imagenPicked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compresión ligera para optimizar subida
    );

    if (imagenPicked != null) {
      setState(() {
        _imagenSeleccionada = File(imagenPicked.path);
      });
    }
  }

  // Método para subir la imagen a Firebase Storage y obtener su URL
  Future<String?> _subirImagenFirebase(String email) async {
    if (_imagenSeleccionada == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('usuarios_fotos')
          .child('$email.jpg');

      await ref.putFile(_imagenSeleccionada!);
      final urlDescarga = await ref.getDownloadURL();
      return urlDescarga;
    } catch (e) {
      debugPrint('Error al subir imagen a Storage: $e');
      return null;
    }
  }

  // Lógica de registro en Firebase Auth, subida de foto y guardado en Firestore
  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los Términos de Servicio y la Política de Tratamiento de Datos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Firebase Authentication
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Subir imagen a Firebase Storage (si seleccionó una)
      String? fotoUrl;
      if (_imagenSeleccionada != null) {
        fotoUrl = await _subirImagenFirebase(email);
      }

      // 3. Guardar información en Firestore (incluyendo el campo fotoUrl)
      await FirebaseFirestore.instance.collection('usuarios').doc(email).set({
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'codigo': _codigoController.text.trim(),
        'celular': _celularController.text.trim(),
        'rol': selectedRole,
        'fotoUrl': fotoUrl ?? '', // Se guarda la URL o un string vacío si no subió foto
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente! Redirigiendo...'),
          backgroundColor: Colors.green,
        ),
      );

      // Redirigir según el rol seleccionado
      if (selectedRole == 'estudiante') {
        Navigator.pushNamedAndRemoveUntil(context, '/estudiante', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/docente', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar usuario.';
      if (e.code == 'email-already-in-use') {
        mensaje = 'El correo electrónico ya está registrado.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña debe tener al menos 6 caracteres.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo no es válido.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            children: [
              // ENCABEZADO SUPERIOR CON BOTÓN ATRÁS Y LOGO
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8.0),
                  Image.asset('lib/src/img/logo.png', height: 28, fit: BoxFit.contain),
                  const SizedBox(width: 8.0),
                  const Text(
                    'PRESENTE!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // SECCIÓN CABECERA "Crear Cuenta" Y AVATAR CON SELECCIÓN DE IMAGEN
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: kAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Únete a la plataforma institucional de control de asistencia al instante.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // AVATAR INTERACTIVO CON GALERÍA
                    GestureDetector(
                      onTap: _seleccionarImagen,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: _imagenSeleccionada != null
                                  ? FileImage(_imagenSeleccionada!)
                                  : null,
                              child: _imagenSeleccionada == null
                                  ? Icon(
                                      Icons.person_outline,
                                      size: 45,
                                      color: Colors.grey.shade600,
                                    )
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Foto o avatar institucional (Opcional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Toca el círculo para elegir desde la galería',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // TARJETA PRINCIPAL DEL FORMULARIO
              Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ETIQUETA ROLES
                      Text(
                        'SELECCIONA TU PERFIL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10.0),

                      // SELECTOR DE ROL (SOY ESTUDIANTE / SOY DOCENTE)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF3F8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRoleButton(
                                label: 'Soy Estudiante',
                                icon: Icons.school_outlined,
                                isSelect: selectedRole == 'estudiante',
                                onTap: () => setState(() => selectedRole = 'estudiante'),
                              ),
                            ),
                            Expanded(
                              child: _buildRoleButton(
                                label: 'Soy Docente',
                                icon: Icons.badge_outlined,
                                isSelect: selectedRole == 'docente',
                                onTap: () => setState(() => selectedRole = 'docente'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // BANNER INFORMATIVO SEGÚN EL ROL
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: kAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedRole == 'estudiante'
                                    ? 'Registro estudiante: validación con matrícula institucional.'
                                    : 'Registro docente: validación con credenciales departamentales.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // NOMBRES
                      _buildLabel('Nombres *'),
                      TextFormField(
                        controller: _nombresController,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa tus nombres' : null,
                        decoration: _buildInputDecoration(
                          hint: 'Ej. Carlos Andrés',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // APELLIDOS
                      _buildLabel('Apellidos *'),
                      TextFormField(
                        controller: _apellidosController,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa tus apellidos' : null,
                        decoration: _buildInputDecoration(
                          hint: 'Ej. Gómez Pérez',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // CÓDIGO DOCENTE / ESTUDIANTE
                      _buildLabel(
                        selectedRole == 'estudiante'
                            ? 'Código Estudiantil *'
                            : 'Código Docente / Identificación *',
                      ),
                      TextFormField(
                        controller: _codigoController,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa tu código' : null,
                        decoration: _buildInputDecoration(
                          hint: selectedRole == 'estudiante' ? 'Ej. EST-104928' : 'Ej. DOC-882910',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // NÚMERO DE CELULAR
                      _buildLabel('Número de Celular *'),
                      TextFormField(
                        controller: _celularController,
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa tu celular' : null,
                        decoration: _buildInputDecoration(
                          hint: '300 123 4567',
                          icon: Icons.smartphone,
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // CORREO INSTITUCIONAL
                      _buildLabel('Correo Institucional *'),
                      TextFormField(
                        controller: _emailController,
                        validator: ValidatorForm.validatorEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          hint: selectedRole == 'estudiante'
                              ? 'estudiante@alumnos.edu'
                              : 'profesor@universidad.edu.co',
                          icon: Icons.alternate_email,
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // CONTRASEÑA
                      _buildLabel('Contraseña *'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: ValidatorForm.validatorPassword,
                        decoration: _buildInputDecoration(
                          hint: '••••••••••••',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // CONFIRMAR CONTRASEÑA
                      _buildLabel('Confirmar Contraseña *'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                        decoration: _buildInputDecoration(
                          hint: '••••••••••••',
                          icon: Icons.history,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18.0),

                      // CHECKBOX TÉRMINOS Y CONDICIONES
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _aceptaTerminos,
                              activeColor: kAccent,
                              onChanged: (value) =>
                                  setState(() => _aceptaTerminos = value ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Acepto los ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Términos de Servicio ',
                                    style: TextStyle(
                                      color: kAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: 'y la '),
                                  TextSpan(
                                    text: 'Política de Tratamiento de Datos Personales.',
                                    style: TextStyle(
                                      color: kAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),

                      // BOTÓN REGISTRARME E INICIAR
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _registrarUsuario,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Registrarme e Iniciar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // PIE DE PÁGINA
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Presente! • Tu asistencia al instante',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET AUXILIAR PARA ETIQUETAS DE CAMPOS
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          color: kPrimary,
        ),
      ),
    );
  }

  // DECORACIÓN HOMOGÉNEA DE LOS CAMPOS DE TEXTO
  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14.0,
      ),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kFieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  // BOTONES DEL SELECTOR DE ROL
  Widget _buildRoleButton({
    required String label,
    required IconData icon,
    required bool isSelect,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelect ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelect ? Colors.white : kPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelect ? Colors.white : kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}