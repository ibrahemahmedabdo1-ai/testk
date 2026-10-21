const double kDeliveryFee = 15;

String money(double v) =>
    '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)} ج.م';

enum OrderStatus { placed, accepted, pickedUp, delivered }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'تم استلام الطلب';
      case OrderStatus.accepted:
        return 'المندوب قبل الطلب';
      case OrderStatus.pickedUp:
        return 'في الطريق إليك';
      case OrderStatus.delivered:
        return 'تم التسليم';
    }
  }
}

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String emoji;
  const MenuItem(this.id, this.name, this.price, this.emoji);
}

class Store {
  final String id;
  final String name;
  final String category;
  final String emoji;
  final String eta;
  final List<MenuItem> items;
  const Store(this.id, this.name, this.category, this.emoji, this.eta, this.items);
}

class CartLine {
  final MenuItem item;
  int qty;
  CartLine(this.item, this.qty);
}

class OrderLine {
  final String name;
  final double price;
  final int qty;
  OrderLine(this.name, this.price, this.qty);

  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'qty': qty};

  factory OrderLine.fromJson(Map<String, dynamic> j) =>
      OrderLine(j['name'] as String, (j['price'] as num).toDouble(), j['qty'] as int);
}

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final String storeName;
  final String address;
  final List<OrderLine> lines;
  final double fee;
  final int createdAt;
  OrderStatus status;
  String? courierName;
  String? courierPhone;

  Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.storeName,
    required this.address,
    required this.lines,
    required this.fee,
    required this.createdAt,
    this.status = OrderStatus.placed,
    this.courierName,
    this.courierPhone,
  });

  double get subtotal => lines.fold<double>(0, (s, l) => s + l.price * l.qty);
  double get total => subtotal + fee;
  String get shortId => id.substring(id.length - 5);

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'storeName': storeName,
        'address': address,
        'lines': lines.map((l) => l.toJson()).toList(),
        'fee': fee,
        'createdAt': createdAt,
        'status': status.index,
        'courierName': courierName,
        'courierPhone': courierPhone,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        customerName: j['customerName'] as String,
        customerPhone: j['customerPhone'] as String,
        storeName: j['storeName'] as String,
        address: j['address'] as String,
        lines: (j['lines'] as List)
            .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        fee: (j['fee'] as num).toDouble(),
        createdAt: j['createdAt'] as int,
        status: OrderStatus.values[j['status'] as int],
        courierName: j['courierName'] as String?,
        courierPhone: j['courierPhone'] as String?,
      );
}

final List<Store> sampleStores = [
  const Store('s1', 'مطعم الشام', 'مشويات وشاورما', '🍗', '25-35 دقيقة', [
    MenuItem('m1', 'شاورما دجاج', 65, '🌯'),
    MenuItem('m2', 'وجبة كباب', 140, '🍢'),
    MenuItem('m3', 'بطاطس مقلية', 30, '🍟'),
    MenuItem('m4', 'عصير برتقال', 25, '🍊'),
  ]),
  const Store('s2', 'بيتزا روما', 'بيتزا ومعجنات', '🍕', '30-40 دقيقة', [
    MenuItem('m5', 'بيتزا مارجريتا', 110, '🍕'),
    MenuItem('m6', 'بيتزا خضار', 120, '🥗'),
    MenuItem('m7', 'فطيرة جبنة', 55, '🥟'),
    MenuItem('m8', 'مياه غازية', 15, '🥤'),
  ]),
  const Store('s3', 'سوبر ماركت الخير', 'بقالة ومشتريات', '🛒', '20-30 دقيقة', [
    MenuItem('m9', 'خبز (10 أرغفة)', 10, '🍞'),
    MenuItem('m10', 'لبن 1 لتر', 38, '🥛'),
    MenuItem('m11', 'بيض (30 بيضة)', 135, '🥚'),
    MenuItem('m12', 'أرز 1 كجم', 40, '🍚'),
  ]),
];
