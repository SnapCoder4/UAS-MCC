import 'package:flutter/material.dart';
import '../widgets/gym_ui_widgets.dart';

class PersonalTrainerPage extends StatelessWidget {
  const PersonalTrainerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trainers = const [
      {
        "name": "Alvin Pratama",
        "spec": "Strength • Hypertrophy",
        "rate": "4.9",
        "img":
            "https://images.unsplash.com/photo-1550345332-09e3ac987658?auto=format&fit=crop&w=900&q=60",
      },
      {
        "name": "Naya Putri",
        "spec": "Cardio • Fat loss",
        "rate": "4.8",
        "img":
            "https://images.unsplash.com/photo-1605296867304-46d5465a13f1?auto=format&fit=crop&w=900&q=60",
      },
      {
        "name": "Rina Wulandari",
        "spec": "Yoga • Mobility",
        "rate": "4.9",
        "img":
            "https://images.unsplash.com/photo-1549576490-b0b4831ef60a?auto=format&fit=crop&w=900&q=60",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Personal Trainer")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BannerCard(
            title: "Pilih Trainer",
            subtitle: "Sesuaikan dengan target dan jadwal kamu",
            rightIcon: Icons.sports_gymnastics,
            gradientColors: [Colors.red.shade500, Colors.red.shade900],
          ),
          const SizedBox(height: 14),
          const Text(
            "Daftar Trainer",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...trainers.map(
            (t) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showTrainerModal(
                  context,
                  name: t["name"] as String,
                  spec: t["spec"] as String,
                  rate: t["rate"] as String,
                  imageUrl: t["img"] as String,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: Image.network(
                            t["img"] as String,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t["name"] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t["spec"] as String,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  t["rate"] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrainerModal(
    BuildContext context, {
    required String name,
    required String spec,
    required String rate,
    required String imageUrl,
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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: Text(spec)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "$rate / 5.0",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Paket",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              const PriceTile(
                title: "1 Session",
                subtitle: "45–60 menit",
                price: "Rp 120.000",
              ),
              const PriceTile(
                title: "8 Sessions",
                subtitle: "Program 1 bulan",
                price: "Rp 850.000",
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showToast(context, "Chat dibuka");
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Chat"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showToast(context, "Permintaan booking terkirim");
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Book"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
