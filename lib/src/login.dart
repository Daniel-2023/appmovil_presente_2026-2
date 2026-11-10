 // lib/src/login/login_screen.dart
 import 'package:flutter/material.dart';
 import 'package:firebase_auth/firebase_auth.dart';
 import 'package:cloud_firestore/cloud_firestore.dart';
 import 'package:proyecto_final/src/validator_Form.dart';
 const Color kPrimary = Color(0xFF0F263B);
 const Color kAccent = Color(0xFF007A78);
 const Color kFieldBg = Color(0xFFF2F5F9);
 class LoginScreen extends StatefulWidget {
   const LoginScreen({super.key});
   @override
   State<LoginScreen> createState() => _LoginScreenState();
 }
 class _LoginScreenState extends State<LoginScreen> {
   final _formKeyLogin = GlobalKey<FormState>();
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();
   String selectedRole = 'estudiante'; // 'estudiante' o 'docente'
   bool _obscurePassword = true;
   bool _isLoading = false;
   @override
   void dispose() {
     _emailController.dispose();
     _passwordController.dispose();
     super.dispose();
   }
   // --- LÓGICA DE FIREBASE AUTH & FIRESTORE ---
   Future<void> _iniciarSesion() async {
     if (!_formKeyLogin.currentState!.validate()) return;
     final email = _emailController.text.trim().toLowerCase();
     final password = _passwordController.text.trim();
     setState(() => _isLoading = true);
     try {
       UserCredential userCredential =
           await FirebaseAuth.instance.signInWithEmailAndPassword(
         email: email,
         password: password,
       );
       User? user = userCredential.user;
       if (user != null) {
         print('====================================================');
         print(' SESIÓN INICIADA CON ÉXITO');
         print(' Correo del usuario: ${user.email}');
         print(' UID de Firebase: ${user.uid}');
         print('====================================================');
       }
       DocumentSnapshot userDoc = await FirebaseFirestore.instance
           .collection('usuarios')
           .doc(email)
           .get();
       if (!mounted) return;
       if (userDoc.exists) {
         Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
         String rolGuardado = userData['rol'] ?? '';
         if (rolGuardado == selectedRole) {
           if (selectedRole == 'estudiante') {
             Navigator.pushReplacementNamed(context, '/estudiante');
           } else if (selectedRole == 'docente') {
             Navigator.pushReplacementNamed(context, '/docente');
           }
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(
                 'Tu usuario no tiene permisos de $selectedRole. Cambia la opción arriba.',
               ),
             ),
           );
         }
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('El usuario no está registrado en Firestore.'),
           ),
         );
       }
     } on FirebaseAuthException catch (e) {
       String mensajeError = 'Error al iniciar sesión';
       if (e.code == 'user-not-found') {
         mensajeError = 'No existe ningún usuario con este correo';
       } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
         mensajeError = 'Contraseña o correo incorrectos';
       } else if (e.code == 'invalid-email') {
         mensajeError = 'El formato del correo no es válido';
       }
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(mensajeError)),
         );
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error inesperado: $e')),
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
         child: Center(
           child: SingleChildScrollView(
             padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 // TARJETA CONTENEDORA PRINCIPAL
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
                   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // LOGO E ENCABEZADO
                       Center(
                         child: Column(
                           children: [
                             Image.asset(
                               'lib/src/img/logo.png',
                               height: 90,
                               fit: BoxFit.contain,
                             ),
                             const SizedBox(height: 10.0),
                             const Text(
                               'PRESENTE !',
                               style: TextStyle(
                                 fontSize: 26,
                                 fontWeight: FontWeight.bold,
                                 color: kPrimary,
                               ),
                             ),
                             const Text(
                               'Tu asistencia al instante',
                               style: TextStyle(
                                 fontSize: 14,
                                 color: kPrimary,
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 24.0),
                       // SELECTOR DE ROL
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
                                 label: 'Soy Docente',
                                 icon: Icons.badge_outlined,
                                 isSelect: selectedRole == 'docente',
                                 onTap: () => setState(() => selectedRole = 'docente'),
                               ),
                             ),
                             Expanded(
                               child: _buildRoleButton(
                                 label: 'Soy Estudiante',
                                 icon: Icons.school_outlined,
                                 isSelect: selectedRole == 'estudiante',
                                 onTap: () => setState(() => selectedRole = 'estudiante'),
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 24.0),
                       // TÍTULOS DE SECCIÓN
                       const Text(
                         'Inicia sesión',
                         style: TextStyle(
                           fontSize: 22,
                           fontWeight: FontWeight.bold,
                           color: kPrimary,
                         ),
                       ),
                       const SizedBox(height: 4.0),
                       Text(
                         selectedRole == 'estudiante'
                             ? 'Consulta tu registro de faltas, retardos y justificantes'
                             : 'Gestiona la asistencia y reportes de tus alumnos',
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.grey.shade600,
                         ),
                       ),
                       const SizedBox(height: 20.0),
                       // FORMULARIO
                       Form(
                         key: _formKeyLogin,
                         autovalidateMode: AutovalidateMode.onUserInteraction,
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text(
                               'Correo institucional',
                               style: TextStyle(
                                 fontSize: 14.0,
                                 fontWeight: FontWeight.w600,
                                 color: kPrimary,
                               ),
                             ),
                             const SizedBox(height: 6.0),
                             TextFormField(
                               controller: _emailController,
                               validator: ValidatorForm.validatorEmail,
                               keyboardType: TextInputType.emailAddress,
                               decoration: InputDecoration(
                                 hintText: selectedRole == 'estudiante'
                                     ? 'estudiante@alumnos.edu'
                                     : 'docente@colegio.edu',
                                 hintStyle: TextStyle(
                                   color: Colors.grey.shade400,
                                   fontSize: 14.0,
                                 ),
                                 prefixIcon: const Icon(
                                   Icons.alternate_email,
                                   color: Colors.grey,
                                   size: 22,
                                 ),
                                 filled: true,
                                 fillColor: kFieldBg,
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(16),
                                   borderSide: BorderSide.none,
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(
                                   horizontal: 12,
                                   vertical: 12,
                                 ),
                               ),
                             ),
                             const SizedBox(height: 16.0),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 const Text(
                                   'Contraseña',
                                   style: TextStyle(
                                     fontSize: 14.0,
                                     fontWeight: FontWeight.w600,
                                     color: kPrimary,
                                   ),
                                 ),
                                 GestureDetector(
                                   onTap: () {
                                     Navigator.pushNamed(context, '/recuperar');
                                   },
                                   child: const Text(
                                     '¿Olvidaste tu contraseña?',
                                     style: TextStyle(
                                       fontSize: 12.0,
                                       fontWeight: FontWeight.bold,
                                       color: kAccent,
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 6.0),
                             TextFormField(
                               controller: _passwordController,
                               obscureText: _obscurePassword,
                               validator: ValidatorForm.validatorPassword,
                               keyboardType: TextInputType.visiblePassword,
                               decoration: InputDecoration(
                                 hintText: '••••••••••••',
                                 hintStyle: TextStyle(
                                   color: Colors.grey.shade400,
                                   fontSize: 14.0,
                                 ),
                                 prefixIcon: const Icon(
                                   Icons.lock_outline,
                                   color: Colors.grey,
                                   size: 22,
                                 ),
                                 suffixIcon: IconButton(
                                   icon: Icon(
                                     _obscurePassword
                                         ? Icons.visibility_outlined
                                         : Icons.visibility_off_outlined,
                                     color: Colors.grey,
                                     size: 20,
                                   ),
                                   onPressed: () => setState(
                                       () => _obscurePassword = !_obscurePassword),
                                 ),
                                 filled: true,
                                 fillColor: kFieldBg,
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(16),
                                   borderSide: BorderSide.none,
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(
                                   horizontal: 12,
                                   vertical: 12,
                                 ),
                               ),
                             ),
                             const SizedBox(height: 28.0),
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
                                       onPressed: _iniciarSesion,
                                       child: const Row(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           Text(
                                             'Iniciar Sesión',
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
                             const SizedBox(height: 20.0),
                             Center(
                               child: GestureDetector(
                                 onTap: () => Navigator.pushNamed(context, '/registro'),
                                 child: Text.rich(
                                   TextSpan(
                                     text: '¿No tienes cuenta? ',
                                     style: TextStyle(
                                       color: Colors.grey.shade700,
                                       fontSize: 13.0,
                                     ),
                                     children: const [
                                       TextSpan(
                                         text: 'Regístrate aquí ',
                                         style: TextStyle(
                                           color: kAccent,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                       WidgetSpan(
                                         alignment: PlaceholderAlignment.middle,
                                         child: Icon(
                                           Icons.open_in_new,
                                           size: 14,
                                           color: kAccent,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 20.0),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(
                       Icons.flash_on,
                       size: 16,
                       color: Colors.grey.shade600,
                     ),
                     const SizedBox(width: 4.0),
                     Text(
                       'Versión 1.0 • Campus Conectado',
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
       ),
     );
   }
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

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:proyecto_final/src/validator_Form.dart';

// const Color kPrimary = Color(0xFF0F263B);
// const Color kAccent = Color(0xFF007A78);
// const Color kFieldBg = Color(0xFFF2F5F9);

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKeyLogin = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   String selectedRole = 'estudiante'; // 'estudiante' o 'docente'
//   bool _obscurePassword = true;
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // --- LÓGICA DE FIRESTORE CON PROTECCIÓN CONTRA RUTAS VACÍAS ---
//   Future<void> _iniciarSesion() async {
//     if (!_formKeyLogin.currentState!.validate()) return;

//     final email = _emailController.text.trim().toLowerCase();
//     final password = _passwordController.text.trim();

//     if (email.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Por favor ingresa un correo válido.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       DocumentSnapshot? userDoc;

//       // 1. Intentar buscar primero por el campo 'email' en la colección 'usuarios'
//       QuerySnapshot query = await FirebaseFirestore.instance
//           .collection('usuarios')
//           .where('email', isEqualTo: email)
//           .get();

//       if (query.docs.isNotEmpty) {
//         userDoc = query.docs.first;
//       } else {
//         // 2. Fallback: buscar directamente por el ID del documento usando el correo
//         DocumentSnapshot docById = await FirebaseFirestore.instance
//             .collection('usuarios')
//             .doc(email)
//             .get();

//         if (docById.exists) {
//           userDoc = docById;
//         }
//       }

//       if (!mounted) return;

//       if (userDoc != null && userDoc.exists) {
//         Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
//         String passwordGuardada = userData['password'] ?? '';
//         String rolGuardado = userData['rol'] ?? '';

//         // 3. Validar la contraseña almacenada en Firestore
//         if (passwordGuardada != password) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Contraseña o correo incorrectos'),
//               backgroundColor: Colors.red,
//             ),
//           );
//           return;
//         }

//         // 4. Validar el rol seleccionado
//         if (rolGuardado == selectedRole) {
//           print('====================================================');
//           print(' SESIÓN INICIADA CON ÉXITO');
//           print(' Correo: $email');
//           print(' Rol: $selectedRole');
//           print('====================================================');

//           if (selectedRole == 'estudiante') {
//             Navigator.pushReplacementNamed(context, '/estudiante');
//           } else if (selectedRole == 'docente') {
//             Navigator.pushReplacementNamed(context, '/docente');
//           }
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Tu usuario no tiene permisos de $selectedRole. Cambia la opción arriba.',
//               ),
//             ),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No existe ningún usuario registrado con este correo.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error al iniciar sesión: $e'),
//             backgroundColor: Colors.red,
//           ),
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
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // TARJETA CONTENEDORA PRINCIPAL
//                 Container(
//                   constraints: const BoxConstraints(maxWidth: 450),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24.0),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.06),
//                         blurRadius: 20,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // LOGO Y ENCABEZADO
//                       Center(
//                         child: Column(
//                           children: [
//                             Image.asset(
//                               'lib/src/img/logo.png',
//                               height: 90,
//                               fit: BoxFit.contain,
//                             ),
//                             const SizedBox(height: 10.0),
//                             const Text(
//                               'PRESENTE !',
//                               style: TextStyle(
//                                 fontSize: 26,
//                                 fontWeight: FontWeight.bold,
//                                 color: kPrimary,
//                               ),
//                             ),
//                             const Text(
//                               'Tu asistencia al instante',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: kPrimary,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24.0),

//                       // SELECTOR DE ROL
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
//                                 label: 'Soy Docente',
//                                 icon: Icons.badge_outlined,
//                                 isSelect: selectedRole == 'docente',
//                                 onTap: () => setState(() => selectedRole = 'docente'),
//                               ),
//                             ),
//                             Expanded(
//                               child: _buildRoleButton(
//                                 label: 'Soy Estudiante',
//                                 icon: Icons.school_outlined,
//                                 isSelect: selectedRole == 'estudiante',
//                                 onTap: () => setState(() => selectedRole = 'estudiante'),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24.0),

//                       // TÍTULOS DE SECCIÓN
//                       const Text(
//                         'Inicia sesión',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: kPrimary,
//                         ),
//                       ),
//                       const SizedBox(height: 4.0),
//                       Text(
//                         selectedRole == 'estudiante'
//                             ? 'Consulta tu registro de faltas, retardos y justificantes'
//                             : 'Gestiona la asistencia y reportes de tus alumnos',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       const SizedBox(height: 20.0),

//                       // FORMULARIO
//                       Form(
//                         key: _formKeyLogin,
//                         autovalidateMode: AutovalidateMode.onUserInteraction,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Correo institucional',
//                               style: TextStyle(
//                                 fontSize: 14.0,
//                                 fontWeight: FontWeight.w600,
//                                 color: kPrimary,
//                               ),
//                             ),
//                             const SizedBox(height: 6.0),
//                             TextFormField(
//                               controller: _emailController,
//                               validator: ValidatorForm.validatorEmail,
//                               keyboardType: TextInputType.emailAddress,
//                               decoration: InputDecoration(
//                                 hintText: selectedRole == 'estudiante'
//                                     ? 'estudiante@alumnos.edu'
//                                     : 'docente@colegio.edu',
//                                 hintStyle: TextStyle(
//                                   color: Colors.grey.shade400,
//                                   fontSize: 14.0,
//                                 ),
//                                 prefixIcon: const Icon(
//                                   Icons.alternate_email,
//                                   color: Colors.grey,
//                                   size: 22,
//                                 ),
//                                 filled: true,
//                                 fillColor: kFieldBg,
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                   borderSide: BorderSide.none,
//                                 ),
//                                 contentPadding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 12,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 16.0),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 const Text(
//                                   'Contraseña',
//                                   style: TextStyle(
//                                     fontSize: 14.0,
//                                     fontWeight: FontWeight.w600,
//                                     color: kPrimary,
//                                   ),
//                                 ),
//                                 GestureDetector(
//                                   onTap: () {
//                                     Navigator.pushNamed(context, '/recuperar');
//                                   },
//                                   child: const Text(
//                                     '¿Olvidaste tu contraseña?',
//                                     style: TextStyle(
//                                       fontSize: 12.0,
//                                       fontWeight: FontWeight.bold,
//                                       color: kAccent,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 6.0),
//                             TextFormField(
//                               controller: _passwordController,
//                               obscureText: _obscurePassword,
//                               validator: ValidatorForm.validatorPassword,
//                               keyboardType: TextInputType.visiblePassword,
//                               decoration: InputDecoration(
//                                 hintText: '••••••••••••',
//                                 hintStyle: TextStyle(
//                                   color: Colors.grey.shade400,
//                                   fontSize: 14.0,
//                                 ),
//                                 prefixIcon: const Icon(
//                                   Icons.lock_outline,
//                                   color: Colors.grey,
//                                   size: 22,
//                                 ),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _obscurePassword
//                                         ? Icons.visibility_outlined
//                                         : Icons.visibility_off_outlined,
//                                     color: Colors.grey,
//                                     size: 20,
//                                   ),
//                                   onPressed: () => setState(
//                                       () => _obscurePassword = !_obscurePassword),
//                                 ),
//                                 filled: true,
//                                 fillColor: kFieldBg,
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                   borderSide: BorderSide.none,
//                                 ),
//                                 contentPadding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 12,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 28.0),
//                             SizedBox(
//                               width: double.infinity,
//                               height: 50,
//                               child: _isLoading
//                                   ? const Center(child: CircularProgressIndicator())
//                                   : ElevatedButton(
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: kPrimary,
//                                         foregroundColor: Colors.white,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(30),
//                                         ),
//                                         elevation: 0,
//                                       ),
//                                       onPressed: _iniciarSesion,
//                                       child: const Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           Text(
//                                             'Iniciar Sesión',
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           SizedBox(width: 8),
//                                           Icon(Icons.arrow_forward, size: 20),
//                                         ],
//                                       ),
//                                     ),
//                             ),
//                             const SizedBox(height: 20.0),
//                             Center(
//                               child: GestureDetector(
//                                 onTap: () => Navigator.pushNamed(context, '/registro'),
//                                 child: Text.rich(
//                                   TextSpan(
//                                     text: '¿No tienes cuenta? ',
//                                     style: TextStyle(
//                                       color: Colors.grey.shade700,
//                                       fontSize: 13.0,
//                                     ),
//                                     children: const [
//                                       TextSpan(
//                                         text: 'Regístrate aquí ',
//                                         style: TextStyle(
//                                           color: kAccent,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       WidgetSpan(
//                                         alignment: PlaceholderAlignment.middle,
//                                         child: Icon(
//                                           Icons.open_in_new,
//                                           size: 14,
//                                           color: kAccent,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20.0),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.flash_on,
//                       size: 16,
//                       color: Colors.grey.shade600,
//                     ),
//                     const SizedBox(width: 4.0),
//                     Text(
//                       'Versión 1.0 • Campus Conectado',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

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