class Dish {
  final String id;
  final String name;
  final String restaurant;
  final String category;
  final int price;
  final int mrp;
  final bool veg;
  final double rating;
  final int mins;
  final String image;
  final String desc;

  const Dish({
    required this.id,
    required this.name,
    required this.restaurant,
    required this.category,
    required this.price,
    required this.mrp,
    required this.veg,
    required this.rating,
    required this.mins,
    required this.image,
    required this.desc,
  });

  int get discountPercent => mrp > price ? (((mrp - price) * 100) / mrp).round() : 0;
}

class CartItem {
  final Dish dish;
  final String size; // Regular / Large
  final List<String> addons;
  final int unitPrice;
  final String note;
  int qty;

  CartItem({
    required this.dish,
    required this.size,
    required this.addons,
    required this.unitPrice,
    this.note = '',
    this.qty = 1,
  });

  /// Same dish + same size + same add-ons = same cart line.
  String get key => '${dish.id}|$size|${(List<String>.from(addons)..sort()).join(',')}';

  int get total => unitPrice * qty;
}

class Order {
  final String id;
  final List<CartItem> items;
  final int total;
  final DateTime time;
  final String address;
  String status;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.time,
    required this.address,
    this.status = 'Order placed',
  });
}
