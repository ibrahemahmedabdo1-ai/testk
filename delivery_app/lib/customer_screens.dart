import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'widgets.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _index = 0;

  static const _titles = ['المتاجر', 'السلة', 'طلباتي', 'حسابي'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pages = <Widget>[
          const StoresTab(),
          CartTab(onOrdered: () => setState(() => _index = 2)),
          const CustomerOrdersTab(),
          const AccountTab(),
        ];
        return Scaffold(
          appBar: AppBar(title: Text(_titles[_index])),
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.storefront), label: 'المتاجر'),
              NavigationDestination(
                icon: Badge(
                  label: Text('${appState.cartCount}'),
                  isLabelVisible: appState.cartCount > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                label: 'السلة',
              ),
              const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'طلباتي'),
              const NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
            ],
          ),
        );
      },
    );
  }
}

class StoresTab extends StatelessWidget {
  const StoresTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final s in sampleStores)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Text(s.emoji, style: const TextStyle(fontSize: 38)),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s.category}\nالتوصيل خلال ${s.eta}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => StoreScreen(store: s)),
              ),
            ),
          ),
      ],
    );
  }
}

class StoreScreen extends StatelessWidget {
  final Store store;
  const StoreScreen({super.key, required this.store});

  Future<void> _add(BuildContext context, MenuItem m) async {
    if (appState.addToCart(store, m)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء سلة جديدة؟'),
        content: const Text('سلتك تحتوي على منتجات من متجر آخر. هل تريد تفريغها؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تفريغ وإضافة')),
        ],
      ),
    );
    if (ok == true) {
      appState.clearCart();
      appState.addToCart(store, m);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(store.name)),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final m in store.items)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: ListTile(
                    leading: Text(m.emoji, style: const TextStyle(fontSize: 32)),
                    title: Text(m.name),
                    subtitle: Text(money(m.price)),
                    trailing: appState.qtyOf(m) == 0
                        ? IconButton.filled(
                            onPressed: () => _add(context, m),
                            icon: const Icon(Icons.add),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => appState.removeFromCart(m),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${appState.qtyOf(m)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                onPressed: () => _add(context, m),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: appState.cartCount == 0
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${appState.cartCount} منتج • ${money(appState.cartSubtotal)} - العودة للسلة'),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class CartTab extends StatefulWidget {
  final VoidCallback onOrdered;
  const CartTab({super.key, required this.onOrdered});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  final _address = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _order() {
    final address = _address.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('اكتب عنوان التوصيل أولاً')));
      return;
    }
    appState.placeOrder(address);
    _address.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح ✅')));
    widget.onOrdered();
  }

  @override
  Widget build(BuildContext context) {
    if (appState.cart.isEmpty) {
      return const Center(child: Text('السلة فارغة\nاختر متجراً وأضف منتجات', textAlign: TextAlign.center));
    }
    final lines = appState.cart.values.toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('من: ${appState.cartStore?.name ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final l in lines)
                ListTile(
                  leading: Text(l.item.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(l.item.name),
                  subtitle: Text(money(l.item.price * l.qty)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => appState.removeFromCart(l.item),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${l.qty}'),
                      IconButton(
                        onPressed: () => appState.addToCart(appState.cartStore!, l.item),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'عنوان التوصيل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Text('المنتجات: ${money(appState.cartSubtotal)}'),
              Text('التوصيل: ${money(kDeliveryFee)}'),
              Text('الإجمالي: ${money(appState.cartSubtotal + kDeliveryFee)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _order,
                child: const Padding(padding: EdgeInsets.all(12), child: Text('تأكيد الطلب')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomerOrdersTab extends StatelessWidget {
  const CustomerOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = appState.myOrders;
    if (orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات بعد'));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [for (final o in orders) OrderCard(order: o)],
    );
  }
}
