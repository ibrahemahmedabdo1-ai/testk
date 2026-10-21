import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'widgets.dart';

class CourierHome extends StatefulWidget {
  const CourierHome({super.key});

  @override
  State<CourierHome> createState() => _CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  int _index = 0;

  static const _titles = ['طلبات متاحة', 'توصيلاتي', 'حسابي'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pages = <Widget>[
          const AvailableOrdersTab(),
          const MyDeliveriesTab(),
          const AccountTab(),
        ];
        return Scaffold(
          appBar: AppBar(title: Text(_titles[_index])),
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: Badge(
                  label: Text('${appState.availableOrders.length}'),
                  isLabelVisible: appState.availableOrders.isNotEmpty,
                  child: const Icon(Icons.notifications_none),
                ),
                label: 'متاحة',
              ),
              const NavigationDestination(icon: Icon(Icons.two_wheeler), label: 'توصيلاتي'),
              const NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
            ],
          ),
        );
      },
    );
  }
}

class AvailableOrdersTab extends StatelessWidget {
  const AvailableOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = appState.availableOrders;
    if (orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات متاحة حالياً'));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final o in orders)
          OrderCard(
            order: o,
            showProgress: false,
            action: FilledButton.icon(
              onPressed: () => appState.acceptOrder(o),
              icon: const Icon(Icons.check),
              label: const Text('قبول الطلب'),
            ),
          ),
      ],
    );
  }
}

class MyDeliveriesTab extends StatelessWidget {
  const MyDeliveriesTab({super.key});

  Widget? _action(Order o) {
    switch (o.status) {
      case OrderStatus.accepted:
        return FilledButton.icon(
          onPressed: () => appState.advanceOrder(o),
          icon: const Icon(Icons.shopping_bag),
          label: const Text('تم استلام الطلب من المتجر'),
        );
      case OrderStatus.pickedUp:
        return FilledButton.icon(
          onPressed: () => appState.advanceOrder(o),
          icon: const Icon(Icons.done_all),
          label: const Text('تم التسليم للعميل'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = appState.courierOrders;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('${orders.where((o) => o.status == OrderStatus.delivered).length}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const Text('تم تسليمها'),
                ]),
                Column(children: [
                  Text(money(appState.courierEarnings),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const Text('الأرباح'),
                ]),
              ],
            ),
          ),
        ),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('لم تقبل أي طلب بعد')),
          ),
        for (final o in orders) OrderCard(order: o, action: _action(o)),
      ],
    );
  }
}
