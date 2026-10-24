import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'data.dart';
import 'models.dart';
import 'state.dart';

// Simple shared notifiers so Home can jump to Search with a category.
final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
final ValueNotifier<String> searchCategory = ValueNotifier<String>('All');

void showMsg(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
}

// ======================= Small reusable widgets =======================

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(Icons.ramen_dining_rounded, color: Colors.white, size: size * 0.55),
      );
}

class DishImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  const DishImage(this.url, {super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) => Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, p) => p == null ? child : Container(height: height, width: width, color: kCream),
        errorBuilder: (c, e, s) => Container(
          height: height,
          width: width,
          color: kCream,
          child: const Icon(Icons.restaurant_rounded, color: kPrimary, size: 36),
        ),
      );
}

class VegDot extends StatelessWidget {
  final bool veg;
  const VegDot(this.veg, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = veg ? kGreen : Colors.red.shade700;
    return Semantics(
      label: veg ? 'Vegetarian' : 'Non-vegetarian',
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(border: Border.all(color: c, width: 1.5), borderRadius: BorderRadius.circular(3)),
        child: Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle))),
      ),
    );
  }
}

class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<AppState, int>((s) => s.cartCount);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class DishCard extends StatelessWidget {
  final Dish dish;
  const DishCard(this.dish, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final qty = s.qtyOf(dish);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showDishSheet(context, dish),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: DishImage(dish.image, height: 96, width: 96)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  VegDot(dish.veg),
                  const SizedBox(width: 6),
                  Expanded(child: Text(dish.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 2),
                Text(dish.restaurant, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  Text(' ${dish.rating}  •  ${dish.mins} min', style: const TextStyle(fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('₹${dish.price}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (dish.discountPercent > 0) ...[
                    const SizedBox(width: 6),
                    Text('₹${dish.mrp}', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 6),
                    Text('${dish.discountPercent}% off', style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ]),
            ),
            Column(children: [
              IconButton(
                tooltip: 'Favourite',
                onPressed: () => s.toggleFav(dish.id),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Icon(s.isFav(dish.id) ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(s.isFav(dish.id)), color: kPrimary),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: () {
                  s.addToCart(dish);
                  showMsg(context, '${dish.name} added to cart');
                },
                child: Text(qty > 0 ? 'ADD · $qty' : 'ADD'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ======================= Splash / Onboarding =======================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final done = context.read<AppState>().onboarded;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => done ? const HomeShell() : const OnboardingScreen()));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kPrimary,
        body: Center(
          child: FadeTransition(
            opacity: _c,
            child: ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                  child: const Icon(Icons.ramen_dining_rounded, color: kPrimary, size: 56),
                ),
                const SizedBox(height: 16),
                const Text(appName, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(appTagline, style: TextStyle(color: Colors.white70)),
              ]),
            ),
          ),
        ),
      );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.explore_rounded, 'Discover food', 'Browse biryani, dosa, pizza, thalis and more.'),
    (Icons.tune_rounded, 'Find it fast', 'Search and filter by veg, price and rating.'),
    (Icons.delivery_dining_rounded, 'Easy ordering', 'Customise, checkout and track your order.'),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<AppState>().finishOnboarding();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _finish, child: const Text('Skip'))),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(radius: 70, backgroundColor: kCream, child: Icon(p.$1, size: 70, color: kPrimary)),
                    const SizedBox(height: 32),
                    Text(p.$2, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(p.$3, textAlign: TextAlign.center),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < _pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(color: i == _page ? kPrimary : Colors.grey.shade400, borderRadius: BorderRadius.circular(8)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: last ? _finish : () => _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: Text(last ? 'Get Started' : 'Next'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ======================= Shell with bottom nav =======================

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, i, _) => Scaffold(
        body: IndexedStack(index: i, children: const [HomeTab(), SearchTab(), OrdersTab(), ProfileTab()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => tabIndex.value = v,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ======================= Home =======================

String currentAddress = savedAddresses[0];

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<void> _pickAddress() async {
    final controller = TextEditingController();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Select delivery location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final a in savedAddresses)
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined, color: kPrimary),
                title: Text(a),
                trailing: a == currentAddress ? const Icon(Icons.check_circle, color: kGreen) : null,
                onTap: () => Navigator.pop(ctx, a),
              ),
            ),
          const SizedBox(height: 8),
          TextField(controller: controller, decoration: const InputDecoration(labelText: 'Or enter a custom address')),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                if (t.isNotEmpty) Navigator.pop(ctx, t);
              },
              child: const Text('Confirm custom address'),
            ),
          ),
        ]),
      ),
    );
    controller.dispose();
    if (picked != null) setState(() => currentAddress = picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final best = dishes.where((d) => d.rating >= 4.4).toList();
    final budget = dishes.where((d) => d.price <= 100).toList();
    final restaurants = dishes.map((d) => d.restaurant).toSet().toList();

    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: _pickAddress,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Deliver to', style: TextStyle(fontSize: 12)),
                Row(children: [
                  const Icon(Icons.location_on, color: kPrimary, size: 18),
                  Expanded(child: Text(currentAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                  const Icon(Icons.keyboard_arrow_down),
                ]),
              ]),
            ),
          ),
          const CartButton(),
          GestureDetector(
            onTap: () => tabIndex.value = 3,
            child: CircleAvatar(backgroundColor: kPrimary, child: Text(s.userName.isEmpty ? '?' : s.userName[0], style: const TextStyle(color: Colors.white))),
          ),
        ]),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => tabIndex.value = 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kCream, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [Icon(Icons.search), SizedBox(width: 8), Text('Search dishes or restaurants', style: TextStyle(color: Colors.black54))]),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('50% OFF up to ₹100', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Use code CRAVE50 on orders above ₹199 (sample offer)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimary, minimumSize: const Size(100, 38)),
                  onPressed: () => tabIndex.value = 1,
                  child: const Text('Order now'),
                ),
              ]),
            ),
            const Icon(Icons.local_offer_rounded, color: Colors.white54, size: 64),
          ]),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length - 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = categories[i + 1];
              return ActionChip(
                label: Text(c),
                onPressed: () {
                  searchCategory.value = c;
                  tabIndex.value = 1;
                },
              );
            },
          ),
        ),
        const _Heading('Popular near you'),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ActionChip(
              avatar: const Icon(Icons.storefront, size: 18, color: kPrimary),
              label: Text(restaurants[i]),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(restaurants[i]))),
            ),
          ),
        ),
        const _Heading('Bestsellers'),
        for (final d in best) Padding(padding: const EdgeInsets.only(bottom: 10), child: DishCard(d)),
        const _Heading('Budget meals under ₹100'),
        for (final d in budget) Padding(padding: const EdgeInsets.only(bottom: 10), child: DishCard(d)),
      ]),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );
}

// ======================= Search =======================

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _q = TextEditingController();
  String _vegFilter = 'All'; // All / Veg / Non-veg
  String _sort = 'Popular'; // Popular / Price low / Price high / Rating

  @override
  void initState() {
    super.initState();
    searchCategory.addListener(_onCat);
  }

  void _onCat() => setState(() {});

  @override
  void dispose() {
    searchCategory.removeListener(_onCat);
    _q.dispose();
    super.dispose();
  }

  List<Dish> get _results {
    final q = _q.text.trim().toLowerCase();
    var list = dishes.where((d) {
      final okQ = q.isEmpty || d.name.toLowerCase().contains(q) || d.restaurant.toLowerCase().contains(q);
      final okC = searchCategory.value == 'All' || d.category == searchCategory.value;
      final okV = _vegFilter == 'All' || (_vegFilter == 'Veg' ? d.veg : !d.veg);
      return okQ && okC && okV;
    }).toList();
    switch (_sort) {
      case 'Price low':
        list.sort((a, b) => a.price.compareTo(b.price));
      case 'Price high':
        list.sort((a, b) => b.price.compareTo(a.price));
      default:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  void _clear() {
    _q.clear();
    searchCategory.value = 'All';
    setState(() {
      _vegFilter = 'All';
      _sort = 'Popular';
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final filtered = _q.text.isNotEmpty || searchCategory.value != 'All' || _vegFilter != 'All' || _sort != 'Popular';
    return Scaffold(
      appBar: AppBar(title: const Text('Search'), actions: const [CartButton()]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search dishes or restaurants',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _q.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_q.clear)),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final c in categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: searchCategory.value == c,
                  onSelected: (_) => searchCategory.value = c,
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final v in ['All', 'Veg', 'Non-veg'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(label: Text(v), selected: _vegFilter == v, onSelected: (_) => setState(() => _vegFilter = v)),
              ),
            const Spacer(),
            DropdownButton<String>(
              value: _sort,
              underline: const SizedBox(),
              items: const ['Popular', 'Price low', 'Price high', 'Rating']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _sort = v ?? 'Popular'),
            ),
          ]),
        ),
        if (filtered) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _clear, child: const Text('Clear filters'))),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('No dishes match your search'),
                    TextButton(onPressed: _clear, child: const Text('Clear filters')),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => DishCard(results[i], key: ValueKey(results[i].id)),
                ),
        ),
      ]),
    );
  }
}

// ======================= Restaurant =======================

class RestaurantScreen extends StatelessWidget {
  final String name;
  const RestaurantScreen(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    final menu = dishes.where((d) => d.restaurant == name).toList();
    final count = context.select<AppState, int>((s) => s.cartCount);
    return Scaffold(
      appBar: AppBar(title: Text(name), actions: const [CartButton()]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: DishImage(menu.first.image, height: 160)),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text('${menu.map((d) => d.category).toSet().join(', ')}  •  Min order ₹99 (sample)'),
        const SizedBox(height: 12),
        for (final d in menu) Padding(padding: const EdgeInsets.only(bottom: 10), child: DishCard(d)),
      ]),
      bottomNavigationBar: count == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Text('View cart ($count items)'),
                ),
              ),
            ),
    );
  }
}

// ======================= Dish details sheet =======================

void showDishSheet(BuildContext context, Dish dish) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DishSheet(dish),
  );
}

class DishSheet extends StatefulWidget {
  final Dish dish;
  const DishSheet(this.dish, {super.key});
  @override
  State<DishSheet> createState() => _DishSheetState();
}

class _DishSheetState extends State<DishSheet> {
  String _size = 'Regular';
  final Set<String> _addons = {};
  int _qty = 1;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _unit => widget.dish.price + (_size == 'Large' ? 50 : 0) + _addons.fold(0, (s, a) => s + (addonPrice[a] ?? 0));

  @override
  Widget build(BuildContext context) {
    final d = widget.dish;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: DishImage(d.image, height: 180, width: double.infinity)),
          const SizedBox(height: 12),
          Row(children: [VegDot(d.veg), const SizedBox(width: 8), Expanded(child: Text(d.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))]),
          const SizedBox(height: 4),
          Text(d.desc),
          const SizedBox(height: 12),
          const Text('Size', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Regular'), selected: _size == 'Regular', onSelected: (_) => setState(() => _size = 'Regular')),
            ChoiceChip(label: const Text('Large (+₹50)'), selected: _size == 'Large', onSelected: (_) => setState(() => _size = 'Large')),
          ]),
          const SizedBox(height: 8),
          const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final a in addonOptions)
              FilterChip(
                label: Text(a),
                selected: _addons.contains(a),
                onSelected: (v) => setState(() => v ? _addons.add(a) : _addons.remove(a)),
              ),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Special instructions (optional)')),
          const SizedBox(height: 12),
          Row(children: [
            IconButton.outlined(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove), tooltip: 'Decrease'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            IconButton.outlined(onPressed: _qty < 20 ? () => setState(() => _qty++) : null, icon: const Icon(Icons.add), tooltip: 'Increase'),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  context.read<AppState>().addToCart(d, size: _size, addons: _addons.toList(), qty: _qty, note: _note.text.trim());
                  Navigator.pop(context);
                  showMsg(context, '${d.name} added to cart');
                },
                child: Text('Add to cart · ₹${_unit * _qty}'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ======================= Cart =======================

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: s.cart.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('Your cart is empty'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.popUntil(context, (r) => r.isFirst);
                    tabIndex.value = 0;
                  },
                  child: const Text('Browse food'),
                ),
              ]),
            )
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final c in s.cart)
                Card(
                  key: ValueKey(c.key),
                  child: ListTile(
                    leading: VegDot(c.dish.veg),
                    title: Text(c.dish.name),
                    subtitle: Text([c.size, ...c.addons, if (c.note.isNotEmpty) 'Note: ${c.note}'].join(' • ')),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(onPressed: () => s.changeQty(c, -1), icon: const Icon(Icons.remove_circle_outline), tooltip: 'Decrease'),
                      Text('${c.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(onPressed: () => s.changeQty(c, 1), icon: const Icon(Icons.add_circle_outline), tooltip: 'Increase'),
                      Text('₹${c.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Coupon code (try CRAVE50)'))),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final err = s.applyCoupon(_code.text);
                    showMsg(context, err ?? 'Coupon applied!');
                  },
                  child: const Text('Apply'),
                ),
              ]),
              if (s.coupon != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: kGreen),
                  title: Text('${s.coupon} applied'),
                  trailing: TextButton(onPressed: s.removeCoupon, child: const Text('Remove')),
                ),
              const SizedBox(height: 12),
              BillSummary(s),
            ]),
      bottomNavigationBar: s.cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                  child: Text('Checkout · ₹${s.total}'),
                ),
              ),
            ),
    );
  }
}

class BillSummary extends StatelessWidget {
  final AppState s;
  const BillSummary(this.s, {super.key});

  Widget _row(String l, String v, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null, color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _row('Item subtotal', '₹${s.subtotal}'),
            _row('Delivery fee', s.delivery == 0 ? 'FREE' : '₹${s.delivery}'),
            _row('Platform fee', '₹${s.platform}'),
            if (s.discount > 0) _row('Discount', '-₹${s.discount}', color: kGreen),
            const Divider(),
            _row('To pay', '₹${s.total}', bold: true),
          ]),
        ),
      );
}

// ======================= Checkout =======================

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AppState>().userName);
  late final _phone = TextEditingController(text: context.read<AppState>().userPhone);
  final _instr = TextEditingController();
  String _address = currentAddress;
  String _pay = 'Cash on Delivery';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _instr.dispose();
    super.dispose();
  }

  void _place() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final order = s.placeOrder(_address);
    if (order == null) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ConfirmScreen(order)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final addresses = {...savedAddresses, currentAddress}.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Delivery address', style: TextStyle(fontWeight: FontWeight.w800)),
          RadioGroup<String>(
            groupValue: _address,
            onChanged: (v) => setState(() => _address = v ?? _address),
            child: Column(
              children: [
                for (final a in addresses)
                  RadioListTile<String>(
                    value: a,
                    title: Text(a),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
            validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid 10-digit number',
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _instr, decoration: const InputDecoration(labelText: 'Delivery instructions (optional)')),
          const SizedBox(height: 16),
          const Text('Payment (simulated - no real payment)', style: TextStyle(fontWeight: FontWeight.w800)),
          RadioGroup<String>(
            groupValue: _pay,
            onChanged: (v) => setState(() => _pay = v ?? _pay),
            child: Column(
              children: [
                for (final p in ['Cash on Delivery', 'UPI (simulated)', 'Card (simulated)'])
                  RadioListTile<String>(
                    value: p,
                    title: Text(p),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BillSummary(s),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(onPressed: s.cart.isEmpty ? null : _place, child: Text('Place order · ₹${s.total}')),
        ),
      ),
    );
  }
}

// ======================= Confirmation + tracking =======================

const List<String> orderStages = ['Order placed', 'Restaurant preparing', 'Order picked up', 'Delivered'];

class ConfirmScreen extends StatefulWidget {
  final Order order;
  const ConfirmScreen(this.order, {super.key});
  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  Timer? _t;
  int _stage = 0;

  @override
  void initState() {
    super.initState();
    // Frontend simulation only: advance a stage every 4 seconds.
    _t = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted) return;
      if (_stage < orderStages.length - 1) {
        setState(() => _stage++);
        context.read<AppState>().setStatus(widget.order, orderStages[_stage]);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Order confirmed'), automaticallyImplyLeading: false),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Icon(Icons.check_circle, color: kGreen, size: 72),
          const SizedBox(height: 8),
          Center(child: Text('Order ${o.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          const Center(child: Text('Estimated delivery: 30-40 min (sample)')),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                for (final i in o.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text('${i.qty} x ${i.dish.name}')), Text('₹${i.total}')]),
                  ),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total paid', style: TextStyle(fontWeight: FontWeight.w800)), Text('₹${o.total}', style: const TextStyle(fontWeight: FontWeight.w800))]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Order progress (simulated)', style: TextStyle(fontWeight: FontWeight.w800)),
          for (int i = 0; i < orderStages.length; i++)
            ListTile(
              dense: true,
              leading: Icon(i <= _stage ? Icons.check_circle : Icons.radio_button_unchecked, color: i <= _stage ? kGreen : Colors.grey),
              title: Text(orderStages[i], style: TextStyle(fontWeight: i == _stage ? FontWeight.w800 : null)),
            ),
        ]),
        bottomNavigationBar: SafeArea(
          child: Padding(padding: const EdgeInsets.all(12), child: FilledButton(onPressed: _home, child: const Text('Back to home'))),
        ),
      ),
    );
  }

  void _home() {
    tabIndex.value = 0;
    Navigator.popUntil(context, (r) => r.isFirst);
  }
}

// ======================= Orders =======================

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  return '${d.inDays} day(s) ago';
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Your orders'), actions: const [CartButton()]),
      body: s.orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: s.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = s.orders[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(o.id, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(o.status, style: TextStyle(color: o.status == 'Delivered' ? kGreen : kPrimary, fontWeight: FontWeight.w700)),
                      ]),
                      Text(_ago(o.time), style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(o.items.map((e) => '${e.qty} x ${e.dish.name}').join(', ')),
                      const SizedBox(height: 6),
                      Text('Total ₹${o.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(o))),
                          child: const Text('View details'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size(90, 38)),
                          onPressed: () {
                            s.reorder(o);
                            showMsg(context, 'Items added to cart');
                          },
                          child: const Text('Reorder'),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen(this.order, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(order.id)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Status: ${order.status}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('Placed: ${_ago(order.time)}'),
          Text('Address: ${order.address}'),
          const Divider(height: 24),
          for (final i in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: VegDot(i.dish.veg),
              title: Text('${i.qty} x ${i.dish.name}'),
              subtitle: Text([i.size, ...i.addons].join(' • ')),
              trailing: Text('₹${i.total}'),
            ),
          const Divider(height: 24),
          Text('Total: ₹${order.total}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
      );
}

// ======================= Profile =======================

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _edit(BuildContext context) {
    final s = context.read<AppState>();
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: s.userName);
    final phone = TextEditingController(text: s.userPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 10),
            TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '') ? null : 'Invalid number'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              s.updateProfile(name.text.trim(), phone.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      name.dispose();
      phone.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (!s.signedIn)
          Column(children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
            const Text('You are signed out'),
            const SizedBox(height: 12),
            FilledButton(onPressed: s.toggleSignIn, child: const Text('Sign in (simulated)')),
          ])
        else ...[
          Row(children: [
            CircleAvatar(radius: 32, backgroundColor: kPrimary, child: Text(s.userName.isEmpty ? '?' : s.userName[0], style: const TextStyle(fontSize: 26, color: Colors.white))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('+91 ${s.userPhone}')])),
            IconButton(onPressed: () => _edit(context), icon: const Icon(Icons.edit), tooltip: 'Edit profile'),
          ]),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.favorite_border), title: const Text('Favourites'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouritesScreen()))),
          ListTile(leading: const Icon(Icons.receipt_long), title: const Text('Order history'), trailing: const Icon(Icons.chevron_right), onTap: () => tabIndex.value = 2),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Saved addresses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Saved addresses'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [for (final a in savedAddresses) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.home_outlined), title: Text(a))]),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ),
            ),
          ),
          SwitchListTile(secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark theme'), value: s.darkMode, onChanged: s.setDark),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & About'),
            onTap: () => showAboutDialog(context: context, applicationName: appName, applicationVersion: '1.0.0', children: const [Text('Demo app. All food, prices, ratings and offers are sample data. No real orders or payments.')]),
          ),
          ListTile(leading: const Icon(Icons.logout, color: kPrimary), title: const Text('Sign out'), onTap: s.toggleSignIn),
        ],
      ]),
    );
  }
}

// ======================= Favourites =======================

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favs = dishes.where((d) => s.isFav(d.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: favs.isEmpty
          ? const Center(child: Text('No favourites yet. Tap the heart on any dish.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => DishCard(favs[i], key: ValueKey(favs[i].id)),
            ),
    );
  }
}
