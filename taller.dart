1)	Generación de secuencia de Fibonacci con interacción del usuario
Stream<int> fibonacciStream(int n) async* {
  int a = 0, b = 1;
  while (n-- > 0) {
    yield a;
    a = b + (b = a);
    await Future.delayed(Duration(milliseconds: 500));
  }
}

void main() {
  var subscription = fibonacciStream(10).listen(print);

  Future.delayed(Duration(seconds: 3), () {
    print('Pausando...');
    subscription.pause();
    print('Opciones: [r] Reanudar | [c] Cancelar');
    String? input = stdin.readLineSync();
    if (input == 'r') {
      print('Reanudando...');
      subscription.resume();
    } else if (input == 'c') {
      print('Cancelando...');
      subscription.cancel();
    }
  });
}
2)	Combinación de clases 
mixin Electrico {
  void cargarBateria() {
    print('Cargando la batería...');
  }

  void usarElectrico() {
    print('Usando energía eléctrica...');
  }
}

mixin Anfibio {
  void conducirEnAgua() {
    print('Conduciendo en el agua...');
  }
}

mixin Volador {
  void volar() {
    print('Volando...');
  }

  void aterrizar() {
    print('Aterrizando...');
  }
}

class Vehiculo {
  void conducir() {
    print('Conduciendo...');
  }
}

class CocheElectrico extends Vehiculo with Electrico {
  void mostrarInfo() {
    print(' coche eléctrico.');
  }
}

class VehiculoAnfibioElectrico extends Vehiculo with Electrico, Anfibio {
  void mostrarInfo() {
    print(' vehículo anfibio eléctrico.');
  }
}

class Dron extends Vehiculo with Electrico, Volador {
  void mostrarInfo() {
    print(' un dron.');
  }
}

void main() {

  var cocheElectrico = CocheElectrico();
  var vehiculoAnfibioElectrico = VehiculoAnfibioElectrico();
  var dron = Dron();

  cocheElectrico.mostrarInfo();
  cocheElectrico.conducir();
  cocheElectrico.cargarBateria();
  cocheElectrico.usarElectrico();

  print('\n');

  vehiculoAnfibioElectrico.mostrarInfo();
  vehiculoAnfibioElectrico.conducir();
  vehiculoAnfibioElectrico.cargarBateria();
  vehiculoAnfibioElectrico.usarElectrico();
  vehiculoAnfibioElectrico.conducirEnAgua();

  print('\n');

  dron.mostrarInfo();
  dron.conducir();
  dron.cargarBateria();
  dron.usarElectrico();
  dron.volar();
  dron.aterrizar();
}

3)	 Lectura de archivo de texto utilizando isoteles 

 import 'dart:io';
import 'dart:isolate';
import 'dart:math';

const String fileName = "large_text.txt";
const int fileSize = 10 * 1024 * 1024; 


Future<void> generateLargeFile() async {
  final file = File(fileName);
  final random = Random();
  const words = [
    "Dart",
    "Flutter",
    "Parallel",
    "Isolate",
    "Performance",
    "Compute",
    "Async"
  ];

  final sink = file.openWrite();
  int size = 0;
  while (size < fileSize) {
    final word = words[random.nextInt(words.length)];
    sink.write("$word ");
    size += word.length + 1;
  }
  await sink.close();
}

Future<Map<String, dynamic>> processFileSequential() async {
  final file = File(fileName);
  final content = await file.readAsString();
  final words = content.split(RegExp(r'\s+'));

  final int wordCount = words.length;
  final Map<String, int> letterFrequency = {};
  String longestWord = "";

  for (var word in words) {
    if (word.length > longestWord.length) {
      longestWord = word;
    }
    for (var letter in word.runes) {
      final char = String.fromCharCode(letter).toLowerCase();
      if (char.contains(RegExp(r'[a-z]'))) {
        letterFrequency[char] = (letterFrequency[char] ?? 0) + 1;
      }
    }
  }

  return {
    "wordCount": wordCount,
    "letterFrequency": letterFrequency,
    "longestWord": longestWord,
  };
}


Future<Map<String, dynamic>> processFileParallel() async {
  final file = File(fileName);
  final content = await file.readAsString();
  final words = content.split(RegExp(r'\s+'));

  final int chunkSize =
      (words.length / 4).ceil(); // Convertimos a entero explícitamente
  final List<List<String>> chunks = List.generate(
      4, (i) => words.skip(i * chunkSize).take(chunkSize).toList());

  final List<Map<String, dynamic>> results = await Future.wait(chunks
      .map((chunk) async => await Isolate.run(() => processChunk(chunk))));

  int wordCount = 0;
  String longestWord = "";
  final Map<String, int> letterFrequency = {};

  for (var result in results) {
    wordCount += result["wordCount"] as int;
    if ((result["longestWord"] as String).length > longestWord.length) {
      longestWord = result["longestWord"] as String;
    }
    (result["letterFrequency"] as Map<String, int>).forEach((key, value) {
      letterFrequency[key] = (letterFrequency[key] ?? 0) + value;
    });
  }

  return {
    "wordCount": wordCount,
    "letterFrequency": letterFrequency,
    "longestWord": longestWord,
  };
}

Map<String, dynamic> processChunk(List<String> words) {
  int wordCount = words.length;
  final Map<String, int> letterFrequency = {};
  String longestWord = "";

  for (var word in words) {
    if (word.length > longestWord.length) {
      longestWord = word;
    }
    for (var letter in word.runes) {
      final char = String.fromCharCode(letter).toLowerCase();
      if (char.contains(RegExp(r'[a-z]'))) {
        letterFrequency[char] = (letterFrequency[char] ?? 0) + 1;
      }
    }
  }
  return {
    "wordCount": wordCount,
    "letterFrequency": letterFrequency,
    "longestWord": longestWord
  };
}

void main() async {
  await generateLargeFile();

  final stopwatchSeq = Stopwatch()..start();
  final resultSeq = await processFileSequential();
  stopwatchSeq.stop();

  print("Secuencial - Tiempo: ${stopwatchSeq.elapsedMilliseconds} ms");
  print("Secuencial - Palabra más larga: ${resultSeq["longestWord"]}");
  final stopwatchPar = Stopwatch()..start();
  final resultPar = await processFileParallel();
  stopwatchPar.stop();

  print("Paralelo - Tiempo: ${stopwatchPar.elapsedMilliseconds} ms");
  print("Paralelo - Palabra más larga: ${resultPar["longestWord"]}");
}

4) recorrido árbol binario 

class BinarySearchTree<T extends Comparable<T>> {
  TreeNode<T>? _root;

  void insert(T value) => _root = _insert(_root, value);

  TreeNode<T>? _insert(TreeNode<T>? node, T value) {
    if (node == null) return TreeNode(value);
    if (value.compareTo(node.value) < 0) {
      node.left = _insert(node.left, value);
    } else if (value.compareTo(node.value) > 0) {
      node.right = _insert(node.right, value);
    }
    return node;
  }

  void delete(T value) => _root = _delete(_root, value);

  TreeNode<T>? _delete(TreeNode<T>? node, T value) {
    if (node == null) return null;

    if (value.compareTo(node.value) < 0) {
      node.left = _delete(node.left, value);
    } else if (value.compareTo(node.value) > 0) {
      node.right = _delete(node.right, value);
    } else {
      if (node.left == null) return node.right;
      if (node.right == null) return node.left;
      node.value = _minValue(node.right!);
      node.right = _delete(node.right, node.value);
    }
    return node;
  }

  T _minValue(TreeNode<T> node) {
    while (node.left != null) node = node.left!;
    return node.value;
  }

  bool search(T value) => _search(_root, value);

  bool _search(TreeNode<T>? node, T value) {
    if (node == null) return false;
    if (value.compareTo(node.value) == 0) return true;
    return value.compareTo(node.value) < 0
        ? _search(node.left, value)
        : _search(node.right, value);
  }

  void inOrder(void Function(T) action) => _inOrder(_root, action);

  void _inOrder(TreeNode<T>? node, void Function(T) action) {
    if (node == null) return;
    _inOrder(node.left, action);
    action(node.value);
    _inOrder(node.right, action);
  }

  void preOrder(void Function(T) action) => _preOrder(_root, action);

  void _preOrder(TreeNode<T>? node, void Function(T) action) {
    if (node == null) return;
    action(node.value);
    _preOrder(node.left, action);
    _preOrder(node.right, action);
  }

  void postOrder(void Function(T) action) => _postOrder(_root, action);

  void _postOrder(TreeNode<T>? node, void Function(T) action) {
    if (node == null) return;
    _postOrder(node.left, action);
    _postOrder(node.right, action);
    action(node.value);
  }

  Iterable<T> get iterator => _BSTIterator(_root);
}

class TreeNode<T> {
  T value;
  TreeNode<T>? left, right;
  TreeNode(this.value);
}

class _BSTIterator<T extends Comparable<T>> extends Iterable<T> {
  final TreeNode<T>? _root;
  _BSTIterator(this._root);

  @override
  Iterator<T> get iterator => _BSTIteratorImpl(_root);
}

class _BSTIteratorImpl<T extends Comparable<T>> implements Iterator<T> {
  final List<TreeNode<T>> _stack = [];
  T? _current;

  _BSTIteratorImpl(TreeNode<T>? root) {
    _pushLeft(root);
  }

  void _pushLeft(TreeNode<T>? node) {
    while (node != null) {
      _stack.add(node);
      node = node.left;
    }
  }

  @override
  T get current {
    if (_current == null) throw StateError("No element");
    return _current!;
  }

  @override
  bool moveNext() {
    if (_stack.isEmpty) return false;
    var node = _stack.removeLast();
    _current = node.value;
    _pushLeft(node.right);
    return true;
  }
}

class ComparableInt implements Comparable<ComparableInt> {
  final int value;

  ComparableInt(this.value);

  @override
  int compareTo(ComparableInt other) => value.compareTo(other.value);

  @override
  String toString() => value.toString();
}

void main() {
  var bst = BinarySearchTree<ComparableInt>();
  for (var value in [5, 3, 7, 2, 4, 6, 8].map((v) => ComparableInt(v))) {
    bst.insert(value);
  }

  print("InOrder traversal:");
  bst.inOrder(print);

  print("\nPreOrder traversal:");
  bst.preOrder(print);

  print("\nPostOrder traversal:");
  bst.postOrder(print);

  print("\nSearch for 4: ${bst.search(ComparableInt(4))}");
  print("Search for 10: ${bst.search(ComparableInt(10))}");

  print("\nDeleting 3...");
  bst.delete(ComparableInt(3));

  print("\nInOrder traversal after deletion:");
  bst.inOrder(print);

  print("\nUsing iterator:");
  for (var value in bst.iterator) {
    print(value);
  }
}

5) manejo de exepciones

abstract class EcommerceException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  EcommerceException(this.message, [this.stackTrace]);

  @override
  String toString() => 'EcommerceException: $message';
}

// Excepciones de Validación de Entrada
class InvalidInputException extends EcommerceException {
  InvalidInputException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class EmptyCartException extends InvalidInputException {
  EmptyCartException([StackTrace? stackTrace])
      : super('El carrito está vacío.', stackTrace);
}

class InvalidEmailFormatException extends InvalidInputException {
  InvalidEmailFormatException([StackTrace? stackTrace])
      : super('Formato de correo electrónico inválido.', stackTrace);
}

// Excepciones de Red
class NetworkException extends EcommerceException {
  NetworkException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class TimeoutException extends NetworkException {
  TimeoutException([StackTrace? stackTrace])
      : super('Tiempo de espera agotado.', stackTrace);
}

class ConnectionFailedException extends NetworkException {
  ConnectionFailedException([StackTrace? stackTrace])
      : super('No se pudo conectar al servidor.', stackTrace);
}

// Excepciones de Autenticación
class AuthenticationException extends EcommerceException {
  AuthenticationException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class InvalidCredentialsException extends AuthenticationException {
  InvalidCredentialsException([StackTrace? stackTrace])
      : super('Credenciales inválidas.', stackTrace);
}

class UserNotFoundException extends AuthenticationException {
  UserNotFoundException([StackTrace? stackTrace])
      : super('Usuario no encontrado.', stackTrace);
}

// Excepciones de Pago
class PaymentException extends EcommerceException {
  PaymentException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class InsufficientFundsException extends PaymentException {
  InsufficientFundsException([StackTrace? stackTrace])
      : super('Fondos insuficientes.', stackTrace);
}

class PaymentFailedException extends PaymentException {
  PaymentFailedException([StackTrace? stackTrace])
      : super('Pago fallido.', stackTrace);
}

// Excepciones de Producto
class ProductException extends EcommerceException {
  ProductException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

class ProductNotFoundException extends ProductException {
  ProductNotFoundException([StackTrace? stackTrace])
      : super('Producto no encontrado.', stackTrace);
}

class OutOfStockException extends ProductException {
  OutOfStockException([StackTrace? stackTrace])
      : super('Producto fuera de stock.', stackTrace);
}

class ErrorLogger {
  static void logError(EcommerceException exception) {
    print('Error: ${exception.message}');
    if (exception.stackTrace != null) {
      print('StackTrace: ${exception.stackTrace}');
    }
    // Aquí puedes implementar el registro en un archivo, base de datos, etc.
  }
}

class EcommerceService {
  void placeOrder(String email, List<String> cartItems) {
    try {
      if (cartItems.isEmpty) {
        throw EmptyCartException();
      }

      if (!email.contains('@')) {
        throw InvalidEmailFormatException();
      }

      // Simulación de error de red
      if (DateTime.now().second % 2 == 0) {
        throw TimeoutException();
      }

      // Simulación de error de pago
      if (DateTime.now().second % 3 == 0) {
        throw InsufficientFundsException();
      }

      print('Pedido realizado con éxito.');
    } on InvalidInputException catch (e) {
      ErrorLogger.logError(e);
      print('Error de validación: ${e.message}');
    } on NetworkException catch (e) {
      ErrorLogger.logError(e);
      print('Error de red: ${e.message}');
    } on PaymentException catch (e) {
      ErrorLogger.logError(e);
      print('Error de pago: ${e.message}');
    } on EcommerceException catch (e) {
      ErrorLogger.logError(e);
      print('Ocurrió un error inesperado: ${e.message}');
    } catch (e) {
      print('Ocurrió un error: $e');
    }
  }
}

void main() {
  var service = EcommerceService();

  // Simulación de varios escenarios
  service.placeOrder("test@example.com", ["product1", "product2"]);
  service.placeOrder("invalid_email", []);
  service.placeOrder("test@example.com", []);
  service.placeOrder("test@example.com", ["product3"]);
}

6) serialisaacion de json y deserializacion
import 'dart:mirrors';
import 'dart:convert';

/// Clase abstracta que define la funcionalidad de serialización y deserialización.
/// Las clases que deseen ser serializables deben extender de JsonSerializable.
abstract class JsonSerializable {
  /// Serializa la instancia a un mapa (Map<String, dynamic>)
  Map<String, dynamic> toJson() {
    final instanceMirror = reflect(this);
    final classMirror = instanceMirror.type;
    final Map<String, dynamic> json = {};

    classMirror.declarations.forEach((symbol, declaration) {
      // Se consideran solo las variables de instancia no estáticas.
      if (declaration is VariableMirror && !declaration.isStatic) {
        final fieldName = MirrorSystem.getName(symbol);
        final fieldValue = instanceMirror.getField(symbol).reflectee;
        json[fieldName] = fieldValue;
      }
    });
    return json;
  }


  static T fromJson<T>(Map<String, dynamic> json, T instance) {
    final instanceMirror = reflect(instance);
    final classMirror = instanceMirror.type;

    json.forEach((key, value) {
      final symbol = Symbol(key);
      if (classMirror.declarations.containsKey(symbol)) {
        instanceMirror.setField(symbol, value);
      }
    });
    return instance;
  }
}


class Persona extends JsonSerializable {
  String nombre;
  int edad;


  Persona({required this.nombre, required this.edad});

  @override
  String toString() => 'Persona(nombre: $nombre, edad: $edad)';
}

void main() {
  // Se crea una instancia de Persona y se serializa a JSON.
  Persona persona = Persona(nombre: 'pedro', edad: 40);
  Map<String, dynamic> jsonMap = persona.toJson();
  String jsonString = jsonEncode(jsonMap);
  print('Serializado: $jsonString');

  // Se deserializa el JSON a una nueva instancia de Persona.
  Map<String, dynamic> parsedJson = jsonDecode(jsonString);
  Persona persona2 = Persona(nombre: '', edad: 0);
  persona2 = JsonSerializable.fromJson(parsedJson, persona2);
  print('Deserializado: $persona2');
}
