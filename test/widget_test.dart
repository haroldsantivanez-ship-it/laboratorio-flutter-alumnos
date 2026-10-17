import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';
import '../lib/app_store.dart';

void main() {
  test('Solo acepta la cuenta de la sección y su contraseña correcta', () {
    final store = AppStore.memory();
    expect(store.login(Section.students, 'docente@demo.com', 'Demo1234'), isTrue);
    expect(store.login(Section.products, 'admin@demo.com', 'Demo1234'), isTrue);
    expect(store.login(Section.students, 'admin@demo.com', 'Demo1234'), isFalse);
    expect(store.login(Section.products, 'admin@demo.com', 'incorrecta'), isFalse);
  });

  test('Valida notas y conserva escrituras de alumnos consecutivas', () async {
    final store = AppStore.memory();
    final initialCount = store.students.length;
    await expectLater(store.saveStudent(const Student(
      id: 'incorrecto', name: 'Luis', surname: 'Pérez', grade: 21)), throwsArgumentError);
    await expectLater(store.saveStudent(const Student(
      id: 'nan', name: 'Luis', surname: 'Pérez', grade: double.nan)), throwsArgumentError);
    await Future.wait([
      store.saveStudent(const Student(id: 'uno', name: 'Rosa', surname: 'Díaz', grade: 10.99)),
      store.saveStudent(const Student(id: 'dos', name: 'Pedro', surname: 'Reyes', grade: 11)),
    ]);
    expect(store.students.length, initialCount + 2);
    expect(store.students.firstWhere((a) => a.id == 'uno').approved, isFalse);
    expect(store.students.firstWhere((a) => a.id == 'dos').approved, isTrue);
    await store.saveStudent(const Student(id: 'uno', name: 'Rosa', surname: 'Díaz', grade: 20));
    expect(store.students.length, initialCount + 2);
    expect(store.students.firstWhere((a) => a.id == 'uno').grade, 20);
    await store.deleteStudent('uno');
    expect(store.students.any((a) => a.id == 'uno'), isFalse);
  });

  test('Rechaza productos inválidos y permite stock cero', () async {
    final store = AppStore.memory();
    await expectLater(store.saveProduct(const Product(id: 'inv', name: 'Prueba',
      description: 'Prueba', price: -1, stock: 1)), throwsArgumentError);
    await expectLater(store.saveProduct(const Product(id: 'inv2', name: 'Prueba',
      description: 'Prueba', price: 1, stock: -1)), throwsArgumentError);
    await store.saveProduct(const Product(id: 'nuevo', name: 'Audífonos',
      description: 'Audífonos de prueba', price: 99.50, stock: 0));
    expect(store.products.firstWhere((p) => p.id == 'nuevo').stock, 0);
    await store.deleteProduct('nuevo');
    expect(store.products.any((p) => p.id == 'nuevo'), isFalse);
  });

  test('Editar el correo del perfil actualiza la cuenta de acceso', () async {
    final store = AppStore.memory();
    await store.saveProfile(Section.students, const UserProfile(
      name: 'María González', email: 'maria@demo.com', phone: '912345678', role: 'Docente'));
    expect(store.login(Section.students, 'docente@demo.com', 'Demo1234'), isFalse);
    expect(store.login(Section.students, 'maria@demo.com', 'Demo1234'), isTrue);
  });

  testWidgets('Un acceso incorrecto permanece en el login y uno válido abre el menú', (tester) async {
    await tester.pumpWidget(LabApp(store: AppStore.memory()));
    await tester.tap(find.text('Alumnos'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'docente@demo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrecta');
    await tester.ensureVisible(find.text('INICIAR SESIÓN'));
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('El correo o la contraseña no son correctos.'), findsOneWidget);
    expect(find.byType(MenuPage), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(1), 'Demo1234');
    await tester.ensureVisible(find.text('INICIAR SESIÓN'));
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuPage), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MenuPage), findsNothing);
  });
}
