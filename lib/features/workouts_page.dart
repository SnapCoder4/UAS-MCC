import 'package:flutter/material.dart';
import '../widgets/gym_ui_widgets.dart';

class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = [
      {
        "title": "Beginner Full Body",
        "desc": "12–18 menit • 6 gerakan",
        "tag": "Beginner",
        "icon": Icons.bolt,
      },
      {
        "title": "Upper Body Pump",
        "desc": "25–35 menit • Strength",
        "tag": "Strength",
        "icon": Icons.fitness_center,
      },
      {
        "title": "Cardio Burn",
        "desc": "15–20 menit • HIIT",
        "tag": "HIIT",
        "icon": Icons.local_fire_department,
      },
      {
        "title": "Core & Abs",
        "desc": "10–15 menit • Core",
        "tag": "Core",
        "icon": Icons.speed,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Latihan")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BannerCard(
            title: "Latihan Hari Ini",
            subtitle: "Pilih plan yang sesuai target kamu",
            rightIcon: Icons.play_circle_fill,
            gradientColors: [
              Colors.orange.shade400,
              Colors.deepOrange.shade700,
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Rekomendasi Plan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...plans.map((p) {
            return Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                onTap: () => _showWorkoutModal(
                  context,
                  title: p["title"] as String,
                  subtitle: p["desc"] as String,
                ),
                leading: CircleAvatar(child: Icon(p["icon"] as IconData)),
                title: Text(
                  p["title"] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(p["desc"] as String),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showWorkoutModal(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        final moves = [
          "Jumping Jack • 45s",
          "Push-up (Knee) • 12x",
          "Bodyweight Squat • 15x",
          "Plank • 30s",
          "Mountain Climber • 30s",
          "Stretch • 2 menit",
        ];

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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle),
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                "Rangkaian Gerakan",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...moves.map(
                (m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(m)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showToast(context, "Latihan dimulai");
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Mulai Latihan"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
