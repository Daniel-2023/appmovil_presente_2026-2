import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kPrimary = Color(0xFF0F263B);
const Color kAccent = Color(0xFF007A78);
const Color kFieldBg = Color(0xFFF2F5F9);

class HorarioSlot {
  String sede;
  String bloque;
  String salon;
  TimeOfDay horaInicio;
  TimeOfDay horaFin;
  int radioMetros;

  HorarioSlot({
    this.sede = 'Sede Central (Campus Porvenir)',
    this.bloque = 'Bloque B',
    this.salon = 'Aula B-204',
    this.horaInicio = const TimeOfDay(hour: 8, minute: 0),
    this.horaFin = const TimeOfDay(hour: 10, minute: 0),
    this.radioMetros = 30,
  });

  int get duracionMinutos {
    final inicioMin = horaInicio.hour * 60 + horaInicio.minute;
    final finMin = horaFin.hour * 60 + horaFin.minute;
    final diff = finMin - inicioMin;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toMap(String dia) {
    return {
      'dia': dia,
      'sede': sede,
      'bloque': bloque,
      'salon': salon,
      'radioMetros': radioMetros,
      'horaInicio':
          '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
      'horaFin':
          '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}',
      'duracionMinutos': duracionMinutos,
    };
  }
}

class CrearAsignatura2Screen extends StatefulWidget {
  final String cursoId;
  final String nombreCurso;

  const CrearAsignatura2Screen({
    super.key,
    required this.cursoId,
    required this.nombreCurso,
  });

  @override
  State<CrearAsignatura2Screen> createState() => _CrearAsignatura2ScreenState();
}

class _CrearAsignatura2ScreenState extends State<CrearAsignatura2Screen> {
  final _diasSemana = [
    {'letra': 'L', 'corto': 'Lun', 'completo': 'Lunes'},
    {'letra': 'M', 'corto': 'Mar', 'completo': 'Martes'},
    {'letra': 'X', 'corto': 'Mié', 'completo': 'Miércoles'},
    {'letra': 'J', 'corto': 'Jue', 'completo': 'Jueves'},
    {'letra': 'V', 'corto': 'Vie', 'completo': 'Viernes'},
    {'letra': 'S', 'corto': 'Sáb', 'completo': 'Sábado'},
    {'letra': 'D', 'corto': 'Dom', 'completo': 'Domingo'},
  ];

  // Días seleccionados inicialmente (Lunes y Miércoles como en la referencia)
  final _diasSeleccionados = {'Lunes', 'Miércoles'};

  // Horarios asignados por cada día
  final _horariosPorDia = {
    'Lunes': [
      HorarioSlot(
        sede: 'Sede Central (Campus Porvenir)',
        bloque: 'Bloque B',
        salon: 'Aula B-204',
        radioMetros: 30,
        horaInicio: const TimeOfDay(hour: 8, minute: 0),
        horaFin: const TimeOfDay(hour: 10, minute: 0),
      ),
    ],
    'Miércoles': [
      HorarioSlot(
        sede: 'Sede Central (Campus Porvenir)',
        bloque: 'Bloque C - Tecnología',
        salon: 'Lab Cómputo 2',
        radioMetros: 25,
        horaInicio: const TimeOfDay(hour: 10, minute: 0),
        horaFin: const TimeOfDay(hour: 11, minute: 30),
      ),
    ],
  };

  final _sedes = [
    'Sede Central (Campus Porvenir)',
    'Sede Centro',
    'Sede Social',
  ];

  final _bloques = [
    'Bloque A',
    'Bloque B',
    'Bloque C - Tecnología',
    'Bloque D - Laboratorios',
  ];

  final _salones = [
    'Aula A-101',
    'Aula B-204',
    'Aula B-205',
    'Lab Cómputo 1',
    'Lab Cómputo 2',
    'Auditorio',
  ];

  int _toleranciaMinutos = 15;
  bool _qrDinamicoActivo = true;
  bool _isSaving = false;

  void _toggleDia(String nombreDia) {
    setState(() {
      if (_diasSeleccionados.contains(nombreDia)) {
        if (_diasSeleccionados.length > 1) {
          _diasSeleccionados.remove(nombreDia);
          _horariosPorDia.remove(nombreDia);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debe haber al menos un día seleccionado.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _diasSeleccionados.add(nombreDia);
        _horariosPorDia[nombreDia] = [HorarioSlot()];
      }
    });
  }

  void _agregarSlot(String nombreDia) {
    setState(() {
      _horariosPorDia[nombreDia]?.add(
        HorarioSlot(
          salon: 'Aula B-205',
          horaInicio: const TimeOfDay(hour: 14, minute: 0),
          horaFin: const TimeOfDay(hour: 16, minute: 0),
          radioMetros: 25,
        ),
      );
    });
  }

  void _eliminarSlot(String nombreDia, int index) {
    setState(() {
      final lista = _horariosPorDia[nombreDia];
      if (lista != null && lista.length > 1) {
        lista.removeAt(index);
      }
    });
  }

  Future<void> _seleccionarHora(HorarioSlot slot, {required bool esInicio}) async {
    final inicial = esInicio ? slot.horaInicio : slot.horaFin;
    final picked = await showTimePicker(
      context: context,
      initialTime: inicial,
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

    if (picked != null) {
      setState(() {
        if (esInicio) {
          slot.horaInicio = picked;
        } else {
          slot.horaFin = picked;
        }
      });
    }
  }

  String _formatearHora12(TimeOfDay hora) {
    final hourOfPeriod = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final min = hora.minute.toString().padLeft(2, '0');
    final periodo = hora.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hourOfPeriod.toString().padLeft(2, '0')}:$min $periodo';
  }

  String _formatearDuracion(int totalMinutos) {
    final horas = totalMinutos ~/ 60;
    final minutos = totalMinutos % 60;
    final textoHoras = horas == 1 ? '1 hora' : '$horas horas';
    final textoMin = '${minutos.toString().padLeft(2, '0')} minutos';
    return '$textoHoras con $textoMin';
  }

  Future<void> _guardarYFinalizar() async {
    for (final entry in _horariosPorDia.entries) {
      for (final slot in entry.value) {
        if (slot.duracionMinutos <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'La hora de fin debe ser posterior a la hora de inicio en ${entry.key}.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final listaHorarios = [];
      for (final diaInfo in _diasSemana) {
        final nombreDia = diaInfo['completo']!;
        if (_diasSeleccionados.contains(nombreDia) &&
            _horariosPorDia.containsKey(nombreDia)) {
          for (final slot in _horariosPorDia[nombreDia]!) {
            listaHorarios.add(slot.toMap(nombreDia));
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('asignaturas')
          .doc(widget.cursoId)
          .update({
        'horarios': listaHorarios,
        'toleranciaMinutos': _toleranciaMinutos,
        'metodoValidacion': _qrDinamicoActivo ? 'QR_DINAMICO_15S' : 'MANUAL',
        'configuracionCompleta': true,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Horarios y validación configurados con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diasOrdenados = _diasSemana
        .where((d) => _diasSeleccionados.contains(d['completo']))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO PASO 2 DE 2
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
                        const Text(
                          'PASO 2 DE 2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: kAccent,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 5,
                              decoration: BoxDecoration(
                                color: kAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 22,
                              height: 5,
                              decoration: BoxDecoration(
                                color: kAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Horarios',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.nombreCurso,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kFieldBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.schedule, color: kAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // TARJETA DE DÍAS DE CLASE RECURRENTES
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
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: kAccent, size: 19),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Días de clase recurrentes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF99F6E4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_diasSeleccionados.length} seleccionados',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Horarios y duraciones personalizadas por día',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),

                    // BOTONES DE DÍAS (L M X J V S D)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _diasSemana.map((dia) {
                        final nombreDia = dia['completo']!;
                        final activo = _diasSeleccionados.contains(nombreDia);
                        return GestureDetector(
                          onTap: () => _toggleDia(nombreDia),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 40,
                            height: 54,
                            decoration: BoxDecoration(
                              color: activo ? kPrimary : kFieldBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dia['letra']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: activo ? Colors.white : kPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dia['corto']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: activo
                                        ? Colors.white70
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TÍTULO SECCIÓN HORARIO POR DÍA SELECCIONADO
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: kAccent, size: 19),
                      SizedBox(width: 8),
                      Text(
                        'Horario por día seleccionado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.tune, color: kAccent, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Independientes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // TARJETAS DE CONFIGURACIÓN POR CADA DÍA ACTIVO
              ...diasOrdenados.map((diaInfo) {
                final nombreDia = diaInfo['completo']!;
                final letraDia = diaInfo['letra']!;
                final slots = _horariosPorDia[nombreDia] ?? [];
                final totalMinutosDia =
                    slots.fold(0, (acc, s) => acc + s.duracionMinutos);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CABECERA DE LA TARJETA DEL DÍA
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              letraDia,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombreDia,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                                Text(
                                  '${slots.length} ${slots.length == 1 ? 'horario asignado' : 'horarios asignados'} • Geocerca activa',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: kAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _agregarSlot(nombreDia),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Nuevo horario',
                              style: TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // LISTA DE SLOTS DE HORARIO DEL DÍA
                      ...List.generate(slots.length, (slotIndex) {
                        final slot = slots[slotIndex];
                        final esManana = slot.horaInicio.hour < 12;
                        final etiquetaJornada = esManana ? 'MAÑANA' : 'TARDE';

                        return Container(
                          margin: EdgeInsets.only(
                              bottom: slotIndex < slots.length - 1 ? 16 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'HORARIO ${slotIndex + 1} ($etiquetaJornada)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (slotIndex > 0)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF99F6E4),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Adicional',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => _eliminarSlot(
                                              nombreDia, slotIndex),
                                          child: const Icon(Icons.close,
                                              size: 16,
                                              color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // CAJA DE UBICACIÓN PARA GEOCERCA
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kFieldBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 16, color: kAccent),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ubicación para Geocerca',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: kPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Radio: ${slot.radioMetros}m',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: kAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // DROPDOWN SEDE
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: slot.sede,
                                          isExpanded: true,
                                          icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 18),
                                          items: _sedes.map((s) {
                                            return DropdownMenuItem<String>(
                                              value: s,
                                              child: Text(
                                                'Sede: $s',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: kPrimary),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => slot.sede = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // FILA BLOQUE Y SALÓN
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bloque',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade500),
                                                ),
                                                DropdownButtonHideUnderline(
                                                  child:
                                                      DropdownButton<String>(
                                                    value: slot.bloque,
                                                    isDense: true,
                                                    isExpanded: true,
                                                    icon: const Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        size: 16),
                                                    items: _bloques.map((b) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: b,
                                                        child: Text(
                                                          b,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: kPrimary,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() =>
                                                            slot.bloque = val);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Salón',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade500),
                                                ),
                                                DropdownButtonHideUnderline(
                                                  child:
                                                      DropdownButton<String>(
                                                    value: slot.salon,
                                                    isDense: true,
                                                    isExpanded: true,
                                                    icon: const Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        size: 16),
                                                    items: _salones.map((sa) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: sa,
                                                        child: Text(
                                                          sa,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: kPrimary,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() =>
                                                            slot.salon = val);
                                                      }
                                                    },
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
                              const SizedBox(height: 10),

                              // HORA DE INICIO Y HORA DE FIN
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTimeBox(
                                      titulo: 'Hora de Inicio',
                                      horaTexto:
                                          _formatearHora12(slot.horaInicio),
                                      icon: Icons.alarm,
                                      onTap: () =>
                                          _seleccionarHora(slot, esInicio: true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildTimeBox(
                                      titulo: 'Hora de Fin',
                                      horaTexto: _formatearHora12(slot.horaFin),
                                      icon: Icons.schedule,
                                      onTap: () => _seleccionarHora(slot,
                                          esInicio: false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // DURACIÓN DEL SLOT
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    slots.length > 1
                                        ? 'Duración slot ${slotIndex + 1}:'
                                        : 'Duración total:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    _formatearDuracion(slot.duracionMinutos),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      // DURACIÓN TOTAL ACUMULADA SI HAY MÁS DE UN HORARIO EN EL DÍA
                      if (slots.length > 1) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: kFieldBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Duración total\nacumulada:',
                                style:
                                    TextStyle(fontSize: 12, color: kPrimary),
                              ),
                              Text(
                                _formatearDuracion(totalMinutosDia),
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
                    ],
                  ),
                );
              }),

              // TARJETA TIEMPO LÍMITE DE TOLERANCIA
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
                            Icon(Icons.timer_outlined, color: kAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Tiempo límite de tolerancia',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF99F6E4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Asistencia',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tolerancia máxima tras iniciar la clase para no marcar retraso.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: kFieldBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStepButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (_toleranciaMinutos > 0) {
                                setState(() => _toleranciaMinutos -= 5);
                              }
                            },
                          ),
                          RichText(
                            text: TextSpan(
                              text: '$_toleranciaMinutos ',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'min',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                    color: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStepButton(
                            icon: Icons.add,
                            onTap: () {
                              if (_toleranciaMinutos < 60) {
                                setState(() => _toleranciaMinutos += 5);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // TARJETA MÉTODO DE VALIDACIÓN DE ASISTENCIA
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
                    const Row(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            color: kAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Método de Validación de Asistencia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define la tecnología requerida por los alumnos para registrar su entrada.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => setState(
                          () => _qrDinamicoActivo = !_qrDinamicoActivo),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kFieldBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _qrDinamicoActivo
                                ? kAccent
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.qr_code_2,
                                  color: kPrimary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Flexible(
                                        child: Text(
                                          'Código QR Dinámico',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          'Cada 15s',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Código de un solo uso proyectado en pizarra digital para escaneo presencial simultáneo.',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _qrDinamicoActivo ? kAccent : Colors.white,
                                border: Border.all(
                                  color: _qrDinamicoActivo
                                      ? kAccent
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: _qrDinamicoActivo
                                  ? const Icon(Icons.check,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BOTONES INFERIORES: ATRÁS Y GUARDAR Y FINALIZAR
              Row(
                children: [
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E8F0),
                        foregroundColor: kPrimary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      child: const Text(
                        'Atrás',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(color: kPrimary))
                          : ElevatedButton(
                              onPressed: _guardarYFinalizar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: const StadiumBorder(),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 19, color: Color(0xFF5EEAD4)),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Guardar y Finalizar',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required String titulo,
    required String horaTexto,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kFieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: kAccent),
                ),
                const SizedBox(width: 8),
                Text(
                  horaTexto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
    );
  }
}