import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(LabApp(store: await AppStore.load()));
  } catch (error) {
    debugPrint('No se pudieron cargar los registros: $error');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min,
      children: [const Text('No se pudieron leer los registros guardados.'),
        const SizedBox(height: 16), FilledButton(onPressed: main,
          child: const Text('Reintentar'))]))))));
  }
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);
  static AppStore of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

Color sectionColor(Section section) => section.isStudents
    ? const Color(0xFF5943CF) : const Color(0xFF0879F8);

ThemeData appTheme(Section section) {
  final primary = sectionColor(section);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(primary: primary),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarThemeData(backgroundColor: primary, foregroundColor: Colors.white,
      elevation: 0, centerTitle: false, titleTextStyle: const TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true, fillColor: const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1E9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1E9))),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
  );
}

class LabApp extends StatelessWidget {
  const LabApp({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => AppScope(store: store, child: Builder(
    builder: (context) {
      final state = AppScope.of(context);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Alumnos y productos',
        theme: appTheme(state.selectedSection ?? Section.products),
        home: const SectionPicker(),
        // Conserva un ancho de teléfono al ejecutar la aplicación en Chrome.
        builder: (context, child) => LayoutBuilder(builder: (context, constraints) {
          final width = math.min(440.0, constraints.maxWidth);
          return ColoredBox(color: const Color(0xFFEEF1F7), child: Center(
            child: SizedBox(width: width, height: constraints.maxHeight,
              child: ClipRect(child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: Size(width, constraints.maxHeight)),
                child: child ?? const SizedBox.shrink())))));
        }),
      );
    },
  ));
}

void notice(BuildContext context, String text) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

String? requiredText(String? value) => value == null || value.trim().isEmpty
  ? 'Completa este campo.' : null;

String? validEmail(String? value) =>
  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value?.trim() ?? '')
    ? null : 'Ingresa un correo válido.';

double? readDecimal(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
String gradeText(double grade) => grade == grade.roundToDouble()
  ? grade.toInt().toString().padLeft(2, '0') : grade.toString();

Future<String?> choosePhoto() async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery,
    maxWidth: 640, maxHeight: 640, imageQuality: 70, requestFullMetadata: false);
  if (image == null) return null;
  final bytes = await image.readAsBytes();
  if (bytes.length > 500000) throw const FormatException('Selecciona una imagen más pequeña.');
  // Guardar los bytes evita depender de una ruta temporal del selector.
  return base64Encode(bytes);
}

class PhotoBox extends StatelessWidget {
  const PhotoBox({super.key, this.photo, required this.icon, this.size = 62, this.round = false});
  final String? photo;
  final IconData icon;
  final double size;
  final bool round;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => ColoredBox(color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: size * .52)));
    Widget content = fallback();
    if (photo != null) {
      try {
        content = Image.memory(base64Decode(photo!), fit: BoxFit.cover,
          errorBuilder: (_, error, stack) => fallback());
      } on FormatException {
        content = fallback();
      }
    }
    return ClipRRect(borderRadius: BorderRadius.circular(round ? size / 2 : 12),
      child: SizedBox(width: size, height: size, child: content));
  }
}

IconData productIcon(String name) {
  final text = name.toLowerCase();
  if (text.contains('laptop')) return Icons.laptop_mac;
  if (text.contains('mouse')) return Icons.mouse;
  if (text.contains('teclado')) return Icons.keyboard;
  if (text.contains('monitor')) return Icons.desktop_windows;
  return Icons.inventory_2;
}

class SectionPicker extends StatelessWidget {
  const SectionPicker({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.apps_rounded, size: 66, color: Color(0xFF0879F8)),
        const SizedBox(height: 20),
        const Text('Alumnos y productos', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 9),
        const Text('Selecciona la sección a la que deseas ingresar.', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        for (final section in Section.values) ...[
          Card(color: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE1E5ED))),
            child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              leading: Icon(section.isStudents ? Icons.school : Icons.shopping_bag,
                color: sectionColor(section), size: 34),
              title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(section.label), trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppScope.of(context).choose(section);
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LoginPage(section: section)));
              })),
          const SizedBox(height: 14),
        ],
      ])))));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.section});
  final Section section;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  void _login() {
    if (!_form.currentState!.validate()) return;
    if (!AppScope.of(context).login(widget.section, _email.text, _password.text)) {
      notice(context, 'El correo o la contraseña no son correctos.');
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // Reemplaza el login para que volver atrás no muestre el formulario de acceso.
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => MenuPage(section: widget.section)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.section.title)),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(28), child: Form(key: _form,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(widget.section.isStudents ? Icons.school : Icons.shopping_bag,
            size: 76, color: sectionColor(widget.section)),
          const SizedBox(height: 20),
          const Text('Iniciar sesión', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ingresa tus credenciales para continuar', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 30),
          TextFormField(controller: _email, validator: validEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next, autocorrect: false,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 16),
          TextFormField(controller: _password, validator: requiredText, obscureText: _hidden,
            autocorrect: false, enableSuggestions: false,
            textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _login(),
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          const SizedBox(height: 24),
          FilledButton(onPressed: _login, child: const Text('INICIAR SESIÓN')),
          const SizedBox(height: 10),
          TextButton(onPressed: () {
            final email = AppScope.of(context).profile(widget.section).email;
            showDialog<void>(context: context, builder: (_) => AlertDialog(
              title: const Text('Acceso de prueba'),
              content: Text('Correo: $email\nContraseña: ${AppStore.demoPassword}'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))]));
          }, child: const Text('¿Olvidaste tu contraseña?')),
        ]))))));
}

void logout(BuildContext context, Section section) {
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(
    builder: (_) => LoginPage(section: section)), (route) => route.isFirst);
}

void openPage(BuildContext context, Section section, int index, {bool fromDrawer = false}) {
  final navigator = Navigator.of(context);
  if (fromDrawer) navigator.pop();
  if (index == 3) { logout(context, section); return; }
  final Widget page;
  if (index == 0) {
    page = RecordForm(section: section);
  } else if (index == 1) {
    page = DataListPage(section: section);
  } else {
    page = ProfilePage(section: section);
  }
  navigator.push(MaterialPageRoute<void>(builder: (_) => page));
}

class MenuOptions extends StatelessWidget {
  const MenuOptions({super.key, required this.section, this.fromDrawer = false});
  final Section section;
  final bool fromDrawer;
  @override
  Widget build(BuildContext context) {
    final labels = [section.registerTitle, 'Listar ${section.title.toLowerCase()}', 'Perfil', 'Cerrar sesión'];
    final icons = [section.isStudents ? Icons.person_add_alt_1 : Icons.add_shopping_cart,
      Icons.format_list_bulleted, Icons.person, Icons.logout];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < labels.length; i++) ...[
        ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          leading: Icon(icons[i], color: i == 3 ? Colors.red : sectionColor(section)),
          title: Text(labels[i]), trailing: i == 3 ? null : const Icon(Icons.chevron_right),
          onTap: () => openPage(context, section, i, fromDrawer: fromDrawer)),
        if (i < labels.length - 1) const Divider(height: 1),
      ]
    ]);
  }
}

class ModuleDrawer extends StatelessWidget {
  const ModuleDrawer({super.key, required this.section});
  final Section section;
  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).profile(section);
    return Drawer(child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 16),
      Align(alignment: Alignment.centerLeft,
        child: PhotoBox(photo: user.photo, icon: Icons.person, size: 72, round: true)),
      const SizedBox(height: 12),
      Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(user.email), const SizedBox(height: 24),
      MenuOptions(section: section, fromDrawer: true),
    ])));
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.section});
  final Section section;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Menú')), drawer: ModuleDrawer(section: section),
    body: Padding(padding: const EdgeInsets.all(16), child: MenuOptions(section: section)));
}

class DataListPage extends StatefulWidget {
  const DataListPage({super.key, required this.section});
  final Section section;
  @override
  State<DataListPage> createState() => _DataListPageState();
}

class _DataListPageState extends State<DataListPage> {
  String _query = '';
  Future<void> _delete(String id, String name) async {
    final store = AppScope.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar registro'), content: Text('¿Deseas eliminar a $name?'),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Eliminar'))]));
    if (confirmed != true || !mounted) return;
    try {
      if (widget.section.isStudents) { await store.deleteStudent(id); }
      else { await store.deleteProduct(id); }
      if (mounted) notice(context, 'Registro eliminado.');
    } catch (_) { if (mounted) notice(context, 'No se pudo eliminar el registro.'); }
  }

  void _edit({Student? student, Product? product}) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => RecordForm(section: widget.section, student: student, product: product)));

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final students = store.students.where((item) => item.fullName.toLowerCase().contains(_query)).toList();
    final products = store.products.where((item) => item.name.toLowerCase().contains(_query)).toList();
    final count = widget.section.isStudents ? students.length : products.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.section.title), actions: [IconButton(
        tooltip: 'Nuevo registro', onPressed: () => _edit(), icon: const Icon(Icons.add))]),
      drawer: ModuleDrawer(section: widget.section),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(hintText: widget.section.isStudents ? 'Buscar alumno...' : 'Buscar producto...',
            prefixIcon: const Icon(Icons.search)))),
        Expanded(child: count == 0 ? const Center(child: Text('No se encontraron registros.'))
          : ListView.separated(padding: const EdgeInsets.fromLTRB(12, 0, 12, 24), itemCount: count,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (widget.section.isStudents) {
                final student = students[index];
                final color = student.approved ? Colors.green : Colors.red;
                return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
                  leading: const PhotoBox(icon: Icons.school, size: 44, round: true),
                  title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Nota: ${gradeText(student.grade)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(6)),
                      child: Text(student.approved ? 'Aprobado' : 'Desaprobado',
                        style: TextStyle(color: color.shade800, fontSize: 11))),
                    PopupMenuButton<String>(tooltip: 'Opciones', onSelected: (value) {
                      if (value == 'edit') { _edit(student: student); }
                      else { _delete(student.id, student.fullName); }
                    }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar'))]),
                  ]));
              }
              final product = products[index];
              return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                leading: PhotoBox(photo: product.photo, icon: productIcon(product.name), size: 56),
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Precio: S/ ${product.price.toStringAsFixed(2)}\nStock: ${product.stock}'),
                isThreeLine: true,
                onTap: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                  title: Text(product.name), content: Text('${product.description}\n\nPrecio: S/ ${product.price.toStringAsFixed(2)}\nStock: ${product.stock}'),
                  actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar'))])),
                trailing: PopupMenuButton<String>(tooltip: 'Opciones', onSelected: (value) {
                  if (value == 'edit') { _edit(product: product); }
                  else { _delete(product.id, product.name); }
                }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar'))]));
            })),
      ]));
  }
}

class RecordForm extends StatefulWidget {
  const RecordForm({super.key, required this.section, this.student, this.product});
  final Section section;
  final Student? student;
  final Product? product;
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _surname, _grade, _description, _price, _stock;
  String? _photo;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final a = widget.student;
    final p = widget.product;
    _name = TextEditingController(text: a?.name ?? p?.name ?? '');
    _surname = TextEditingController(text: a?.surname ?? '');
    _grade = TextEditingController(text: a == null ? '' : gradeText(a.grade));
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _photo = p?.photo;
  }
  @override
  void dispose() {
    for (final controller in [_name, _surname, _grade, _description, _price, _stock]) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final photo = await choosePhoto();
      if (mounted && photo != null) setState(() => _photo = photo);
    } catch (error) {
      if (mounted) notice(context, error is FormatException ? error.message : 'No se pudo abrir la imagen.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final store = AppScope.of(context);
    setState(() => _busy = true);
    try {
      if (widget.section.isStudents) {
        await store.saveStudent(Student(id: widget.student?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: _name.text.trim(), surname: _surname.text.trim(), grade: readDecimal(_grade.text)!));
      } else {
        await store.saveProduct(Product(id: widget.product?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: _name.text.trim(), description: _description.text.trim(),
          price: readDecimal(_price.text)!, stock: int.parse(_stock.text.trim()), photo: _photo));
      }
      if (!mounted) return;
      notice(context, widget.section.isStudents ? 'Alumno guardado.' : 'Producto guardado.');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) notice(context, 'No se pudo guardar. Revisa el espacio disponible e inténtalo otra vez.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.student != null || widget.product != null;
    return Scaffold(appBar: AppBar(title: Text(editing
      ? (widget.section.isStudents ? 'Editar alumno' : 'Editar producto') : widget.section.registerTitle)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!widget.section.isStudents) ...[
            Center(child: InkWell(onTap: _busy ? null : _pick, borderRadius: BorderRadius.circular(12),
              child: Column(children: [PhotoBox(photo: _photo, icon: Icons.add_a_photo_outlined, size: 104),
                const SizedBox(height: 8), const Text('Seleccionar imagen')]))),
            const SizedBox(height: 24),
          ],
          TextFormField(controller: _name, enabled: !_busy, validator: requiredText,
            textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: widget.section.isStudents ? 'Nombre del alumno' : 'Nombre del producto')),
          const SizedBox(height: 16),
          if (widget.section.isStudents) ...[
            TextFormField(controller: _surname, enabled: !_busy, validator: requiredText,
              textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Apellido')),
            const SizedBox(height: 16),
            TextFormField(controller: _grade, enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Nota de 0 a 20', suffixIcon: Icon(Icons.school_outlined)),
              validator: (value) {
                final grade = readDecimal(value ?? '');
                return grade == null || !grade.isFinite || grade < 0 || grade > 20
                  ? 'Ingresa una nota entre 0 y 20.' : null;
              }),
          ] else ...[
            TextFormField(controller: _description, enabled: !_busy, validator: requiredText,
              minLines: 2, maxLines: 3, textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 16),
            TextFormField(controller: _price, enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio', prefixText: 'S/ '),
              validator: (value) {
                final price = readDecimal(value ?? '');
                return price == null || !price.isFinite || price < 0
                  ? 'Ingresa un precio mayor o igual a cero.' : null;
              }),
            const SizedBox(height: 16),
            TextFormField(controller: _stock, enabled: !_busy, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Stock'),
              validator: (value) {
                final stock = int.tryParse(value?.trim() ?? '');
                return stock == null || stock < 0 ? 'Ingresa una cantidad entera desde cero.' : null;
              }),
          ],
          const SizedBox(height: 26),
          FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'GUARDANDO...' : 'GUARDAR')),
        ]))));
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.section});
  final Section section;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _busy = false;
  Future<void> _pick() async {
    final store = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final photo = await choosePhoto();
      if (!mounted || photo == null) return;
      final user = store.profile(widget.section);
      await store.saveProfile(widget.section, UserProfile(name: user.name, email: user.email,
        phone: user.phone, role: user.role, photo: photo));
      if (mounted) notice(context, 'Foto actualizada.');
    } catch (error) {
      if (mounted) notice(context, error is FormatException ? error.message : 'No se pudo actualizar la foto.');
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).profile(widget.section);
    return Scaffold(appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 12),
          Center(child: Stack(children: [
            PhotoBox(photo: user.photo, icon: Icons.person, size: 106, round: true),
            Positioned(right: 0, bottom: 0, child: IconButton.filled(
              tooltip: 'Cambiar foto', onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.camera_alt, size: 18))),
          ])),
          const SizedBox(height: 18),
          Text(user.name, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
          const SizedBox(height: 5), Text(user.email, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 28),
          for (final row in <(IconData, String, String)>[
            (Icons.person, 'Nombre', user.name), (Icons.email, 'Correo', user.email),
            (Icons.phone, 'Teléfono', user.phone), (Icons.settings, 'Rol', user.role),
          ]) ...[
            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(row.$1, size: 22),
              title: Text(row.$2, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              subtitle: Text(row.$3, style: const TextStyle(fontSize: 15, color: Colors.black87))),
            const Divider(height: 1),
          ],
          const SizedBox(height: 24),
          OutlinedButton(onPressed: _busy ? null : () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => EditProfilePage(section: widget.section))),
            child: const Text('EDITAR PERFIL')),
        ])));
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.section});
  final Section section;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _email, _phone;
  bool _initialized = false;
  bool _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = AppScope.of(context).profile(widget.section);
      _name = TextEditingController(text: user.name);
      _email = TextEditingController(text: user.email);
      _phone = TextEditingController(text: user.phone);
      _initialized = true;
    }
  }
  @override
  void dispose() { _name.dispose(); _email.dispose(); _phone.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final store = AppScope.of(context);
    final current = store.profile(widget.section);
    setState(() => _busy = true);
    try {
      await store.saveProfile(widget.section, UserProfile(name: _name.text.trim(),
        email: _email.text.trim().toLowerCase(), phone: _phone.text.trim(),
        role: current.role, photo: current.photo));
      if (!mounted) return;
      notice(context, 'Perfil actualizado.');
      Navigator.of(context).pop();
    } catch (_) { if (mounted) notice(context, 'No se pudo guardar el perfil.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Editar perfil')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(controller: _name, enabled: !_busy, validator: requiredText,
          decoration: const InputDecoration(labelText: 'Nombre completo')),
        const SizedBox(height: 16),
        TextFormField(controller: _email, enabled: !_busy, validator: validEmail,
          keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo')),
        const SizedBox(height: 16),
        TextFormField(controller: _phone, enabled: !_busy, keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          validator: (value) => RegExp(r'^\+?[0-9\s()-]{7,20}$').hasMatch(value?.trim() ?? '')
            ? null : 'Ingresa un teléfono válido.'),
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _save,
          child: Text(_busy ? 'GUARDANDO...' : 'GUARDAR CAMBIOS')),
      ]))));
}
