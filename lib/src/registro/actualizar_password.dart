// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:proyecto_final/src/validator_Form.dart';

// // const Color kPrimary = Color(0xFF0F263B);
// // const Color kFieldBg = Color(0xFFF2F5F9);

// // class ActualizarPasswordScreen extends StatefulWidget {
// //   final String email;
// //   final String pinGenerado;

// //   const ActualizarPasswordScreen({
// //     super.key,
// //     required this.email,
// //     required this.pinGenerado,
// //   });

// //   @override
// //   State<ActualizarPasswordScreen> createState() => _ActualizarPasswordScreenState();
// // }

// // class _ActualizarPasswordScreenState extends State<ActualizarPasswordScreen> {
// //   final _formKeyUpdate = GlobalKey<FormState>();
// //   final List<TextEditingController> _pinControllers =
// //       List.generate(6, (_) => TextEditingController());
// //   final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

// //   final TextEditingController _newPasswordController = TextEditingController();
// //   final TextEditingController _confirmPasswordController = TextEditingController();

// //   bool _obscureNewPass = true;
// //   bool _obscureConfirmPass = true;
// //   bool _isLoading = false;

// //   late String _pinActual;
// //   Timer? _timer;
// //   int _secondsRemaining = 45;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _pinActual = widget.pinGenerado;
// //     _startTimer();
// //   }

// //   void _startTimer() {
// //     _secondsRemaining = 45;
// //     _timer?.cancel();
// //     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       if (_secondsRemaining > 0) {
// //         if (mounted) setState(() => _secondsRemaining--);
// //       } else {
// //         _timer?.cancel();
// //       }
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     _timer?.cancel();
// //     for (var controller in _pinControllers) {
// //       controller.dispose();
// //     }
// //     for (var node in _focusNodes) {
// //       node.dispose();
// //     }
// //     _newPasswordController.dispose();
// //     _confirmPasswordController.dispose();
// //     super.dispose();
// //   }

// //   void _reenviarPin() {
// //     if (_secondsRemaining > 0) return;
// //     final nuevoPin = (100000 + (900000 * (DateTime.now().microsecondsSinceEpoch % 1000) / 1000)).toInt().toString();
// //     setState(() {
// //       _pinActual = nuevoPin;
// //     });
// //     _startTimer();
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text('Nuevo PIN generado: $_pinActual'),
// //         backgroundColor: const Color(0xFF007A78),
// //       ),
// //     );
// //   }

// //   Future<void> _actualizarPassword() async {
// //     final pinIngresado = _pinControllers.map((c) => c.text).join();

// //     if (pinIngresado.length < 6) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Ingresa los 6 dígitos del PIN.')),
// //       );
// //       return;
// //     }

// //     if (pinIngresado != _pinActual) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('El PIN ingresado es incorrecto.')),
// //       );
// //       return;
// //     }

// //     if (!_formKeyUpdate.currentState!.validate()) return;

// //     setState(() => _isLoading = true);

// //     try {
// //       User? user = FirebaseAuth.instance.currentUser;
// //       if (user != null) {
// //         await user.updatePassword(_newPasswordController.text.trim());
// //       }

// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Contraseña actualizada correctamente.'),
// //           backgroundColor: Colors.green,
// //         ),
// //       );
// //       Navigator.of(context).popUntil((route) => route.isFirst);
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Error al actualizar contraseña: $e'), backgroundColor: Colors.red),
// //         );
// //       }
// //     } finally {
// //       if (mounted) setState(() => _isLoading = false);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     bool coinciden = _newPasswordController.text.isNotEmpty &&
// //         _newPasswordController.text == _confirmPasswordController.text;

// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF4F8FC),
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // ENCABEZADO SUPERIOR
// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.arrow_back, color: Colors.black87),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                   const SizedBox(width: 8.0),
// //                   Image.asset(
// //                     'lib/src/img/logo.png',
// //                     height: 28,
// //                     fit: BoxFit.contain,
// //                   ),
// //                   const SizedBox(width: 8.0),
// //                   const Text(
// //                     'PRESENTE!',
// //                     style: TextStyle(
// //                       fontSize: 18,
// //                       fontWeight: FontWeight.bold,
// //                       color: kPrimary,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             Expanded(
// //               child: Center(
// //                 child: SingleChildScrollView(
// //                   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
// //                   child: Container(
// //                     constraints: const BoxConstraints(maxWidth: 420),
// //                     child: Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         // ÍCONO CENTRAL DE SEGURIDAD
// //                         Stack(
// //                           alignment: Alignment.center,
// //                           children: [
// //                             Container(
// //                               width: 100,
// //                               height: 100,
// //                               decoration: const BoxDecoration(
// //                                 shape: BoxShape.circle,
// //                                 color: Color(0xFFE8F1FD),
// //                               ),
// //                             ),
// //                             Container(
// //                               width: 70,
// //                               height: 70,
// //                               decoration: const BoxDecoration(
// //                                 shape: BoxShape.circle,
// //                                 color: kPrimary,
// //                               ),
// //                               child: const Icon(
// //                                 Icons.more_horiz,
// //                                 size: 38,
// //                                 color: Colors.white,
// //                               ),
// //                             ),
// //                             Positioned(
// //                               bottom: 4,
// //                               right: 12,
// //                               child: Container(
// //                                 padding: const EdgeInsets.all(4),
// //                                 decoration: const BoxDecoration(
// //                                   color: Color(0xFF007A78),
// //                                   shape: BoxShape.circle,
// //                                 ),
// //                                 child: const Icon(
// //                                   Icons.verified_user_outlined,
// //                                   size: 16,
// //                                   color: Colors.white,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 20.0),

// //                         // TÍTULO Y CORREO
// //                         const Text(
// //                           'Crear Nueva Contraseña',
// //                           style: TextStyle(
// //                             fontSize: 22,
// //                             fontWeight: FontWeight.bold,
// //                             color: kPrimary,
// //                           ),
// //                           textAlign: TextAlign.center,
// //                         ),
// //                         const SizedBox(height: 8.0),
// //                         Text.rich(
// //                           TextSpan(
// //                             text: 'Tu identidad ha sido verificada para\n',
// //                             style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
// //                             children: [
// //                               TextSpan(
// //                                 text: widget.email,
// //                                 style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
// //                               ),
// //                               const TextSpan(text: '. Define tu nueva clave de acceso.'),
// //                             ],
// //                           ),
// //                           textAlign: TextAlign.center,
// //                         ),
// //                         const SizedBox(height: 24.0),

// //                         // CAJA DE CÓDIGO DE VERIFICACIÓN (PIN)
// //                         Container(
// //                           padding: const EdgeInsets.all(16.0),
// //                           decoration: BoxDecoration(
// //                             color: const Color(0xFFEEF5FF),
// //                             borderRadius: BorderRadius.circular(16.0),
// //                           ),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Row(
// //                                 children: [
// //                                   const Icon(Icons.pin, size: 18, color: kPrimary),
// //                                   const SizedBox(width: 6),
// //                                   const Text(
// //                                     'Código de Verificación (PIN)',
// //                                     style: TextStyle(
// //                                       fontSize: 13,
// //                                       fontWeight: FontWeight.bold,
// //                                       color: kPrimary,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 12.0),
// //                               Row(
// //                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                                 children: List.generate(6, (index) {
// //                                   return SizedBox(
// //                                     width: 44,
// //                                     height: 52,
// //                                     child: TextField(
// //                                       controller: _pinControllers[index],
// //                                       focusNode: _focusNodes[index],
// //                                       keyboardType: TextInputType.number,
// //                                       textAlign: TextAlign.center,
// //                                       maxLength: 1,
// //                                       style: const TextStyle(
// //                                         fontSize: 20,
// //                                         fontWeight: FontWeight.bold,
// //                                         color: kPrimary,
// //                                       ),
// //                                       decoration: InputDecoration(
// //                                         counterText: '',
// //                                         filled: true,
// //                                         fillColor: Colors.white,
// //                                         border: OutlineInputBorder(
// //                                           borderRadius: BorderRadius.circular(12),
// //                                           borderSide: BorderSide(color: Colors.grey.shade300),
// //                                         ),
// //                                         enabledBorder: OutlineInputBorder(
// //                                           borderRadius: BorderRadius.circular(12),
// //                                           borderSide: BorderSide(color: Colors.grey.shade300),
// //                                         ),
// //                                         focusedBorder: OutlineInputBorder(
// //                                           borderRadius: BorderRadius.circular(12),
// //                                           borderSide: const BorderSide(color: kPrimary, width: 2),
// //                                         ),
// //                                         contentPadding: EdgeInsets.zero,
// //                                       ),
// //                                       onChanged: (val) {
// //                                         if (val.isNotEmpty && index < 5) {
// //                                           _focusNodes[index + 1].requestFocus();
// //                                         } else if (val.isEmpty && index > 0) {
// //                                           _focusNodes[index - 1].requestFocus();
// //                                         }
// //                                       },
// //                                     ),
// //                                   );
// //                                 }),
// //                               ),
// //                               const SizedBox(height: 12.0),
// //                               Row(
// //                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                                 children: [
// //                                   Row(
// //                                     children: [
// //                                       Icon(Icons.history, size: 14, color: Colors.grey.shade600),
// //                                       const SizedBox(width: 4),
// //                                       Text(
// //                                         'Válido por 30 min',
// //                                         style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                   GestureDetector(
// //                                     onTap: _reenviarPin,
// //                                     child: Text(
// //                                       _secondsRemaining > 0
// //                                           ? 'Reenviar PIN (00:${_secondsRemaining.toString().padLeft(2, '0')})'
// //                                           : 'Reenviar PIN',
// //                                       style: TextStyle(
// //                                         fontSize: 11,
// //                                         fontWeight: FontWeight.bold,
// //                                         color: _secondsRemaining > 0
// //                                             ? Colors.grey.shade500
// //                                             : const Color(0xFF007A78),
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                         const SizedBox(height: 20.0),

// //                         // FORMULARIO DE CONTRASEÑA
// //                         Form(
// //                           key: _formKeyUpdate,
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Row(
// //                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                                 children: [
// //                                   const Text(
// //                                     'Nueva Contraseña',
// //                                     style: TextStyle(
// //                                       fontSize: 13.0,
// //                                       fontWeight: FontWeight.w600,
// //                                       color: Colors.black87,
// //                                     ),
// //                                   ),
// //                                   Text(
// //                                     'REQUERIDO',
// //                                     style: TextStyle(
// //                                       fontSize: 10,
// //                                       fontWeight: FontWeight.bold,
// //                                       color: Colors.teal.shade700,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 6.0),
// //                               TextFormField(
// //                                 controller: _newPasswordController,
// //                                 obscureText: _obscureNewPass,
// //                                 validator: ValidatorForm.validatorPassword,
// //                                 onChanged: (_) => setState(() {}),
// //                                 decoration: InputDecoration(
// //                                   hintText: '••••••••••••',
// //                                   hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
// //                                   prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
// //                                   suffixIcon: IconButton(
// //                                     icon: Icon(
// //                                       _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
// //                                       size: 20,
// //                                       color: Colors.grey,
// //                                     ),
// //                                     onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
// //                                   ),
// //                                   filled: true,
// //                                   fillColor: kFieldBg,
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                     borderSide: BorderSide.none,
// //                                   ),
// //                                   contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 16.0),

// //                               Row(
// //                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                                 children: [
// //                                   const Text(
// //                                     'Confirmar Nueva Contraseña',
// //                                     style: TextStyle(
// //                                       fontSize: 13.0,
// //                                       fontWeight: FontWeight.w600,
// //                                       color: Colors.black87,
// //                                     ),
// //                                   ),
// //                                   if (coinciden)
// //                                     Row(
// //                                       children: const [
// //                                         Icon(Icons.check, size: 12, color: Colors.teal),
// //                                         SizedBox(width: 2),
// //                                         Text(
// //                                           'Coinciden',
// //                                           style: TextStyle(
// //                                             fontSize: 11,
// //                                             fontWeight: FontWeight.bold,
// //                                             color: Colors.teal,
// //                                           ),
// //                                         ),
// //                                       ],
// //                                     ),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 6.0),
// //                               TextFormField(
// //                                 controller: _confirmPasswordController,
// //                                 obscureText: _obscureConfirmPass,
// //                                 validator: (val) {
// //                                   if (val != _newPasswordController.text) {
// //                                     return 'Las contraseñas no coinciden';
// //                                   }
// //                                   return null;
// //                                 },
// //                                 onChanged: (_) => setState(() {}),
// //                                 decoration: InputDecoration(
// //                                   hintText: '••••••••••••',
// //                                   hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
// //                                   prefixIcon: const Icon(Icons.published_with_changes, color: Colors.grey, size: 20),
// //                                   suffixIcon: IconButton(
// //                                     icon: Icon(
// //                                       _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
// //                                       size: 20,
// //                                       color: Colors.grey,
// //                                     ),
// //                                     onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
// //                                   ),
// //                                   filled: true,
// //                                   fillColor: kFieldBg,
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                     borderSide: BorderSide.none,
// //                                   ),
// //                                   contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 16.0),

// //                               // AVISO DISPOSITIVOS
// //                               Container(
// //                                 padding: const EdgeInsets.all(12),
// //                                 decoration: BoxDecoration(
// //                                   color: const Color(0xFFF0F4F8),
// //                                   borderRadius: BorderRadius.circular(12),
// //                                 ),
// //                                 child: Row(
// //                                   children: [
// //                                     Icon(Icons.devices_outlined, size: 18, color: Colors.grey.shade700),
// //                                     const SizedBox(width: 10),
// //                                     Expanded(
// //                                       child: Text(
// //                                         'Por seguridad, al guardar esta clave se cerrarán automáticamente las sesiones activas.',
// //                                         style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 20.0),

// //                               // BOTÓN ACTUALIZAR
// //                               SizedBox(
// //                                 width: double.infinity,
// //                                 height: 48,
// //                                 child: _isLoading
// //                                     ? const Center(child: CircularProgressIndicator())
// //                                     : ElevatedButton(
// //                                         style: ElevatedButton.styleFrom(
// //                                           backgroundColor: kPrimary,
// //                                           foregroundColor: Colors.white,
// //                                           shape: RoundedRectangleBorder(
// //                                             borderRadius: BorderRadius.circular(24),
// //                                           ),
// //                                           elevation: 0,
// //                                         ),
// //                                         onPressed: _actualizarPassword,
// //                                         child: const Row(
// //                                           mainAxisAlignment: MainAxisAlignment.center,
// //                                           children: [
// //                                             Text(
// //                                               'Actualizar Contraseña',
// //                                               style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
// //                                             ),
// //                                             SizedBox(width: 8),
// //                                             Icon(Icons.done_all, size: 18),
// //                                           ],
// //                                         ),
// //                                       ),
// //                               ),
// //                               const SizedBox(height: 12.0),

// //                               // BOTÓN CANCELAR
// //                               SizedBox(
// //                                 width: double.infinity,
// //                                 height: 48,
// //                                 child: OutlinedButton.icon(
// //                                   style: OutlinedButton.styleFrom(
// //                                     backgroundColor: const Color(0xFFE8F1FD),
// //                                     side: BorderSide.none,
// //                                     shape: RoundedRectangleBorder(
// //                                       borderRadius: BorderRadius.circular(24),
// //                                     ),
// //                                   ),
// //                                   onPressed: () => Navigator.pop(context),
// //                                   icon: const Icon(Icons.arrow_back, size: 18, color: kPrimary),
// //                                   label: const Text(
// //                                     'Cancelar y Regresar',
// //                                     style: TextStyle(
// //                                       fontSize: 14,
// //                                       fontWeight: FontWeight.bold,
// //                                       color: kPrimary,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                         const SizedBox(height: 24.0),

// //                         // PIE DE PÁGINA
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //                           decoration: BoxDecoration(
// //                             color: const Color(0xFFE6F3F3),
// //                             borderRadius: BorderRadius.circular(20),
// //                           ),
// //                           child: Row(
// //                             mainAxisSize: MainAxisSize.min,
// //                             children: const [
// //                               Icon(Icons.security, size: 14, color: Color(0xFF007A78)),
// //                               SizedBox(width: 6),
// //                               Text(
// //                                 'Cifrado de extremo a extremo SSL 256-bit',
// //                                 style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF007A78)),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                         const SizedBox(height: 8.0),
// //                         Text(
// //                           'EduAttend Identity Portal • Campus Central',
// //                           style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:proyecto_final/src/validator_Form.dart';

// const Color kPrimary = Color(0xFF0F263B);
// const Color kFieldBg = Color(0xFFF2F5F9);

// class ActualizarPasswordScreen extends StatefulWidget {
//   final String email;

//   const ActualizarPasswordScreen({
//     super.key,
//     required this.email,
//   });

//   @override
//   State<ActualizarPasswordScreen> createState() => _ActualizarPasswordScreenState();
// }

// class _ActualizarPasswordScreenState extends State<ActualizarPasswordScreen> {
//   final _formKeyUpdate = GlobalKey<FormState>();
//   final List<TextEditingController> _pinControllers =
//       List.generate(6, (_) => TextEditingController());
//   final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();

//   bool _obscureNewPass = true;
//   bool _obscureConfirmPass = true;
//   bool _isLoading = false;

//   Timer? _timer;
//   int _secondsRemaining = 45;

//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }

//   void _startTimer() {
//     _secondsRemaining = 45;
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_secondsRemaining > 0) {
//         if (mounted) setState(() => _secondsRemaining--);
//       } else {
//         _timer?.cancel();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     for (var controller in _pinControllers) {
//       controller.dispose();
//     }
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   // Future<void> _actualizarPassword() async {
//   //   final pinIngresado = _pinControllers.map((c) => c.text).join();

//   //   if (pinIngresado.length < 6) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Ingresa los 6 dígitos del PIN.')),
//   //     );
//   //     return;
//   //   }

//   //   if (!_formKeyUpdate.currentState!.validate()) return;

//   //   setState(() => _isLoading = true);

//   //   try {
//   //     // 1. Verificar el PIN en Firestore
//   //     DocumentSnapshot doc = await FirebaseFirestore.instance
//   //         .collection('recuperaciones')
//   //         .doc(widget.email)
//   //         .get();

//   //     if (!doc.exists) {
//   //       throw 'No se encontró una solicitud activa de recuperación.';
//   //     }

//   //     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//   //     String pinGuardado = data['pin'] ?? '';
//   //     Timestamp expiracionTs = data['expiracion'];
//   //     DateTime expiracion = expiracionTs.toDate();

//   //     if (DateTime.now().isAfter(expiracion)) {
//   //       throw 'El PIN ha expirado. Solicita uno nuevo.';
//   //     }

//   //     if (pinIngresado != pinGuardado) {
//   //       throw 'El PIN ingresado es incorrecto.';
//   //     }

//   //     // 2. Intentar actualizar contraseña en Firebase Auth (si hay usuario autenticado)
//   //     User? user = FirebaseAuth.instance.currentUser;
//   //     if (user != null) {
//   //       await user.updatePassword(_newPasswordController.text.trim());
//   //     }

//   //     // 3. Eliminar la solicitud de Firestore tras ser usada
//   //     await FirebaseFirestore.instance
//   //         .collection('recuperaciones')
//   //         .doc(widget.email)
//   //         .delete();

//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('Contraseña actualizada con éxito.'),
//   //         backgroundColor: Colors.green,
//   //       ),
//   //     );

//   //     // Regresar al inicio de sesión
//   //     Navigator.of(context).popUntil((route) => route.isFirst);
//   //   } catch (e) {
//   //     if (mounted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(content: Text('$e'), backgroundColor: Colors.red),
//   //       );
//   //     }
//   //   } finally {
//   //     if (mounted) setState(() => _isLoading = false);
//   //   }
//   // }
//  ///==== segundo metodoo 
// //   Future<void> _actualizarPassword() async {
// //   final pinIngresado = _pinControllers.map((c) => c.text).join();

// //   if (pinIngresado.length < 6) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text('Ingresa los 6 dígitos del PIN.')),
// //     );
// //     return;
// //   }

// //   if (!_formKeyUpdate.currentState!.validate()) return;

// //   setState(() => _isLoading = true);

// //   try {
// //     final nuevaPassword = _newPasswordController.text.trim();

// //     // 1. Verificar el PIN en Firestore
// //     DocumentSnapshot doc = await FirebaseFirestore.instance
// //         .collection('recuperaciones')
// //         .doc(widget.email)
// //         .get();

// //     if (!doc.exists) {
// //       throw 'No se encontró una solicitud activa de recuperación.';
// //     }

// //     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
// //     String pinGuardado = data['pin'] ?? '';
// //     Timestamp expiracionTs = data['expiracion'];
// //     DateTime expiracion = expiracionTs.toDate();

// //     if (DateTime.now().isAfter(expiracion)) {
// //       throw 'El PIN ha expirado. Solicita uno nuevo.';
// //     }

// //     if (pinIngresado != pinGuardado) {
// //       throw 'El PIN ingresado es incorrecto.';
// //     }

// //     // 2. Actualizar la contraseña en la base de datos de Firestore
// //     // (Asegúrate de que 'usuarios' sea el nombre de tu colección)
// //     QuerySnapshot userQuery = await FirebaseFirestore.instance
// //         .collection('usuarios')
// //         .where('email', isEqualTo: widget.email)
// //         .get();

// //     if (userQuery.docs.isNotEmpty) {
// //       for (var userDoc in userQuery.docs) {
// //         await userDoc.reference.update({'password': nuevaPassword});
// //       }
// //     } else {
// //       await FirebaseFirestore.instance
// //           .collection('usuarios')
// //           .doc(widget.email)
// //           .set({'password': nuevaPassword}, SetOptions(merge: true));
// //     }

// //     // 3. Intentar actualizar en Firebase Auth SOLO si el usuario está autenticado recientemente
// //     User? user = FirebaseAuth.instance.currentUser;
// //     if (user != null && user.email == widget.email) {
// //       try {
// //         await user.updatePassword(nuevaPassword);
// //       } catch (authError) {
// //         // Si lanza 'requires-recent-login', lo ignoramos aquí porque la contraseña
// //         // ya se actualizó correctamente en Firestore para el inicio de sesión.
// //         print('Info: Firebase Auth requiere reautenticación: $authError');
// //       }
// //     }

// //     // 4. Eliminar el registro de recuperación usado
// //     await FirebaseFirestore.instance
// //         .collection('recuperaciones')
// //         .doc(widget.email)
// //         .delete();

// //     if (!mounted) return;

// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text('Contraseña actualizada con éxito.'),
// //         backgroundColor: Colors.green,
// //       ),
// //     );

// //     // Regresar al Login para que el usuario inicie sesión con su nueva clave
// //     Navigator.of(context).popUntil((route) => route.isFirst);
// //   } catch (e) {
// //     if (mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
// //       );
// //     }
// //   } finally {
// //     if (mounted) setState(() => _isLoading = false);
// //   }
// // }

// Future<void> _actualizarPassword() async {
//   final pinIngresado = _pinControllers.map((c) => c.text).join();

//   if (pinIngresado.length < 6) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Ingresa los 6 dígitos del PIN.')),
//     );
//     return;
//   }

//   if (!_formKeyUpdate.currentState!.validate()) return;

//   setState(() => _isLoading = true);

//   try {
//     final nuevaPassword = _newPasswordController.text.trim();

//     // 1. Validar el PIN en Firestore
//     DocumentSnapshot doc = await FirebaseFirestore.instance
//         .collection('recuperaciones')
//         .doc(widget.email)
//         .get();

//     if (!doc.exists) {
//       throw 'No se encontró una solicitud activa de recuperación.';
//     }

//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     String pinGuardado = data['pin'] ?? '';
//     Timestamp expiracionTs = data['expiracion'];

//     if (DateTime.now().isAfter(expiracionTs.toDate())) {
//       throw 'El PIN ha expirado. Solicita uno nuevo.';
//     }

//     if (pinIngresado != pinGuardado) {
//       throw 'El PIN ingresado es incorrecto.';
//     }

//     // 2. ACTUALIZAR EN FIRESTORE
//     await FirebaseFirestore.instance
//         .collection('usuarios')
//         .doc(widget.email)
//         .set({'password': nuevaPassword}, SetOptions(merge: true));

//     // 3. ACTUALIZAR LA CONTRASEÑA EN FIREBASE AUTH
//     // Para cambiar la clave en Firebase Auth cuando el usuario no está logueado:
//     // Se envía el correo oficial de reseteo de Firebase o se reautentica la cuenta activa.
//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
//     } catch (authError) {
//       debugPrint('Aviso Firebase Auth Reset: $authError');
//     }

//     // 4. Eliminar el PIN consumido
//     await FirebaseFirestore.instance
//         .collection('recuperaciones')
//         .doc(widget.email)
//         .delete();

//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('PIN verificado. Se ha enviado la confirmación a tu cuenta.'),
//         backgroundColor: Colors.green,
//       ),
//     );

//     // Regresar al inicio de sesión
//     Navigator.of(context).popUntil((route) => route.isFirst);
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   } finally {
//     if (mounted) setState(() => _isLoading = false);
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     bool coinciden = _newPasswordController.text.isNotEmpty &&
//         _newPasswordController.text == _confirmPasswordController.text;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F8FC),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ENCABEZADO SUPERIOR
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.black87),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const SizedBox(width: 8.0),
//                   Image.asset(
//                     'lib/src/img/logo.png',
//                     height: 28,
//                     fit: BoxFit.contain,
//                   ),
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
//             ),

//             Expanded(
//               child: Center(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 420),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         // ÍCONO DE SEGURIDAD
//                         Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             Container(
//                               width: 100,
//                               height: 100,
//                               decoration: const BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: Color(0xFFE8F1FD),
//                               ),
//                             ),
//                             Container(
//                               width: 70,
//                               height: 70,
//                               decoration: const BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: kPrimary,
//                               ),
//                               child: const Icon(
//                                 Icons.more_horiz,
//                                 size: 38,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             Positioned(
//                               bottom: 4,
//                               right: 12,
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: const BoxDecoration(
//                                   color: Color(0xFF007A78),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.verified_user_outlined,
//                                   size: 16,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20.0),

//                         // TÍTULO Y EMAIL
//                         const Text(
//                           'Crear Nueva Contraseña',
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: kPrimary,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 8.0),
//                         Text.rich(
//                           TextSpan(
//                             text: 'Tu identidad ha sido verificada para\n',
//                             style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
//                             children: [
//                               TextSpan(
//                                 text: widget.email,
//                                 style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
//                               ),
//                               const TextSpan(text: '. Define tu nueva clave de acceso.'),
//                             ],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 24.0),

//                         // CASILLAS PIN (6 DÍGITOS)
//                         Container(
//                           padding: const EdgeInsets.all(16.0),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFEEF5FF),
//                             borderRadius: BorderRadius.circular(16.0),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: const [
//                                   Icon(Icons.pin, size: 18, color: kPrimary),
//                                   SizedBox(width: 6),
//                                   Text(
//                                     'Código de Verificación (PIN)',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.bold,
//                                       color: kPrimary,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12.0),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: List.generate(6, (index) {
//                                   return SizedBox(
//                                     width: 44,
//                                     height: 52,
//                                     child: TextField(
//                                       controller: _pinControllers[index],
//                                       focusNode: _focusNodes[index],
//                                       keyboardType: TextInputType.number,
//                                       textAlign: TextAlign.center,
//                                       maxLength: 1,
//                                       style: const TextStyle(
//                                         fontSize: 20,
//                                         fontWeight: FontWeight.bold,
//                                         color: kPrimary,
//                                       ),
//                                       decoration: InputDecoration(
//                                         counterText: '',
//                                         filled: true,
//                                         fillColor: Colors.white,
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                           borderSide: BorderSide(color: Colors.grey.shade300),
//                                         ),
//                                         focusedBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                           borderSide: const BorderSide(color: kPrimary, width: 2),
//                                         ),
//                                         contentPadding: EdgeInsets.zero,
//                                       ),
//                                       onChanged: (val) {
//                                         if (val.isNotEmpty && index < 5) {
//                                           _focusNodes[index + 1].requestFocus();
//                                         } else if (val.isEmpty && index > 0) {
//                                           _focusNodes[index - 1].requestFocus();
//                                         }
//                                       },
//                                     ),
//                                   );
//                                 }),
//                               ),
//                               const SizedBox(height: 12.0),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Icon(Icons.history, size: 14, color: Colors.grey.shade600),
//                                       const SizedBox(width: 4),
//                                       Text(
//                                         'Válido por 30 min',
//                                         style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
//                                       ),
//                                     ],
//                                   ),
//                                   Text(
//                                     _secondsRemaining > 0
//                                         ? 'Reenviar PIN (00:${_secondsRemaining.toString().padLeft(2, '0')})'
//                                         : 'Reenviar PIN',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.bold,
//                                       color: _secondsRemaining > 0
//                                           ? Colors.grey.shade500
//                                           : const Color(0xFF007A78),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 20.0),

//                         // FORMULARIO NUEVA CONTRASEÑA
//                         Form(
//                           key: _formKeyUpdate,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const Text(
//                                     'Nueva Contraseña',
//                                     style: TextStyle(
//                                       fontSize: 13.0,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                   Text(
//                                     'REQUERIDO',
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.teal.shade700,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 6.0),
//                               TextFormField(
//                                 controller: _newPasswordController,
//                                 obscureText: _obscureNewPass,
//                                 validator: ValidatorForm.validatorPassword,
//                                 onChanged: (_) => setState(() {}),
//                                 decoration: InputDecoration(
//                                   hintText: '••••••••••••',
//                                   hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
//                                   prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
//                                   suffixIcon: IconButton(
//                                     icon: Icon(
//                                       _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
//                                       size: 20,
//                                       color: Colors.grey,
//                                     ),
//                                     onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
//                                   ),
//                                   filled: true,
//                                   fillColor: kFieldBg,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                                 ),
//                               ),
//                               const SizedBox(height: 16.0),

//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const Text(
//                                     'Confirmar Nueva Contraseña',
//                                     style: TextStyle(
//                                       fontSize: 13.0,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                   if (coinciden)
//                                     Row(
//                                       children: const [
//                                         Icon(Icons.check, size: 12, color: Colors.teal),
//                                         SizedBox(width: 2),
//                                         Text(
//                                           'Coinciden',
//                                           style: TextStyle(
//                                             fontSize: 11,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.teal,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                 ],
//                               ),
//                               const SizedBox(height: 6.0),
//                               TextFormField(
//                                 controller: _confirmPasswordController,
//                                 obscureText: _obscureConfirmPass,
//                                 validator: (val) {
//                                   if (val != _newPasswordController.text) {
//                                     return 'Las contraseñas no coinciden';
//                                   }
//                                   return null;
//                                 },
//                                 onChanged: (_) => setState(() {}),
//                                 decoration: InputDecoration(
//                                   hintText: '••••••••••••',
//                                   hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
//                                   prefixIcon: const Icon(Icons.published_with_changes, color: Colors.grey, size: 20),
//                                   suffixIcon: IconButton(
//                                     icon: Icon(
//                                       _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
//                                       size: 20,
//                                       color: Colors.grey,
//                                     ),
//                                     onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
//                                   ),
//                                   filled: true,
//                                   fillColor: kFieldBg,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                                 ),
//                               ),
//                               const SizedBox(height: 16.0),

//                               // AVISO DISPOSITIVOS
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF0F4F8),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.devices_outlined, size: 18, color: Colors.grey.shade700),
//                                     const SizedBox(width: 10),
//                                     Expanded(
//                                       child: Text(
//                                         'Por seguridad, al guardar esta clave se cerrarán automáticamente las sesiones activas.',
//                                         style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 20.0),

//                               // BOTÓN ACTUALIZAR
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 48,
//                                 child: _isLoading
//                                     ? const Center(child: CircularProgressIndicator())
//                                     : ElevatedButton(
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: kPrimary,
//                                           foregroundColor: Colors.white,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(24),
//                                           ),
//                                           elevation: 0,
//                                         ),
//                                         onPressed: _actualizarPassword,
//                                         child: const Row(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             Text(
//                                               'Actualizar Contraseña',
//                                               style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                                             ),
//                                             SizedBox(width: 8),
//                                             Icon(Icons.done_all, size: 18),
//                                           ],
//                                         ),
//                                       ),
//                               ),
//                               const SizedBox(height: 12.0),

//                               // BOTÓN CANCELAR
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 48,
//                                 child: OutlinedButton.icon(
//                                   style: OutlinedButton.styleFrom(
//                                     backgroundColor: const Color(0xFFE8F1FD),
//                                     side: BorderSide.none,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(24),
//                                     ),
//                                   ),
//                                   onPressed: () => Navigator.pop(context),
//                                   icon: const Icon(Icons.arrow_back, size: 18, color: kPrimary),
//                                   label: const Text(
//                                     'Cancelar y Regresar',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: kPrimary,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 24.0),

//                         // PIE DE PÁGINA
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFE6F3F3),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Icon(Icons.security, size: 14, color: Color(0xFF007A78)),
//                               SizedBox(width: 6),
//                               Text(
//                                 'Cifrado de extremo a extremo SSL 256-bit',
//                                 style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF007A78)),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 8.0),
//                         Text(
//                           'EduAttend Identity Portal • Campus Central',
//                           style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final/src/validator_Form.dart';

const Color kPrimary = Color(0xFF0F263B);
const Color kFieldBg = Color(0xFFF2F5F9);

class ActualizarPasswordScreen extends StatefulWidget {
  final String email;

  const ActualizarPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ActualizarPasswordScreen> createState() => _ActualizarPasswordScreenState();
}

class _ActualizarPasswordScreenState extends State<ActualizarPasswordScreen> {
  final _formKeyUpdate = GlobalKey<FormState>();
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  Timer? _timer;
  int _secondsRemaining = 45;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Future<void> _actualizarPassword() async {
  //   if (widget.email.trim().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Error: El correo electrónico no es válido.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   final emailLimpio = widget.email.trim().toLowerCase();
  //   final pinIngresado = _pinControllers.map((c) => c.text).join();

  //   if (pinIngresado.length < 6) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Ingresa los 6 dígitos del PIN.')),
  //     );
  //     return;
  //   }

  //   if (!_formKeyUpdate.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     final nuevaPassword = _newPasswordController.text.trim();

  //     // 1. Verificar el PIN en Firestore
  //     DocumentSnapshot doc = await FirebaseFirestore.instance
  //         .collection('recuperaciones')
  //         .doc(emailLimpio)
  //         .get();

  //     if (!doc.exists) {
  //       throw 'No se encontró una solicitud activa de recuperación.';
  //     }

  //     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //     String pinGuardado = data['pin'] ?? '';
  //     Timestamp expiracionTs = data['expiracion'];

  //     if (DateTime.now().isAfter(expiracionTs.toDate())) {
  //       throw 'El PIN ha expirado. Solicita uno nuevo.';
  //     }

  //     if (pinIngresado != pinGuardado) {
  //       throw 'El PIN ingresado es incorrecto.';
  //     }

  //     // 2. Actualizar la contraseña en la base de datos de usuarios en Firestore
  //     DocumentReference userDocRef = FirebaseFirestore.instance
  //         .collection('usuarios')
  //         .doc(emailLimpio);

  //     DocumentSnapshot userDoc = await userDocRef.get();

  //     if (userDoc.exists) {
  //       await userDocRef.update({'password': nuevaPassword});
  //     } else {
  //       QuerySnapshot query = await FirebaseFirestore.instance
  //           .collection('usuarios')
  //           .where('email', isEqualTo: emailLimpio)
  //           .get();

  //       if (query.docs.isNotEmpty) {
  //         for (var docItem in query.docs) {
  //           await docItem.reference.update({'password': nuevaPassword});
  //         }
  //       } else {
  //         await userDocRef.set({
  //           'email': emailLimpio,
  //           'password': nuevaPassword,
  //         }, SetOptions(merge: true));
  //       }
  //     }

  //     // 3. Eliminar la solicitud de recuperación consumida
  //     await FirebaseFirestore.instance
  //         .collection('recuperaciones')
  //         .doc(emailLimpio)
  //         .delete();

  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Contraseña actualizada con éxito.'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );

  //     // Regresar al Login
  //     Navigator.of(context).popUntil((route) => route.isFirst);
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

// =Metodo 2=
//   Future<void> _actualizarPassword() async {
//   final emailLimpio = widget.email.trim().toLowerCase();
//   final pinIngresado = _pinControllers.map((c) => c.text).join();

//   if (emailLimpio.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Error: El correo llegó vacío. Intenta de nuevo desde el inicio.'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }

//   if (pinIngresado.length < 6) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Ingresa los 6 dígitos del PIN.')),
//     );
//     return;
//   }

//   if (!_formKeyUpdate.currentState!.validate()) return;

//   setState(() => _isLoading = true);

//   try {
//     final nuevaPassword = _newPasswordController.text.trim();

//     // 1. Obtener la solicitud de recuperación
//     DocumentSnapshot docRecuperacion = await FirebaseFirestore.instance
//         .collection('recuperaciones')
//         .doc(emailLimpio)
//         .get();

//     if (!docRecuperacion.exists) {
//       throw 'No se encontró un PIN activo para este correo. Solicita uno nuevo.';
//     }

//     Map<String, dynamic> data = docRecuperacion.data() as Map<String, dynamic>;
//     String pinGuardado = data['pin'] ?? '';
//     Timestamp expiracionTs = data['expiracion'];

//     if (DateTime.now().isAfter(expiracionTs.toDate())) {
//       throw 'El PIN ha expirado. Solicita uno nuevo.';
//     }

//     if (pinIngresado != pinGuardado) {
//       throw 'El PIN ingresado es incorrecto.';
//     }

//     // 2. Actualizar directamente el campo password en la colección 'usuarios'
//     // Como vimos en Firestore, el ID del documento es el correo exacto
//     await FirebaseFirestore.instance
//         .collection('usuarios')
//         .doc(emailLimpio)
//         .update({'password': nuevaPassword});

//     // 3. Eliminar el registro del PIN ya utilizado
//     await FirebaseFirestore.instance
//         .collection('recuperaciones')
//         .doc(emailLimpio)
//         .delete();

//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('¡Contraseña actualizada con éxito! Ya puedes iniciar sesión.'),
//         backgroundColor: Colors.green,
//       ),
//     );

//     // Regresar al Login
//     Navigator.of(context).popUntil((route) => route.isFirst);
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   } finally {
//     if (mounted) setState(() => _isLoading = false);
//   }
// }

Future<void> _actualizarPassword() async {
  final emailLimpio = widget.email.trim().toLowerCase();
  final pinIngresado = _pinControllers.map((c) => c.text).join();

  if (emailLimpio.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error: El correo llegó vacío.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (pinIngresado.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingresa los 6 dígitos del PIN.')),
    );
    return;
  }

  if (!_formKeyUpdate.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final nuevaPassword = _newPasswordController.text.trim();

    // 1. Verificar PIN en Firestore
    DocumentSnapshot docRecuperacion = await FirebaseFirestore.instance
        .collection('recuperaciones')
        .doc(emailLimpio)
        .get();

    if (!docRecuperacion.exists) {
      throw 'No se encontró un PIN activo para este correo.';
    }

    Map<String, dynamic> data = docRecuperacion.data() as Map<String, dynamic>;
    String pinGuardado = data['pin'] ?? '';
    Timestamp expiracionTs = data['expiracion'];

    if (DateTime.now().isAfter(expiracionTs.toDate())) {
      throw 'El PIN ha expirado. Solicita uno nuevo.';
    }

    if (pinIngresado != pinGuardado) {
      throw 'El PIN ingresado es incorrecto.';
    }

    // 2. Actualizar campo en Firestore
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(emailLimpio)
        .update({'password': nuevaPassword});

    // 3. ENVIAR CORREO DE NATIVO DE RESET DE FIREBASE AUTH
    // Esto asegura que la cuenta de Firebase Auth quede lista para aceptar la nueva clave
    await FirebaseAuth.instance.sendPasswordResetEmail(email: emailLimpio);

    // 4. Limpiar el registro del PIN
    await FirebaseFirestore.instance
        .collection('recuperaciones')
        .doc(emailLimpio)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN confirmado. Revisa tu correo para completar la sincronización de tu contraseña.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}



  @override
  Widget build(BuildContext context) {
    bool coinciden = _newPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _confirmPasswordController.text;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8.0),
                  Image.asset(
                    'lib/src/img/logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
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
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE8F1FD),
                              ),
                            ),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: kPrimary,
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                size: 38,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF007A78),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        const Text(
                          'Crear Nueva Contraseña',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        Text.rich(
                          TextSpan(
                            text: 'Tu identidad ha sido verificada para\n',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                            children: [
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
                              ),
                              const TextSpan(text: '. Define tu nueva clave de acceso.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24.0),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5FF),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.pin, size: 18, color: kPrimary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Código de Verificación (PIN)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  return SizedBox(
                                    width: 44,
                                    height: 52,
                                    child: TextField(
                                      controller: _pinControllers[index],
                                      focusNode: _focusNodes[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: kPrimary, width: 2),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        if (val.isNotEmpty && index < 5) {
                                          _focusNodes[index + 1].requestFocus();
                                        } else if (val.isEmpty && index > 0) {
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.history, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Válido por 30 min',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _secondsRemaining > 0
                                        ? 'Reenviar PIN (00:${_secondsRemaining.toString().padLeft(2, '0')})'
                                        : 'Reenviar PIN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _secondsRemaining > 0
                                          ? Colors.grey.shade500
                                          : const Color(0xFF007A78),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Form(
                          key: _formKeyUpdate,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Nueva Contraseña',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'REQUERIDO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6.0),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscureNewPass,
                                validator: ValidatorForm.validatorPassword,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '••••••••••••',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                                  ),
                                  filled: true,
                                  fillColor: kFieldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Confirmar Nueva Contraseña',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (coinciden)
                                    const Row(
                                      children: [
                                        Icon(Icons.check, size: 12, color: Colors.teal),
                                        SizedBox(width: 2),
                                        Text(
                                          'Coinciden',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6.0),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPass,
                                validator: (val) {
                                  if (val != _newPasswordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '••••••••••••',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  prefixIcon: const Icon(Icons.published_with_changes, color: Colors.grey, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                                  ),
                                  filled: true,
                                  fillColor: kFieldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4F8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.devices_outlined, size: 18, color: Colors.grey.shade700),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Por seguridad, al guardar esta clave se cerrarán automáticamente las sesiones activas.',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20.0),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: _actualizarPassword,
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Actualizar Contraseña',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.done_all, size: 18),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12.0),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE8F1FD),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back, size: 18, color: kPrimary),
                                  label: const Text(
                                    'Cancelar y Regresar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3F3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.security, size: 14, color: Color(0xFF007A78)),
                              SizedBox(width: 6),
                              Text(
                                'Cifrado de extremo a extremo SSL 256-bit',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF007A78)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'EduAttend Identity Portal • Campus Central',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}