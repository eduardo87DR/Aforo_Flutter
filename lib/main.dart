import 'package:flutter/material.dart';

void main() {
  runApp(const AforoApp());
}

///! miapp principal
class AforoApp extends StatelessWidget {
  const AforoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Aforo Ferry',
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const AforoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

///?pantalla principal con el estado, capcidad e historial
class AforoHomePage extends StatefulWidget {
  const AforoHomePage({super.key});
  @override
  State<AforoHomePage> createState() => _AforoHomePageState();
}

class _AforoHomePageState extends State<AforoHomePage> {
  final TextEditingController _capacityController = TextEditingController();
  final FocusNode _capacityFocusNode = FocusNode();
  int _capacity = 0, _current = 0;
  final List<String> _history = [];

  @override
  void dispose() {
    _capacityController.dispose();
    _capacityFocusNode.dispose();
    super.dispose();
  }

  //? aqui añadimos el historial con la hora
  void _addHistory(String text) {
    final now = TimeOfDay.now();
    setState(() {
      _history.insert(0, '${now.format(context)} · $text');
    });
  }

  //pop ups
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  //applicar capacidad
  void _applyCapacity() {
    final parsed = int.tryParse(_capacityController.text.trim());
    if (parsed == null || parsed <= 0) {
      _showMessage('Capacidad inválida');
      return;
    }
    setState(() {
      _capacity = parsed;
      if (_current > _capacity) _current = _capacity;
      _addHistory('Capacidad establecida: $_capacity');
    });
    _capacityFocusNode.unfocus();
  }

  //Cambiar conteo
  void _changeCount(int delta) {
    if (_capacity <= 0) return _showMessage('Primero aplica capacidad');

    final nuevo = _current + delta;

    // Validar exceso hacia arriba
    if (nuevo > _capacity) {
      _showMessage(
        'No puedes añadir ${delta.abs()} personas, excede la capacidad ($_capacity)',
      );
      return;
    }

    // Validar que no baje de 0
    if (nuevo < 0) {
      _showMessage('No puedes restar más, ya está en 0');
      return;
    }

    // Si pasa las validaciones, aplicar cambio
    setState(() {
      _addHistory(
        '${delta > 0 ? "Entraron" : "Salieron"} ${delta.abs()} → $nuevo/$_capacity',
      );
      _current = nuevo;
    });
  }

  // Reiniciar aforo
  void _resetAforo() {
    if (_capacity <= 0) return _showMessage('No hay capacidad definida');
    setState(() {
      _current = 0;
      _addHistory('Reinicio de aforo');
    });
  }

  //? porcentaje de la ocupacion dentro del ferry
  double get _pct => _capacity == 0 ? 0 : _current / _capacity;

  //! este es el semaforo
  Widget _semaforoCircle(Color color, bool activo) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activo ? color : Colors.grey.shade300,
        boxShadow: activo
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
            : null,
      ),
    );
  }

  //!esta es la seccion donde se muestra el semaforo con el aforo
  @override
  Widget build(BuildContext context) {
    final p = _pct;
    final verde = p < .6, amarillo = p >= .6 && p < .9, rojo = p >= .9;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de aforo en Ferry: Isla Mujeres'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con bordes redondeados
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://blog.garrafon.com.mx/wp-content/uploads/2023/01/ferry-a-isla-mujeres.jpg',
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),

            //?Capacidad y boton
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacityController,
                    focusNode: _capacityFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Capacidad máxima',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyCapacity(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyCapacity,
                  child: const Text('Aplicar'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Panel de estado
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              'Aforo: $_current/$_capacity',
                              key: ValueKey(_current),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Ocupación: ${(p * 100).toStringAsFixed(0)}%'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: p,
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        _semaforoCircle(Colors.green, verde),
                        const SizedBox(height: 6),
                        _semaforoCircle(Colors.amber, amarillo),
                        const SizedBox(height: 6),
                        _semaforoCircle(Colors.red, rojo),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botonera de control organizada por filas
            Column(
              children: [
                // Fila de sumar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var d in [1, 2, 5])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ElevatedButton.icon(
                          onPressed: () => _changeCount(d),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text('$d'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Fila de restar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var d in [1, 2, 5])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ElevatedButton.icon(
                          onPressed: () => _changeCount(-d),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.remove),
                          label: Text('$d'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                //botonn de reinicio
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _resetAforo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text(
                        'Reiniciar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 17),

            // Historial
            const Text(
              'Historial de eventos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('Aún no hay eventos.'))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (c, i) {
                        final evento = _history[i];

                        IconData icono = Icons.info;
                        Color color = Colors.blueGrey;
                        String titulo = evento;
                        String hora = "";

                        if (evento.contains("Entraron")) {
                          icono = Icons.arrow_upward;
                          color = Colors.green.shade600;
                        } else if (evento.contains("Salieron")) {
                          icono = Icons.arrow_downward;
                          color = Colors.red.shade600;
                        } else if (evento.contains("Capacidad")) {
                          icono = Icons.settings;
                          color = Colors.blue.shade600;
                        } else if (evento.contains("Reinicio")) {
                          icono = Icons.restart_alt;
                          color = Colors.orange.shade700;
                        }

                        final partes = evento.split("·");
                        if (partes.length == 2) {
                          hora = partes[0].trim();
                          titulo = partes[1].trim();
                        }

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.2),
                              child: Icon(icono, color: color),
                            ),
                            title: Text(
                              titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              hora,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
