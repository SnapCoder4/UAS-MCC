import 'package:flutter/material.dart';
import '../widgets/gym_ui_widgets.dart';

class ClassSchedulePage extends StatefulWidget {
  const ClassSchedulePage({super.key});

  @override
  State<ClassSchedulePage> createState() => _ClassSchedulePageState();
}

class _ClassSchedulePageState extends State<ClassSchedulePage> {
  final List<Map<String, String>> classes = const [
    {
      "title": "Yoga Flow",
      "time": "Senin • 07:00",
      "coach": "Coach Rina",
      "level": "Beginner",
    },
    {
      "title": "HIIT Blast",
      "time": "Selasa • 18:30",
      "coach": "Coach Dimas",
      "level": "Intermediate",
    },
    {
      "title": "Strength Basics",
      "time": "Kamis • 19:00",
      "coach": "Coach Alvin",
      "level": "Beginner",
    },
    {
      "title": "Cardio Dance",
      "time": "Sabtu • 09:00",
      "coach": "Coach Naya",
      "level": "All level",
    },
  ];

  final Set<String> booked = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jadwal Kelas")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BannerCard(
            title: "Kelas Minggu Ini",
            subtitle: "Ada ${classes.length} kelas • Tap kelas untuk detail",
            rightIcon: Icons.event_available,
            gradientColors: [Colors.purple.shade500, Colors.indigo.shade800],
          ),
          const SizedBox(height: 14),
          const Text(
            "List Jadwal",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...classes.map((c) {
            final title = c["title"]!;
            final isBooked = booked.contains(title);

            return Card(
              elevation: 1.5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                onTap: () => _showClassModal(
                  title: title,
                  time: c["time"]!,
                  coach: c["coach"]!,
                  level: c["level"]!,
                  isBooked: isBooked,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withOpacity(0.15),
                  child: const Icon(Icons.event_note, color: Colors.purple),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(c["time"]!),
                    Text(
                      "${c["coach"]!} • ${c["level"]!}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (isBooked) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.green.withOpacity(0.14),
                        ),
                        child: const Text(
                          "Booked",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showClassModal({
    required String title,
    required String time,
    required String coach,
    required String level,
    required bool isBooked,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 10),
              InfoRow(icon: Icons.schedule, text: time),
              InfoRow(icon: Icons.person_outline, text: coach),
              InfoRow(icon: Icons.bar_chart, text: "Level: $level"),
              const Divider(),
              const Text(
                "Catatan",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                "Datang 10 menit lebih awal. Bawa handuk & botol minum. Pemanasan wajib.",
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      if (booked.contains(title)) {
                        booked.remove(title);
                        showToast(context, "Booking dibatalkan");
                      } else {
                        booked.add(title);
                        showToast(context, "Booking berhasil");
                      }
                    });
                  },
                  icon: Icon(isBooked ? Icons.close : Icons.check),
                  label: Text(isBooked ? "Batalkan Booking" : "Book Kelas"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
