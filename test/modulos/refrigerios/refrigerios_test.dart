import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bumand_movil/modulos/refrigerios/modelos/refrigerio-modelo.dart';
import 'package:bumand_movil/modulos/refrigerios/proveedores/refrigerios-proveedor.dart';

void main() {
  group('IngredienteRefrigerioModelo Tests', () {
    test('Creación y serialización JSON correcta', () {
      const ingrediente = IngredienteRefrigerioModelo(
        insumo: 'Huevos de granja',
        cantidad: '30 u',
        costo_bs: 35.50,
        pagado_por_becario_id: 1,
        pagado_por_nombre: 'María Catunta Laime',
      );

      final json = ingrediente.aJson();
      expect(json['insumo'], 'Huevos de granja');
      expect(json['costo_bs'], 35.50);
      expect(json['pagado_por_nombre'], 'María Catunta Laime');

      final deserializado = IngredienteRefrigerioModelo.deJson(json);
      expect(deserializado.insumo, 'Huevos de granja');
      expect(deserializado.costo_bs, 35.50);
      expect(deserializado.pagado_por_becario_id, 1);
      expect(deserializado.pagado_por_nombre, 'María Catunta Laime');
    });

    test('copiarCon modifica atributos correctamente', () {
      const ingrediente = IngredienteRefrigerioModelo(
        insumo: 'Pan',
        cantidad: '50 u',
        costo_bs: 40.0,
      );

      final modificado = ingrediente.copiarCon(
        costo_bs: 45.0,
        pagado_por_nombre: 'Juan Quispe',
      );

      expect(modificado.insumo, 'Pan');
      expect(modificado.costo_bs, 45.0);
      expect(modificado.pagado_por_nombre, 'Juan Quispe');
    });
  });

  group('RefrigerioModelo - Dupla y Devolución 100% Tests', () {
    const refrigerio_prueba = RefrigerioModelo(
      id: 10,
      fecha: '2026-10-30',
      evento_o_jornada: 'Viernes Formativo',
      menu_detalle: 'Sándwich de huevo',
      sede_nombre: 'Oficina Central El Alto',
      bloque: 'Bloque B',
      responsable_entrega: 'Angel Ali',
      horario_distribucion: '16:00 - 17:30',
      recogido: false,
      becario_encargado_1_id: 1,
      becario_encargado_1_nombre: 'María Catunta Laime',
      becario_encargado_2_id: 2,
      becario_encargado_2_nombre: 'Juan Carlos Quispe',
      modalidad_preparacion: 'cocina_diaconia',
      cantidad_raciones: 23,
      costo_unitario_bs: 6.0,
      costo_total_bs: 138.0,
      porcentaje_devolucion: 100,
      monto_devolucion_bs: 138.0,
      estado: 'sorteado',
      ingredientes: [
        IngredienteRefrigerioModelo(
          insumo: 'Huevos',
          cantidad: '30 u',
          costo_bs: 38.0,
          pagado_por_becario_id: 1,
          pagado_por_nombre: 'María Catunta Laime',
        ),
        IngredienteRefrigerioModelo(
          insumo: 'Pan',
          cantidad: '50 u',
          costo_bs: 40.0,
          pagado_por_becario_id: 1,
          pagado_por_nombre: 'María Catunta Laime',
        ),
        IngredienteRefrigerioModelo(
          insumo: 'Té y Café',
          cantidad: '1 pack',
          costo_bs: 30.0,
          pagado_por_becario_id: 2,
          pagado_por_nombre: 'Juan Carlos Quispe',
        ),
        IngredienteRefrigerioModelo(
          insumo: 'Tomate y condimentos',
          cantidad: 'Varios',
          costo_bs: 30.0,
          pagado_por_becario_id: 2,
          pagado_por_nombre: 'Juan Carlos Quispe',
        ),
      ],
    );

    test('esParteDeLaDupla detecta correctamente por ID y por Nombre', () {
      expect(refrigerio_prueba.esParteDeLaDupla(becario_id: 1), isTrue);
      expect(refrigerio_prueba.esParteDeLaDupla(becario_id: 2), isTrue);
      expect(refrigerio_prueba.esParteDeLaDupla(becario_id: 99), isFalse);

      expect(
        refrigerio_prueba.esParteDeLaDupla(nombre: 'María Catunta Laime'),
        isTrue,
      );
      expect(
        refrigerio_prueba.esParteDeLaDupla(nombre: 'maría catunta laime'),
        isTrue,
      );
      expect(
        refrigerio_prueba.esParteDeLaDupla(nombre: 'Pedro Perez'),
        isFalse,
      );
    });

    test('obtenerCompaneroDupla retorna el compañero correspondiente', () {
      expect(
        refrigerio_prueba.obtenerCompaneroDupla(becario_id: 1),
        'Juan Carlos Quispe',
      );
      expect(
        refrigerio_prueba.obtenerCompaneroDupla(becario_id: 2),
        'María Catunta Laime',
      );
      expect(
        refrigerio_prueba.obtenerCompaneroDupla(nombre: 'María Catunta Laime'),
        'Juan Carlos Quispe',
      );
      expect(
        refrigerio_prueba.obtenerCompaneroDupla(nombre: 'Juan Carlos Quispe'),
        'María Catunta Laime',
      );
      expect(
        refrigerio_prueba.obtenerCompaneroDupla(nombre: 'Otro Becario'),
        isNull,
      );
    });

    test('gastoPorBecario calcula con exactitud los gastos de cada integrante', () {
      final gasto_maria = refrigerio_prueba.gastoPorBecario(becario_id: 1);
      final gasto_juan = refrigerio_prueba.gastoPorBecario(becario_id: 2);

      // María pagó 38.0 + 40.0 = 78.0 Bs
      expect(gasto_maria, 78.0);
      // Juan pagó 30.0 + 30.0 = 60.0 Bs
      expect(gasto_juan, 60.0);

      // Total coincide con el costo total rendido
      expect(gasto_maria + gasto_juan, refrigerio_prueba.costo_total_bs);
    });

    test('devolucionEntregada se activa al aprobarse por administración y fijar receptor', () {
      expect(refrigerio_prueba.devolucionEntregada, isFalse);

      final aprobado = refrigerio_prueba.copiarCon(
        estado: 'aprobado_administracion',
        becario_receptor_devolucion_id: 1,
        becario_receptor_devolucion_nombre: 'María Catunta Laime',
        fecha_entrega_devolucion: '2026-10-30 17:30',
      );

      expect(aprobado.devolucionEntregada, isTrue);
      expect(aprobado.monto_devolucion_bs, 138.0);
      expect(aprobado.porcentaje_devolucion, 100);
      expect(aprobado.becario_receptor_devolucion_nombre, 'María Catunta Laime');
    });

    test('modalidadLegible y estadoLegible devuelven textos oficiales BUMAND', () {
      expect(
        refrigerio_prueba.modalidadLegible,
        'Preparado en Cocina de Diaconía',
      );
      expect(
        refrigerio_prueba.copiarCon(modalidad_preparacion: 'traido_de_casa').modalidadLegible,
        'Elaborado en Casa',
      );
      expect(
        refrigerio_prueba.copiarCon(modalidad_preparacion: 'compra_directa').modalidadLegible,
        'Compra Directa',
      );

      expect(refrigerio_prueba.estadoLegible, 'Sorteado / Programado');
      expect(
        refrigerio_prueba.copiarCon(estado: 'rendido_pendiente').estadoLegible,
        'Rendido (Pendiente Revisión)',
      );
      expect(
        refrigerio_prueba.copiarCon(estado: 'revisado_supervisor').estadoLegible,
        'Revisado por Supervisor',
      );
      expect(
        refrigerio_prueba.copiarCon(estado: 'aprobado_administracion').estadoLegible,
        'Aprobado por Administración (Devolución 100%)',
      );
    });
  });

  group('Refrigerios Riverpod Providers Tests', () {
    test('turno_dupla_activo_proveedor detecta a María Catunta como encargada del viernes', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      final turno = contenedor.read(turno_dupla_activo_proveedor);

      expect(turno.es_encargado, isTrue);
      expect(turno.companero_nombre, 'Juan Carlos Quispe');
      expect(turno.mi_nombre, 'María Catunta Laime');
      expect(turno.refrigerio, isNotNull);
      expect(turno.refrigerio?.cantidad_raciones, 23);
      expect(turno.refrigerio?.porcentaje_devolucion, 100);
    });

    test('RefrigeriosNotificador.rendirRefrigerio actualiza ingredientes y solicita 100% devolución', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      final notificador = contenedor.read(refrigerios_proveedor.notifier);

      notificador.rendirRefrigerio(
        id: 1,
        menu_detalle: 'Sándwich de palta y huevo con té',
        modalidad_preparacion: 'traido_de_casa',
        ingredientes: const [
          IngredienteRefrigerioModelo(
            insumo: 'Palta',
            cantidad: '2 kg',
            costo_bs: 60.0,
            pagado_por_becario_id: 1,
            pagado_por_nombre: 'María Catunta Laime',
          ),
          IngredienteRefrigerioModelo(
            insumo: 'Pan y té',
            cantidad: '50 u',
            costo_bs: 85.0,
            pagado_por_becario_id: 2,
            pagado_por_nombre: 'Juan Carlos Quispe',
          ),
        ],
        costo_total_bs: 145.0,
      );

      final lista_actualizada = contenedor.read(refrigerios_proveedor);
      final ref_actualizado = lista_actualizada.firstWhere((r) => r.id == 1);

      expect(ref_actualizado.menu_detalle, 'Sándwich de palta y huevo con té');
      expect(ref_actualizado.modalidad_preparacion, 'traido_de_casa');
      expect(ref_actualizado.costo_total_bs, 145.0);
      expect(ref_actualizado.monto_devolucion_bs, 145.0);
      expect(ref_actualizado.porcentaje_devolucion, 100);
      expect(ref_actualizado.estado, 'rendido_pendiente');
      expect(ref_actualizado.ingredientes.length, 2);
    });

    test('RefrigeriosNotificador.aprobarDevolucion registra receptor único del 100%', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      final notificador = contenedor.read(refrigerios_proveedor.notifier);

      notificador.aprobarDevolucion(
        id: 1,
        becario_receptor_id: 1,
        becario_receptor_nombre: 'María Catunta Laime',
        fecha_entrega: '2026-10-30 17:30',
      );

      final lista_actualizada = contenedor.read(refrigerios_proveedor);
      final ref_actualizado = lista_actualizada.firstWhere((r) => r.id == 1);

      expect(ref_actualizado.estado, 'aprobado_administracion');
      expect(ref_actualizado.devolucionEntregada, isTrue);
      expect(ref_actualizado.becario_receptor_devolucion_id, 1);
      expect(ref_actualizado.becario_receptor_devolucion_nombre, 'María Catunta Laime');
    });

    test('filtro_busqueda_refrigerios_proveedor filtra por compañero de dupla', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      contenedor
          .read(filtro_busqueda_refrigerios_proveedor.notifier)
          .actualizar('Claudia Cabrera');

      final filtrados = contenedor.read(refrigerios_filtrados_proveedor);
      expect(filtrados.length, 1);
      expect(filtrados.first.becario_encargado_1_nombre, 'Claudia Cabrera');
    });
  });
}
