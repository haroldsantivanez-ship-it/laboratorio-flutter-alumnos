import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Section { students, products }

extension SectionInfo on Section {
  bool get isStudents => this == Section.students;
  String get title => isStudents ? 'Alumnos' : 'Productos';
  String get label => isStudents ? 'Sección A' : 'Sección B';
  String get registerTitle => isStudents ? 'Registrar alumno' : 'Registrar producto';
}

class Student {
  const Student({required this.id, required this.name, required this.surname, required this.grade});
  final String id, name, surname;
  final double grade;
  String get fullName => '$name $surname';
  // El criterio de esta práctica es aprobar desde 11 sobre 20.
  bool get approved => grade >= 11;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'surname': surname, 'grade': grade};
  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as String, name: json['name'] as String,
    surname: json['surname'] as String, grade: (json['grade'] as num).toDouble(),
  );
}

class Product {
  const Product({required this.id, required this.name, required this.description,
    required this.price, required this.stock, this.photo});
  final String id, name, description;
  final double price;
  final int stock;
  final String? photo;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description,
    'price': price, 'stock': stock, 'photo': photo};
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String, name: json['name'] as String,
    description: json['description'] as String, price: (json['price'] as num).toDouble(),
    stock: json['stock'] as int, photo: json['photo'] as String?,
  );
}

class UserProfile {
  const UserProfile({required this.name, required this.email, required this.phone,
    required this.role, this.photo});
  final String name, email, phone, role;
  final String? photo;
  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone,
    'role': role, 'photo': photo};
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String, email: json['email'] as String,
    phone: json['phone'] as String, role: json['role'] as String,
    photo: json['photo'] as String?,
  );
}

class AppStore extends ChangeNotifier {
  AppStore.memory() : _prefs = null;
  AppStore._(this._prefs);
  final SharedPreferencesAsync? _prefs;
  static const storageKey = 'alumnos_productos_v1';
  // Credencial local de demostración. No representa autenticación con un servidor.
  static const demoPassword = 'Demo1234';
  Section? selectedSection;
  Future<void> _queue = Future<void>.value();

  List<Student> _students = const [
    Student(id: 'a1', name: 'Ana', surname: 'Torres', grade: 18),
    Student(id: 'a2', name: 'Luis', surname: 'García', grade: 12),
    Student(id: 'a3', name: 'María', surname: 'López', grade: 9),
    Student(id: 'a4', name: 'Carlos', surname: 'Ruiz', grade: 15),
  ];
  List<Product> _products = const [
    Product(id: 'p1', name: 'Laptop', description: 'Laptop para estudio y trabajo.', price: 3500, stock: 10),
    Product(id: 'p2', name: 'Mouse', description: 'Mouse inalámbrico.', price: 50, stock: 25),
    Product(id: 'p3', name: 'Teclado', description: 'Teclado de oficina.', price: 120, stock: 15),
    Product(id: 'p4', name: 'Monitor', description: 'Monitor de 24 pulgadas.', price: 800, stock: 8),
  ];
  Map<Section, UserProfile> _profiles = const {
    Section.students: UserProfile(name: 'María González', email: 'docente@demo.com',
      phone: '912345678', role: 'Docente'),
    Section.products: UserProfile(name: 'Juan Pérez', email: 'admin@demo.com',
      phone: '987654321', role: 'Administrador'),
  };
  List<Student> get students => List.unmodifiable(_students);
  List<Product> get products => List.unmodifiable(_products);
  UserProfile profile(Section section) => _profiles[section]!;

  static Future<AppStore> load() async {
    final store = AppStore._(SharedPreferencesAsync());
    final saved = await store._prefs!.getString(storageKey);
    if (saved != null) {
      final data = jsonDecode(saved) as Map<String, dynamic>;
      store._students = (data['students'] as List<dynamic>).map(
        (item) => Student.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      store._products = (data['products'] as List<dynamic>).map(
        (item) => Product.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      final profiles = data['profiles'] as Map<String, dynamic>;
      store._profiles = {
        for (final section in Section.values)
          section: UserProfile.fromJson(Map<String, dynamic>.from(profiles[section.name] as Map)),
      };
    }
    return store;
  }

  void choose(Section section) {
    selectedSection = section;
    notifyListeners();
  }

  bool login(Section section, String email, String password) =>
    email.trim().toLowerCase() == profile(section).email.toLowerCase()
    && password == demoPassword;

  // Las escrituras se hacen en orden para evitar que un guardado reemplace a otro.
  Future<void> _enqueue(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _commit({List<Student>? students, List<Product>? products,
    Map<Section, UserProfile>? profiles}) async {
    final nextStudents = students ?? _students;
    final nextProducts = products ?? _products;
    final nextProfiles = profiles ?? _profiles;
    final data = jsonEncode({
      'students': nextStudents.map((item) => item.toJson()).toList(),
      'products': nextProducts.map((item) => item.toJson()).toList(),
      'profiles': {for (final entry in nextProfiles.entries) entry.key.name: entry.value.toJson()},
    });
    // La pantalla solo se actualiza cuando el guardado local termina correctamente.
    if (_prefs != null) await _prefs.setString(storageKey, data);
    _students = nextStudents;
    _products = nextProducts;
    _profiles = nextProfiles;
    notifyListeners();
  }

  Future<void> saveStudent(Student student) => _enqueue(() {
    if (!student.grade.isFinite || student.grade < 0 || student.grade > 20
        || student.name.trim().isEmpty || student.surname.trim().isEmpty) {
      throw ArgumentError('Los datos del alumno no son válidos.');
    }
    final exists = _students.any((item) => item.id == student.id);
    return _commit(students: exists
      ? _students.map((item) => item.id == student.id ? student : item).toList()
      : [..._students, student]);
  });

  Future<void> saveProduct(Product product) => _enqueue(() {
    if (!product.price.isFinite || product.price < 0 || product.stock < 0
        || product.name.trim().isEmpty || product.description.trim().isEmpty) {
      throw ArgumentError('Los datos del producto no son válidos.');
    }
    final exists = _products.any((item) => item.id == product.id);
    return _commit(products: exists
      ? _products.map((item) => item.id == product.id ? product : item).toList()
      : [..._products, product]);
  });

  Future<void> deleteStudent(String id) => _enqueue(() =>
    _commit(students: _students.where((item) => item.id != id).toList()));
  Future<void> deleteProduct(String id) => _enqueue(() =>
    _commit(products: _products.where((item) => item.id != id).toList()));
  Future<void> saveProfile(Section section, UserProfile user) => _enqueue(() =>
    _commit(profiles: {..._profiles, section: user}));
}
