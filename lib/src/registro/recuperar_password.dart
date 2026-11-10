


// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:proyecto_final/src/validator_Form.dart';

// // Asegúrate de importar la pantalla de actualización de contraseña
// import 'actualizar_password.dart';

// const Color kPrimary = Color(0xFF0F263B);
// const Color kFieldBg = Color(0xFFF2F5F9);

// class RecuperarPasswordScreen extends StatefulWidget {
//   const RecuperarPasswordScreen({super.key});

//   @override
//   State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
// }

// class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
//   final _formKeyReset = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   Future<void> _enviarCorreoRecuperacion() async {
//     if (!_formKeyReset.currentState!.validate()) return;

//     final email = _emailController.text.trim().toLowerCase();
//     setState(() => _isLoading = true);

//     try {
//       // 1. Generar PIN aleatorio de 6 dígitos (rango 100000 - 999999)
//       final String pinGenerado = (100000 + Random().nextInt(900000)).toString();

//       // 2. Enviar correo de restablecimiento vía Firebase Auth
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

//       if (!mounted) return;

//       // 3. Notificar al usuario (muestra el PIN en pantalla para pruebas)
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('PIN generado para pruebas: $pinGenerado'),
//           backgroundColor: const Color(0xFF007A78),
//           duration: const Duration(seconds: 4),
//         ),
//       );

//       // 4. Redirigir automáticamente a la pantalla de actualización pasando el correo y el PIN
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ActualizarPasswordScreen(
//             email: email,
//             pinGenerado: pinGenerado,
//           ),
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       String mensajeError = 'Error al enviar el correo';
//       if (e.code == 'user-not-found') {
//         mensajeError = 'No existe ningún usuario registrado con este correo.';
//       } else if (e.code == 'invalid-email') {
//         mensajeError = 'El formato del correo no es válido.';
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
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
//                         // ÍCONO CENTRAL CON GLOW CIRCULAR
//                         Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             Container(
//                               width: 130,
//                               height: 130,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: const Color(0xFF007A78).withOpacity(0.08),
//                               ),
//                             ),
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
//                                 color: Colors.white,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black12,
//                                     blurRadius: 10,
//                                     offset: Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               child: const Icon(
//                                 Icons.lock,
//                                 size: 36,
//                                 color: kPrimary,
//                               ),
//                             ),
//                             Positioned(
//                               top: 8,
//                               right: 12,
//                               child: Container(
//                                 padding: const EdgeInsets.all(6),
//                                 decoration: const BoxDecoration(
//                                   color: Color(0xFF007A78),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.vpn_key,
//                                   size: 14,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24.0),

//                         // TÍTULO Y DESCRIPCIÓN
//                         const Text(
//                           '¿Problemas de acceso?',
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: kPrimary,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 10.0),
//                         Text(
//                           'Ingresa tu correo electrónico registrado y te enviaremos un pin para recuperar contraseña.',
//                           style: TextStyle(
//                             fontSize: 13,
//                             height: 1.4,
//                             color: Colors.grey.shade600,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 28.0),

//                         // TARJETA DEL FORMULARIO
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20.0),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.04),
//                                 blurRadius: 16,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           padding: const EdgeInsets.all(20.0),
//                           child: Form(
//                             key: _formKeyReset,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   'Correo electrónico',
//                                   style: TextStyle(
//                                     fontSize: 13.0,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8.0),
//                                 TextFormField(
//                                   controller: _emailController,
//                                   validator: ValidatorForm.validatorEmail,
//                                   keyboardType: TextInputType.emailAddress,
//                                   decoration: InputDecoration(
//                                     hintText: 'profesor.martinez@universidad.edu',
//                                     hintStyle: TextStyle(
//                                       color: Colors.grey.shade400,
//                                       fontSize: 14.0,
//                                     ),
//                                     prefixIcon: const Icon(
//                                       Icons.email_outlined,
//                                       color: Colors.grey,
//                                       size: 20,
//                                     ),
//                                     filled: true,
//                                     fillColor: kFieldBg,
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: BorderSide.none,
//                                     ),
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 14,
//                                       vertical: 14,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 10.0),
//                                 Text(
//                                   'Usa la cuenta vinculada a tu perfil académico.',
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.grey.shade500,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 20.0),

//                                 // BOTÓN DE ENVIAR ENLACE
//                                 SizedBox(
//                                   width: double.infinity,
//                                   height: 48,
//                                   child: _isLoading
//                                       ? const Center(child: CircularProgressIndicator())
//                                       : ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: kPrimary,
//                                             foregroundColor: Colors.white,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(24),
//                                             ),
//                                             elevation: 0,
//                                           ),
//                                           onPressed: _enviarCorreoRecuperacion,
//                                           child: const Row(
//                                             mainAxisAlignment: MainAxisAlignment.center,
//                                             children: [
//                                               Text(
//                                                 'Enviar Enlace',
//                                                 style: TextStyle(
//                                                   fontSize: 15,
//                                                   fontWeight: FontWeight.bold,
//                                                 ),
//                                               ),
//                                               SizedBox(width: 8),
//                                               Icon(Icons.send_outlined, size: 18),
//                                             ],
//                                           ),
//                                         ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20.0),

//                         // TARJETA DE VALIDACIÓN INSTITUCIONAL
//                         Container(
//                           padding: const EdgeInsets.all(16.0),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFEEF5FF),
//                             borderRadius: BorderRadius.circular(16.0),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: const BoxDecoration(
//                                   color: Color(0xFFBCE3E1),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.shield_outlined,
//                                   color: Color(0xFF007A78),
//                                   size: 20,
//                                 ),
//                               ),
//                               const SizedBox(width: 14.0),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text(
//                                       'Validación Institucional',
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.bold,
//                                         color: kPrimary,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 2.0),
//                                     Text(
//                                       'Los enlaces caducan automáticamente tras 30 minutos.',
//                                       style: TextStyle(
//                                         fontSize: 11,
//                                         color: Colors.grey.shade700,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 24.0),

//                         // PIE DE PÁGINA
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.lock_outline,
//                               size: 13,
//                               color: Colors.grey.shade500,
//                             ),
//                             const SizedBox(width: 6.0),
//                             Text(
//                               'Protegido por Campus Conectado • SSL 256-bit',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey.shade500,
//                               ),
//                             ),
//                           ],
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

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final/src/validator_Form.dart';

import 'actualizar_password.dart';

const Color kPrimary = Color(0xFF0F263B);
const Color kFieldBg = Color(0xFFF2F5F9);

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKeyReset = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarCorreoRecuperacion() async {
    if (!_formKeyReset.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    setState(() => _isLoading = true);

    try {
      // 1. Generar PIN aleatorio de 6 dígitos
      final String pinGenerado = (100000 + Random().nextInt(900000)).toString();
      final DateTime expiracion = DateTime.now().add(const Duration(minutes: 30));

      // 2. Guardar en Firestore para validarlo en la siguiente pantalla
      await FirebaseFirestore.instance.collection('recuperaciones').doc(email).set({
        //'email': email,
        'pin': pinGenerado,
        'expiracion': expiracion,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      // 3. Credenciales de EmailJS
      const String serviceId = 'service_cs2qqc4';
      const String templateId = 'template_12joihd'; // Reemplaza por tu Template ID
      const String publicKey = 'Xqd_nOD2Pit2aarAa';   // Reemplaza por tu Public Key

      // 4. Petición a la API de EmailJS
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': email,
            'pin': pinGenerado,
          },
        }),
      );

      if (response.statusCode != 200) {
        throw 'Error al enviar el correo: ${response.body}';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha enviado el PIN de 6 dígitos a tu correo.'),
          backgroundColor: Color(0xFF007A78),
        ),
      );

      // 5. Navegar a la pantalla de verificación del PIN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActualizarPasswordScreen(email: email),
        ),
      );
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
                  Image.asset('lib/src/img/logo.png', height: 28, fit: BoxFit.contain),
                  const SizedBox(width: 8.0),
                  const Text('PRESENTE!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimary)),
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
                            Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF007A78).withOpacity(0.08))),
                            Container(width: 100, height: 100, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8F1FD))),
                            Container(width: 70, height: 70, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]), child: const Icon(Icons.lock, size: 36, color: kPrimary)),
                            Positioned(top: 8, right: 12, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF007A78), shape: BoxShape.circle), child: const Icon(Icons.vpn_key, size: 14, color: Colors.white))),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        const Text('¿Problemas de acceso?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary), textAlign: TextAlign.center),
                        const SizedBox(height: 10.0),
                        Text('Ingresa tu correo electrónico registrado y te enviaremos un pin para recuperar contraseña.', style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade600), textAlign: TextAlign.center),
                        const SizedBox(height: 28.0),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))]),
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKeyReset,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Correo electrónico', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 8.0),
                                TextFormField(
                                  controller: _emailController,
                                  validator: ValidatorForm.validatorEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'profesor.martinez@universidad.edu',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.0),
                                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey, size: 20),
                                    filled: true,
                                    fillColor: kFieldBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Text('Usa la cuenta vinculada a tu perfil académico.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                const SizedBox(height: 20.0),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: _isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0),
                                          onPressed: _enviarCorreoRecuperacion,
                                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Enviar Enlace', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.send_outlined, size: 18)]),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(color: const Color(0xFFEEF5FF), borderRadius: BorderRadius.circular(16.0)),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFBCE3E1), shape: BoxShape.circle), child: const Icon(Icons.shield_outlined, color: Color(0xFF007A78), size: 20)),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Validación Institucional', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary)),
                                    const SizedBox(height: 2.0),
                                    Text('Los enlaces caducan automáticamente tras 30 minutos.', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 6.0),
                            Text('Protegido por Campus Conectado • SSL 256-bit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                          ],
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