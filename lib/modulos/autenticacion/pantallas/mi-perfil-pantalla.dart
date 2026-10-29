import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../modelos/usuario-modelo.dart';
import '../proveedores/autenticacion-proveedor.dart';

class MiPerfilPantalla extends ConsumerStatefulWidget {
  const MiPerfilPantalla({super.key});

  @override
  ConsumerState<MiPerfilPantalla> createState() => _MiPerfilPantallaState();
}

class _MiPerfilPantallaState extends ConsumerState<MiPerfilPantalla>
    with SingleTickerProviderStateMixin {
  // Controladores de Sección 1: Datos Personales
  final TextEditingController _nombre_controlador = TextEditingController();
  final TextEditingController _telefono_controlador = TextEditingController();
  final TextEditingController _direccion_controlador = TextEditingController();
  final TextEditingController _carrera_controlador = TextEditingController();
  final TextEditingController _semestre_controlador = TextEditingController();

  // Controladores de Sección 2: Correos de Inicio de Sesión
  final TextEditingController _correo_nuevo_controlador = TextEditingController();
  String _etiqueta_correo_seleccionada = 'Personal';

  // Controladores de Sección 3: Contraseña y Seguridad
  final TextEditingController _contrasena_actual_controlador =
      TextEditingController();
  final TextEditingController _nueva_contrasena_controlador =
      TextEditingController();
  final TextEditingController _confirmar_contrasena_controlador =
      TextEditingController();

  // Controladores de Sección 4: Administración de Usuarios (Exclusivo Admin)
  final TextEditingController _busqueda_usuario_controlador =
      TextEditingController();
  String? _filtro_rol_admin;

  // Estados de visibilidad de contraseñas
  bool _mostrar_contrasena_actual = false;
  bool _mostrar_nueva_contrasena = false;
  bool _mostrar_confirmar_contrasena = false;

  // Estados de carga
  bool _guardando_datos = false;
  bool _guardando_correo = false;
  bool _guardando_contrasena = false;

  // Claves de formularios
  final GlobalKey<FormState> _clave_formulario_datos = GlobalKey<FormState>();
  final GlobalKey<FormState> _clave_formulario_correo = GlobalKey<FormState>();
  final GlobalKey<FormState> _clave_formulario_contrasena =
      GlobalKey<FormState>();

  // Controlador de pestañas (si es admin)
  TabController? _controlador_pestanas;
  bool _datos_inicializados = false;

  // Lista local de correos vinculados
  List<Map<String, dynamic>> _lista_correos_alternativos = [];

  @override
  void initState() {
    super.initState();
    _controlador_pestanas = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarDatosUsuario();
      _cargarCorreos();
    });
  }

  @override
  void dispose() {
    _controlador_pestanas?.dispose();
    _nombre_controlador.dispose();
    _telefono_controlador.dispose();
    _direccion_controlador.dispose();
    _carrera_controlador.dispose();
    _semestre_controlador.dispose();
    _correo_nuevo_controlador.dispose();
    _contrasena_actual_controlador.dispose();
    _nueva_contrasena_controlador.dispose();
    _confirmar_contrasena_controlador.dispose();
    _busqueda_usuario_controlador.dispose();
    super.dispose();
  }

  void _inicializarDatosUsuario() {
    final usuario = ref.read(autenticacion_proveedor).usuario;
    if (usuario != null && !_datos_inicializados) {
      _nombre_controlador.text = usuario.nombre;
      _telefono_controlador.text = usuario.telefono ?? '78945612';
      _direccion_controlador.text =
          usuario.direccion ?? 'Zona 16 de Julio, Calle Eulert #120, El Alto';
      _carrera_controlador.text = usuario.carrera ?? 'Contaduría Pública';
      _semestre_controlador.text = usuario.semestre ?? '6to Semestre';
      _datos_inicializados = true;
    }
  }

  Future<void> _cargarCorreos() async {
    final repo = ref.read(autenticacion_repositorio_proveedor);
    final resultado = await repo.listarMisCorreos();
    if (resultado.exito && resultado.datos != null && mounted) {
      final lista_raw = resultado.datos!['correos_adicionales'];
      if (lista_raw is List) {
        setState(() {
          _lista_correos_alternativos = lista_raw
              .map((item) {
                if (item is Map<String, dynamic>) return item;
                return {'id': 0, 'correo': item.toString(), 'etiqueta': 'Personal'};
              })
              .toList();
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            es_error ? const Color(0xFFDC2626) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _guardarDatosPersonales() async {
    if (!_clave_formulario_datos.currentState!.validate()) return;

    setState(() => _guardando_datos = true);

    final resultado = await ref
        .read(autenticacion_proveedor.notifier)
        .actualizarMiPerfil(
          nombre: _nombre_controlador.text.trim(),
          telefono: _telefono_controlador.text.trim(),
          direccion: _direccion_controlador.text.trim(),
          carrera: _carrera_controlador.text.trim(),
          semestre: _semestre_controlador.text.trim(),
        );

    if (mounted) {
      setState(() => _guardando_datos = false);
      if (resultado.exito) {
        _mostrarMensaje('Datos personales actualizados exitosamente');
      } else {
        _mostrarMensaje(
          resultado.error ?? 'No se pudo actualizar los datos',
          es_error: true,
        );
      }
    }
  }

  Future<void> _vincularNuevoCorreo() async {
    if (!_clave_formulario_correo.currentState!.validate()) return;

    final nuevo_correo = _correo_nuevo_controlador.text.trim();
    setState(() => _guardando_correo = true);

    final resultado = await ref
        .read(autenticacion_proveedor.notifier)
        .vincularCorreoAlternativo(
          correo: nuevo_correo,
          etiqueta: _etiqueta_correo_seleccionada,
        );

    if (mounted) {
      setState(() => _guardando_correo = false);
      if (resultado.exito) {
        _correo_nuevo_controlador.clear();
        _mostrarMensaje('Correo alternativo vinculado exitosamente');
        await _cargarCorreos();
      } else {
        _mostrarMensaje(
          resultado.error ?? 'Error al vincular correo alternativo',
          es_error: true,
        );
      }
    }
  }

  Future<void> _desvincularCorreo(int correo_id, String correo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Desvincular correo?'),
        content: Text(
          'El correo $correo ya no podrá utilizarse para iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final resultado = await ref
        .read(autenticacion_proveedor.notifier)
        .desvincularCorreoAlternativo(correo_id: correo_id, correo: correo);

    if (mounted) {
      if (resultado.exito) {
        _mostrarMensaje('Correo desvinculado exitosamente');
        await _cargarCorreos();
      } else {
        _mostrarMensaje(
          resultado.error ?? 'Error al desvincular correo',
          es_error: true,
        );
      }
    }
  }

  Future<void> _actualizarContrasena() async {
    if (!_clave_formulario_contrasena.currentState!.validate()) return;

    final actual = _contrasena_actual_controlador.text;
    final nueva = _nueva_contrasena_controlador.text;
    final confirmar = _confirmar_contrasena_controlador.text;

    if (nueva != confirmar) {
      _mostrarMensaje('Las contraseñas no coinciden', es_error: true);
      return;
    }

    setState(() => _guardando_contrasena = true);

    final resultado = await ref
        .read(autenticacion_proveedor.notifier)
        .cambiarMiContrasena(
          contrasena_actual: actual,
          nueva_contrasena: nueva,
        );

    if (mounted) {
      setState(() => _guardando_contrasena = false);
      if (resultado.exito) {
        _contrasena_actual_controlador.clear();
        _nueva_contrasena_controlador.clear();
        _confirmar_contrasena_controlador.clear();
        _mostrarMensaje('Contraseña actualizada exitosamente');
      } else {
        _mostrarMensaje(
          resultado.error ?? 'Error al actualizar contraseña',
          es_error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado_auth = ref.watch(autenticacion_proveedor);
    final usuario = estado_auth.usuario;
    final rol = usuario?.rol.toLowerCase().trim() ?? 'becario';
    final es_admin = rol == 'administrador';

    return Scaffold(
      backgroundColor: BumandColores.fondo,
      appBar: const BarraSuperiorBumand(
        titulo: 'Mi Perfil y Cuenta',
        subtitulo: 'Datos personales, correos y contraseña',
      ),
      body: es_admin
          ? Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _controlador_pestanas,
                    labelColor: BumandColores.AZUL_DIACONIA,
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorColor: BumandColores.AZUL_DIACONIA,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.person_rounded, size: 20),
                        text: 'Mi Perfil y Cuenta',
                      ),
                      Tab(
                        icon: Icon(Icons.manage_accounts_rounded, size: 20),
                        text: 'Gestión de Usuarios',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _controlador_pestanas,
                    children: [
                      _construirVistaPerfilPrincipal(usuario, es_admin: true),
                      _construirVistaAdministracionUsuarios(),
                    ],
                  ),
                ),
              ],
            )
          : _construirVistaPerfilPrincipal(usuario, es_admin: false),
    );
  }

  // --- VISTA PRINCIPAL DEL PERFIL (TODOS LOS USUARIOS) ---

  Widget _construirVistaPerfilPrincipal(
    UsuarioModelo? usuario, {
    required bool es_admin,
  }) {
    final nombre_usuario =
        usuario?.nombre.isNotEmpty == true ? usuario!.nombre : 'Usuario BUMAND';
    final inicial =
        nombre_usuario.isNotEmpty ? nombre_usuario[0].toUpperCase() : 'U';
    final rol_texto = usuario?.rol.toUpperCase() ?? 'BECARIO';
    final correo_principal = usuario?.correo ?? 'usuario@diaconia.bo';
    final correo_alternativo = usuario?.correo_alternativo;
    final es_becario = (usuario?.rol.toLowerCase() ?? '') == 'becario';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. Tarjeta Superior de Identidad Institucional
        _construirTarjetaIdentidad(
          inicial: inicial,
          nombre_completo: nombre_usuario,
          rol_texto: rol_texto,
          correo: correo_principal,
        ),
        const SizedBox(height: 18),

        // Banner informativo para administrador si aplica
        if (es_admin) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7DD3FC)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: BumandColores.AZUL_DIACONIA,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panel de Administrador Activo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tienes acceso a la pestaña "Gestión de Usuarios" para crear cuentas y cambiar contraseñas.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0C4A6E)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _controlador_pestanas?.animateTo(1);
                  },
                  child: const Text(
                    'Ir a Gestión',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 2. Sección 1: Mis Datos Personales e Institucionales
        _construirSeccionDatosPersonales(usuario, es_becario: es_becario),
        const SizedBox(height: 20),

        // 3. Sección 2: Mis Correos de Inicio de Sesión
        _construirSeccionCorreos(
          correo_principal: correo_principal,
          correo_alternativo: correo_alternativo,
        ),
        const SizedBox(height: 20),

        // 4. Sección 3: Cambiar Contraseña y Seguridad
        _construirSeccionContrasena(),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- TARJETA DE IDENTIDAD INSTITUCIONAL ---

  Widget _construirTarjetaIdentidad({
    required String inicial,
    required String nombre_completo,
    required String rol_texto,
    required String correo,
  }) {
    Color color_rol = BumandColores.AZUL_DIACONIA;
    Color fondo_rol = const Color(0xFFE0F2FE);

    if (rol_texto == 'ADMINISTRADOR') {
      color_rol = const Color(0xFF9333EA);
      fondo_rol = const Color(0xFFF3E8FF);
    } else if (rol_texto == 'SUPERVISOR') {
      color_rol = BumandColores.turquesaDiaconia;
      fondo_rol = const Color(0xFFCCFBF1);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: BumandColores.AZUL_DIACONIA,
            child: Text(
              inicial,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: fondo_rol,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color_rol.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        rol_texto,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color_rol,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Cuenta Activa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nombre_completo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  correo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN 1: MIS DATOS PERSONALES E INSTITUCIONALES ---

  Widget _construirSeccionDatosPersonales(
    UsuarioModelo? usuario, {
    required bool es_becario,
  }) {
    final ci_texto = usuario?.ci ?? '9876543 LP';
    final universidad_texto =
        usuario?.universidad ?? 'Universidad Pública de El Alto (UPEA)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Form(
        key: _clave_formulario_datos,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.badge_outlined,
                  color: BumandColores.AZUL_DIACONIA,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Datos Personales e Institucionales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Actualiza tu información de contacto y domicilio oficial en BUMAND.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Nombre Completo
            _construirCampoTexto(
              controlador: _nombre_controlador,
              etiqueta: 'Nombre completo',
              icono: Icons.person_outline_rounded,
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'El nombre completo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Teléfono / Celular
            _construirCampoTexto(
              controlador: _telefono_controlador,
              etiqueta: 'Celular / WhatsApp',
              icono: Icons.phone_android_rounded,
              tipo_teclado: TextInputType.phone,
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'El teléfono de contacto es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Dirección
            _construirCampoTexto(
              controlador: _direccion_controlador,
              etiqueta: 'Dirección / Zona de residencia',
              icono: Icons.home_outlined,
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'La dirección de residencia es requerida';
                }
                return null;
              },
            ),

            if (es_becario) ...[
              const SizedBox(height: 12),
              // Carrera
              _construirCampoTexto(
                controlador: _carrera_controlador,
                etiqueta: 'Carrera',
                icono: Icons.school_outlined,
              ),
              const SizedBox(height: 12),
              // Semestre
              _construirCampoTexto(
                controlador: _semestre_controlador,
                etiqueta: 'Semestre académico',
                icono: Icons.date_range_outlined,
              ),
              const SizedBox(height: 14),

              // Fichas informativas institucionales (C.I. y Universidad)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cédula de Identidad (C.I.):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ci_texto,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFCBD5E1)),
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_outlined,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Universidad:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            universidad_texto,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _guardando_datos ? null : _guardarDatosPersonales,
                icon: _guardando_datos
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _guardando_datos ? 'Guardando...' : 'Guardar Datos Personales',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECCIÓN 2: MIS CORREOS DE INICIO DE SESIÓN ---

  Widget _construirSeccionCorreos({
    required String correo_principal,
    required String? correo_alternativo,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.alternate_email_rounded,
                color: BumandColores.AZUL_DIACONIA,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Correos de Inicio de Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes iniciar sesión indistintamente con tu correo principal o cualquiera de tus correos alternativos vinculados.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Fila Correo Principal
          _construirFilaCorreo(
            correo: correo_principal,
            etiqueta: 'Principal',
            color_fondo: const Color(0xFFEFF6FF),
            color_borde: const Color(0xFFBFDBFE),
            color_texto: const Color(0xFF1D4ED8),
            icono: Icons.mark_email_read_rounded,
          ),
          const SizedBox(height: 8),

          // Fila Correo Alternativo
          if (correo_alternativo != null && correo_alternativo.isNotEmpty) ...[
            _construirFilaCorreo(
              correo: correo_alternativo,
              etiqueta: 'Alternativo',
              color_fondo: const Color(0xFFF0FDF4),
              color_borde: const Color(0xFFBBF7D0),
              color_texto: const Color(0xFF15803D),
              icono: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: 8),
          ],

          // Lista de correos adicionales vinculados
          if (_lista_correos_alternativos.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Otros correos alternativos vinculados:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            ..._lista_correos_alternativos.map((item) {
              final id_item = (item['id'] as int?) ?? 0;
              final correo_item = item['correo']?.toString() ?? '';
              final etiqueta_item = item['etiqueta']?.toString() ?? 'Personal';

              if (correo_item == correo_principal) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alternate_email_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            correo_item,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            etiqueta_item,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      tooltip: 'Desvincular correo',
                      onPressed: () => _desvincularCorreo(id_item, correo_item),
                    ),
                  ],
                ),
              );
            }),
          ],

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          // Formulario para vincular nuevo correo
          const Text(
            'Vincular Nuevo Correo Alternativo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Form(
            key: _clave_formulario_correo,
            child: Column(
              children: [
                _construirCampoTexto(
                  controlador: _correo_nuevo_controlador,
                  etiqueta: 'Correo alternativo a vincular',
                  icono: Icons.add_circle_outline_rounded,
                  tipo_teclado: TextInputType.emailAddress,
                  validador: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa un correo electrónico';
                    }
                    if (!valor.contains('@') || !valor.contains('.')) {
                      return 'Formato de correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Etiqueta: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Personal'),
                      selected: _etiqueta_correo_seleccionada == 'Personal',
                      onSelected: (val) {
                        if (val) {
                          setState(() => _etiqueta_correo_seleccionada = 'Personal');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Institucional'),
                      selected:
                          _etiqueta_correo_seleccionada == 'Institucional',
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () => _etiqueta_correo_seleccionada = 'Institucional',
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BumandColores.AZUL_DIACONIA,
                      side: const BorderSide(
                        color: BumandColores.AZUL_DIACONIA,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _guardando_correo ? null : _vincularNuevoCorreo,
                    icon: _guardando_correo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BumandColores.AZUL_DIACONIA,
                            ),
                          )
                        : const Icon(Icons.link_rounded, size: 20),
                    label: Text(
                      _guardando_correo
                          ? 'Vinculando...'
                          : 'Vincular Correo Alternativo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFilaCorreo({
    required String correo,
    required String etiqueta,
    required Color color_fondo,
    required Color color_borde,
    required Color color_texto,
    required IconData icono,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color_fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color_borde),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color_texto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color_texto,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color_borde),
            ),
            child: Text(
              etiqueta.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color_texto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN 3: CAMBIAR CONTRASEÑA Y SEGURIDAD ---

  Widget _construirSeccionContrasena() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Form(
        key: _clave_formulario_contrasena,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.lock_reset_rounded,
                  color: BumandColores.AZUL_DIACONIA,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Cambiar Contraseña y Seguridad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Actualiza tu clave de acceso institucional. Debe tener un mínimo de 6 caracteres.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Contraseña Actual
            _construirCampoContrasena(
              controlador: _contrasena_actual_controlador,
              etiqueta: 'Contraseña actual',
              oculto: !_mostrar_contrasena_actual,
              alCambiarVisibilidad: () {
                setState(
                  () => _mostrar_contrasena_actual = !_mostrar_contrasena_actual,
                );
              },
              validador: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Ingresa tu contraseña actual';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Nueva Contraseña
            _construirCampoContrasena(
              controlador: _nueva_contrasena_controlador,
              etiqueta: 'Nueva contraseña',
              oculto: !_mostrar_nueva_contrasena,
              alCambiarVisibilidad: () {
                setState(
                  () => _mostrar_nueva_contrasena = !_mostrar_nueva_contrasena,
                );
              },
              validador: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Ingresa la nueva contraseña';
                }
                if (valor.length < 6) {
                  return 'La contraseña debe tener mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Confirmar Nueva Contraseña
            _construirCampoContrasena(
              controlador: _confirmar_contrasena_controlador,
              etiqueta: 'Confirmar nueva contraseña',
              oculto: !_mostrar_confirmar_contrasena,
              alCambiarVisibilidad: () {
                setState(
                  () => _mostrar_confirmar_contrasena =
                      !_mostrar_confirmar_contrasena,
                );
              },
              validador: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Confirma tu nueva contraseña';
                }
                if (valor != _nueva_contrasena_controlador.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Botón Actualizar Contraseña
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _guardando_contrasena ? null : _actualizarContrasena,
                icon: _guardando_contrasena
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.security_rounded, size: 20),
                label: Text(
                  _guardando_contrasena
                      ? 'Actualizando...'
                      : 'Actualizar Contraseña',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECCIÓN 4: ADMINISTRACIÓN DE USUARIOS Y CONTRASEÑAS (EXCLUSIVA ADMIN) ---

  Widget _construirVistaAdministracionUsuarios() {
    final async_usuarios = ref.watch(
      usuarios_admin_proveedor(_filtro_rol_admin),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Encabezado de Administración
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gestión de Cuentas BUMAND',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BumandColores.AZUL_DIACONIA,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: _abrirModalCrearUsuario,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Nuevo Usuario'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Buscador de usuarios
              TextField(
                controller: _busqueda_usuario_controlador,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o correo...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _busqueda_usuario_controlador.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _busqueda_usuario_controlador.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filtro por roles
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _construirChipFiltro(etiqueta: 'Todos', valor: null),
                    const SizedBox(width: 8),
                    _construirChipFiltro(
                      etiqueta: 'Administradores',
                      valor: 'administrador',
                    ),
                    const SizedBox(width: 8),
                    _construirChipFiltro(
                      etiqueta: 'Supervisores',
                      valor: 'supervisor',
                    ),
                    const SizedBox(width: 8),
                    _construirChipFiltro(
                      etiqueta: 'Becarios',
                      valor: 'becario',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Listado de usuarios institucional
        async_usuarios.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Error al cargar usuarios: $err',
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
          data: (resultado) {
            if (!resultado.exito || resultado.datos == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resultado.error ?? 'No se pudo listar usuarios.',
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              );
            }

            final consulta =
                _busqueda_usuario_controlador.text.trim().toLowerCase();
            final usuarios_filtrados = resultado.datos!.where((u) {
              final nombre = (u['nombre'] ?? '').toString().toLowerCase();
              final correo = (u['correo'] ?? '').toString().toLowerCase();
              if (consulta.isEmpty) return true;
              return nombre.contains(consulta) || correo.contains(consulta);
            }).toList();

            if (usuarios_filtrados.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(
                      Icons.person_off_rounded,
                      size: 40,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No se encontraron usuarios coincidentes.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: usuarios_filtrados.map((u) {
                final id = (u['id'] as int?) ?? 0;
                final nombre = (u['nombre'] ?? 'Sin Nombre').toString();
                final correo = (u['correo'] ?? '').toString();
                final rol_u = (u['rol'] ?? 'becario').toString();
                final estado_u = (u['estado'] ?? 'activo').toString();

                return _construirTarjetaUsuarioAdmin(
                  id: id,
                  nombre: nombre,
                  correo: correo,
                  rol: rol_u,
                  estado: estado_u,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _construirChipFiltro({
    required String etiqueta,
    required String? valor,
  }) {
    final seleccionado = _filtro_rol_admin == valor;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (val) {
        if (val) {
          setState(() => _filtro_rol_admin = valor);
          ref.invalidate(usuarios_admin_proveedor);
        }
      },
    );
  }

  Widget _construirTarjetaUsuarioAdmin({
    required int id,
    required String nombre,
    required String correo,
    required String rol,
    required String estado,
  }) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
    final es_activo = estado.toLowerCase() == 'activo';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF1F5F9),
                child: Text(
                  inicial,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: BumandColores.AZUL_DIACONIA,
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      correo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: es_activo
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  es_activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: es_activo
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rol.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const Spacer(),
              // Botón Restablecer Contraseña
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.lock_reset_rounded, size: 16),
                label: const Text('Contraseña'),
                onPressed: () => _abrirModalRestablecerContrasena(id, nombre),
              ),
              // Botón Editar Usuario
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: BumandColores.AZUL_DIACONIA,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
                onPressed: () => _abrirModalEditarUsuario(
                  id: id,
                  nombre: nombre,
                  correo: correo,
                  rol: rol,
                  estado: estado,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MODAL: RESTABLECER CONTRASEÑA (ADMIN) ---

  void _abrirModalRestablecerContrasena(int usuario_id, String nombre_usuario) {
    final controlador_clave = TextEditingController();
    bool mostrar_clave = false;
    bool guardando = false;
    final clave_form = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarModal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: const [
              Icon(Icons.lock_reset_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Restablecer Contraseña',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: clave_form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asigna una nueva clave para $nombre_usuario.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: controlador_clave,
                  obscureText: !mostrar_clave,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña institucional',
                    prefixIcon: const Icon(Icons.vpn_key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        mostrar_clave
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        actualizarModal(() => mostrar_clave = !mostrar_clave);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (valor.length < 6) {
                      return 'Mínimo 6 caracteres requeridos';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!clave_form.currentState!.validate()) return;
                      actualizarModal(() => guardando = true);

                      final repo = ref.read(autenticacion_repositorio_proveedor);
                      final res = await repo.restablecerContrasenaPorAdmin(
                        usuario_id,
                        nueva_contrasena: controlador_clave.text,
                      );

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (mounted) {
                        if (res.exito) {
                          _mostrarMensaje('Contraseña restablecida exitosamente');
                        } else {
                          _mostrarMensaje(
                            res.error ?? 'Error al restablecer contraseña',
                            es_error: true,
                          );
                        }
                      }
                    },
              child: Text(guardando ? 'Guardando...' : 'Guardar Contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODAL: EDITAR USUARIO (ADMIN) ---

  void _abrirModalEditarUsuario({
    required int id,
    required String nombre,
    required String correo,
    required String rol,
    required String estado,
  }) {
    final nombre_ctrl = TextEditingController(text: nombre);
    final correo_ctrl = TextEditingController(text: correo);
    String rol_sel = rol.toLowerCase();
    String estado_sel = estado.toLowerCase();
    bool guardando = false;
    final clave_form = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarModal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Editar Usuario Institucional',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: clave_form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombre_ctrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: correo_ctrl,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: rol_sel,
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'administrador',
                        child: Text('Administrador'),
                      ),
                      DropdownMenuItem(
                        value: 'supervisor',
                        child: Text('Supervisor'),
                      ),
                      DropdownMenuItem(
                        value: 'becario',
                        child: Text('Becario'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) actualizarModal(() => rol_sel = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: estado_sel,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'activo',
                        child: Text('Activo'),
                      ),
                      DropdownMenuItem(
                        value: 'inactivo',
                        child: Text('Inactivo'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) actualizarModal(() => estado_sel = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.AZUL_DIACONIA,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!clave_form.currentState!.validate()) return;
                      actualizarModal(() => guardando = true);

                      final repo = ref.read(autenticacion_repositorio_proveedor);
                      final res = await repo.actualizarUsuarioPorAdmin(
                        id,
                        nombre: nombre_ctrl.text.trim(),
                        correo: correo_ctrl.text.trim(),
                        rol: rol_sel,
                        estado: estado_sel,
                      );

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (mounted) {
                        if (res.exito) {
                          _mostrarMensaje('Usuario actualizado correctamente');
                          ref.invalidate(usuarios_admin_proveedor);
                        } else {
                          _mostrarMensaje(
                            res.error ?? 'Error al actualizar usuario',
                            es_error: true,
                          );
                        }
                      }
                    },
              child: Text(guardando ? 'Guardando...' : 'Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODAL: CREAR NUEVO USUARIO (ADMIN) ---

  void _abrirModalCrearUsuario() {
    final nombre_ctrl = TextEditingController();
    final correo_ctrl = TextEditingController();
    final clave_ctrl = TextEditingController();
    String rol_sel = 'supervisor';
    bool mostrar_clave = false;
    bool guardando = false;
    final clave_form = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarModal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Crear Usuario Institucional',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: clave_form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombre_ctrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: correo_ctrl,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: clave_ctrl,
                    obscureText: !mostrar_clave,
                    decoration: InputDecoration(
                      labelText: 'Contraseña (mínimo 6 caracteres)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          mostrar_clave
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          actualizarModal(() => mostrar_clave = !mostrar_clave);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: rol_sel,
                    decoration: InputDecoration(
                      labelText: 'Rol Institucional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'administrador',
                        child: Text('Administrador'),
                      ),
                      DropdownMenuItem(
                        value: 'supervisor',
                        child: Text('Supervisor'),
                      ),
                      DropdownMenuItem(
                        value: 'becario',
                        child: Text('Becario'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) actualizarModal(() => rol_sel = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.AZUL_DIACONIA,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!clave_form.currentState!.validate()) return;
                      actualizarModal(() => guardando = true);

                      final repo = ref.read(autenticacion_repositorio_proveedor);
                      final res = await repo.crearUsuarioInstitucional(
                        nombre: nombre_ctrl.text.trim(),
                        correo: correo_ctrl.text.trim(),
                        contrasena: clave_ctrl.text,
                        rol: rol_sel,
                      );

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (mounted) {
                        if (res.exito) {
                          _mostrarMensaje('Usuario creado exitosamente');
                          ref.invalidate(usuarios_admin_proveedor);
                        } else {
                          _mostrarMensaje(
                            res.error ?? 'Error al crear usuario',
                            es_error: true,
                          );
                        }
                      }
                    },
              child: Text(guardando ? 'Registrando...' : 'Crear Usuario'),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTE AUXILIAR DE CAMPO DE TEXTO ---

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String etiqueta,
    required IconData icono,
    TextInputType tipo_teclado = TextInputType.text,
    String? Function(String?)? validador,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: tipo_teclado,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: BumandColores.AZUL_DIACONIA,
            width: 1.5,
          ),
        ),
      ),
      validator: validador,
    );
  }

  // --- COMPONENTE AUXILIAR DE CAMPO DE CONTRASEÑA ---

  Widget _construirCampoContrasena({
    required TextEditingController controlador,
    required String etiqueta,
    required bool oculto,
    required VoidCallback alCambiarVisibilidad,
    required String? Function(String?) validador,
  }) {
    return TextFormField(
      controller: controlador,
      obscureText: oculto,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF64748B),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            oculto
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF64748B),
            size: 20,
          ),
          onPressed: alCambiarVisibilidad,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: BumandColores.AZUL_DIACONIA,
            width: 1.5,
          ),
        ),
      ),
      validator: validador,
    );
  }
}
