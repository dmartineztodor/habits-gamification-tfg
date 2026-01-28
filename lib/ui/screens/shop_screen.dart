import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos las monedas en tiempo real para actualizar la barra superior
    final userStats = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mercader"),
        actions: [
          // Mostrador de monedas en la esquina
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Text("💰 ", style: TextStyle(fontSize: 18)),
                userStats.when(
                  data: (user) => Text(
                    "${user?.coins ?? 0}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  loading: () => const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const Text("?"),
                ),
              ],
            ),
          )
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2, // 2 columnas
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Tarjetas un poco más altas que anchas
        children: [
          // ÍTEMS DE EJEMPLO
          _ShopItem(
            name: "Poción de Salud",
            description: "Recupera tu racha perdida (Próximamente)",
            price: 50,
            icon: Icons.local_drink,
            color: Colors.redAccent,
          ),
          _ShopItem(
            name: "Escudo Divino",
            description: "Te protege de fallar un día",
            price: 150,
            icon: Icons.shield,
            color: Colors.blueAccent,
          ),
          _ShopItem(
            name: "Cofre Misterioso",
            description: "¿Qué habrá dentro?",
            price: 500,
            icon: Icons.inventory_2,
            color: Colors.purpleAccent,
          ),
          _ShopItem(
            name: "Corona de Rey",
            description: "Cosmético legendario",
            price: 1000,
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para cada tarjeta de producto
class _ShopItem extends ConsumerStatefulWidget {
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  const _ShopItem({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });

  @override
  ConsumerState<_ShopItem> createState() => _ShopItemState();
}

class _ShopItemState extends ConsumerState<_ShopItem> {
  bool _isBuying = false;

  void _buy() async {
    setState(() => _isBuying = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        // Llamamos a la función de gastar dinero que creamos en el Paso 1
        await ref.read(authRepositoryProvider).purchaseItem(user.uid, widget.price);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("¡Has comprado ${widget.name}! 🎉"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Si no tiene dinero o hay error, sale esto:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(widget.icon, size: 50, color: widget.color),
            Column(
              children: [
                Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(widget.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBuying ? null : _buy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color.withOpacity(0.2),
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
                child: _isBuying 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text("${widget.price} 💰"),
              ),
            )
          ],
        ),
      ),
    );
  }
}