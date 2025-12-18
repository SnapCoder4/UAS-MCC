import 'package:flutter/material.dart';
import '../widgets/gym_ui_widgets.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final meals = const [
    {
      "name": "Chicken Salad Bowl",
      "kcal": "420 kcal",
      "desc": "Protein tinggi • low sugar",
      "img":
          "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=60",
      "detail":
          "Ayam panggang, lettuce, tomat, olive oil. Cocok untuk pola makan tinggi protein.",
    },
    {
      "name": "Oat & Banana",
      "kcal": "330 kcal",
      "desc": "Energy boost • pagi",
      "img":
          "https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?auto=format&fit=crop&w=900&q=60",
      "detail":
          "Oat + susu + pisang. Tambah madu secukupnya bila butuh kalori ekstra.",
    },
    {
      "name": "Salmon & Rice",
      "kcal": "520 kcal",
      "desc": "Omega 3 • recovery",
      "img":
          "https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=900&q=60",
      "detail":
          "Salmon, nasi, sayur. Bagus untuk recovery setelah latihan intens.",
    },
    {
      "name": "Greek Yogurt Mix",
      "kcal": "280 kcal",
      "desc": "Snack • high protein",
      "img":
          "https://images.unsplash.com/photo-1482049016688-2d3e1b311543?auto=format&fit=crop&w=900&q=60",
      "detail":
          "Greek yogurt + granola + buah. Snack cepat, tetap tinggi protein.",
    },
  ];

  final Set<String> favorites = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nutrisi")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ImageBanner(
            title: "Menu Rekomendasi",
            subtitle: "Pilih menu untuk lihat detail",
            imageUrl:
                "https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=1200&q=60",
          ),
          const SizedBox(height: 14),
          const Text(
            "Pilihan Menu",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...meals.map((m) {
            final name = m["name"] as String;
            final isFav = favorites.contains(name);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showMealModal(
                  name: name,
                  kcal: m["kcal"] as String,
                  detail: m["detail"] as String,
                  imageUrl: m["img"] as String,
                  isFav: isFav,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      child: SizedBox(
                        width: 110,
                        height: 90,
                        child: Image.network(
                          m["img"] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade800,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isFav
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  m["kcal"] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m["desc"] as String,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showMealModal({
    required String name,
    required String kcal,
    required String detail,
    required String imageUrl,
    required bool isFav,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade800,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    kcal,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(detail),
              const SizedBox(height: 12),
              const Divider(),
              const Text("Tips", style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                "• Perhatikan porsi\n• Prioritaskan protein\n• Konsisten dengan jadwal makan",
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      if (favorites.contains(name)) {
                        favorites.remove(name);
                        showToast(context, "Dihapus dari favorit");
                      } else {
                        favorites.add(name);
                        showToast(context, "Disimpan ke favorit");
                      }
                    });
                  },
                  icon: Icon(
                    isFav ? Icons.bookmark_remove : Icons.bookmark_add_outlined,
                  ),
                  label: Text(
                    isFav ? "Hapus dari Favorit" : "Simpan ke Favorit",
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
