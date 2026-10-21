import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';

Color statusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.placed:
      return Colors.orange;
    case OrderStatus.accepted:
      return Colors.blue;
    case OrderStatus.pickedUp:
      return Colors.purple;
    case OrderStatus.delivered:
      return Colors.green;
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Widget? action;
  final bool showProgress;

  const OrderCard({super.key, required this.order, this.action, this.showProgress = true});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${order.storeName}  •  #${order.shortId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Chip(
                  label: Text(order.status.label, style: TextStyle(color: color, fontSize: 12)),
                  backgroundColor: color.withAlpha(30),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (order.status.index + 1) / OrderStatus.values.length,
                color: color,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            const SizedBox(height: 10),
            for (final l in order.lines) Text('${l.qty} × ${l.name}'),
            const Divider(height: 20),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 4),
              Expanded(child: Text(order.address)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 4),
              Text('${order.customerName} - ${order.customerPhone}'),
            ]),
            if (order.courierName != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.two_wheeler, size: 18),
                const SizedBox(width: 4),
                Text('المندوب: ${order.courierName}'),
              ]),
            ],
            const SizedBox(height: 8),
            Text('الإجمالي: ${money(order.total)}  (شامل التوصيل ${money(order.fee)})',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (action != null) ...[
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isCourier = appState.role == 'courier';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(isCourier ? Icons.two_wheeler : Icons.person, size: 40),
        ),
        const SizedBox(height: 12),
        Text(appState.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(appState.phone, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(isCourier ? 'حساب مندوب توصيل' : 'حساب عميل',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: appState.switchRole,
          icon: const Icon(Icons.swap_horiz),
          label: Text(isCourier ? 'التبديل إلى وضع العميل' : 'التبديل إلى وضع المندوب'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: appState.logout,
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل الخروج'),
        ),
      ],
    );
  }
}
