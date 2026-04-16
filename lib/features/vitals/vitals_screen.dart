import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../providers.dart';

class VitalsScreen extends ConsumerWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitals = ref.watch(vitalsProvider);
    final latest = vitals.isNotEmpty ? vitals.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Vitals')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B6B),
        onPressed: () => _showAdd(context, ref),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Latest vitals
          if (latest != null) ...[
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(title: 'Heart rate', value: '${latest.heartRate}', unit: 'bpm',
                  icon: Icons.favorite, color: const Color(0xFFFF6B6B)),
                StatCard(title: 'Blood pressure', value: '${latest.systolic}/${latest.diastolic}',
                  unit: 'mmHg', icon: Icons.bloodtype, color: const Color(0xFFFF9F43)),
                StatCard(title: 'SpO2', value: '${latest.spO2.toStringAsFixed(1)}',
                  unit: '%', icon: Icons.air, color: const Color(0xFF74B9FF)),
                StatCard(title: 'Temperature', value: '${latest.temperature.toStringAsFixed(1)}',
                  unit: '°C', icon: Icons.thermostat, color: const Color(0xFF00C896)),
              ],
            ),
            const SizedBox(height: 16),
            // Status indicators
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _statusRow('Heart rate', latest.heartRate, 60, 100, 'bpm'),
                const Divider(color: Colors.white10, height: 20),
                _statusRow('Systolic BP', latest.systolic, 90, 120, 'mmHg'),
                const Divider(color: Colors.white10, height: 20),
                _statusRow('Diastolic BP', latest.diastolic, 60, 80, 'mmHg'),
                const Divider(color: Colors.white10, height: 20),
                _statusRow('SpO2', latest.spO2.round(), 95, 100, '%'),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // History
          if (vitals.isNotEmpty) ...[
            const SectionHeader(title: 'History'),
            ...vitals.map((v) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(DateFormat('MMM d, h:mm a').format(v.date),
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text('❤️ ${v.heartRate}  🩸 ${v.systolic}/${v.diastolic}  💧 ${v.spO2}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            )),
          ],

          if (vitals.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 60),
              child: Text('No vitals logged.\nTap + to add your first reading!',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
            )),
        ]),
      ),
    );
  }

  Widget _statusRow(String label, num value, num low, num high, String unit) {
    final isNormal = value >= low && value <= high;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
      Row(children: [
        Text('$value $unit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isNormal ? const Color(0xFF00C896).withOpacity(0.2) : const Color(0xFFFF6B6B).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(isNormal ? 'Normal' : 'Check',
            style: TextStyle(color: isNormal ? const Color(0xFF00C896) : const Color(0xFFFF6B6B), fontSize: 11)),
        ),
      ]),
    ]);
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    final hr = TextEditingController(text: '72');
    final sys = TextEditingController(text: '120');
    final dia = TextEditingController(text: '80');
    final spo2 = TextEditingController(text: '98.0');
    final temp = TextEditingController(text: '36.6');

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.cardAlt,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Log Vitals', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: InputField(label: 'Heart rate', hint: '72', controller: hr,
              keyboardType: TextInputType.number, suffixText: 'bpm')),
            const SizedBox(width: 12),
            Expanded(child: InputField(label: 'Temperature', hint: '36.6', controller: temp,
              keyboardType: TextInputType.number, suffixText: '°C')),
          ]),
          Row(children: [
            Expanded(child: InputField(label: 'Systolic', hint: '120', controller: sys,
              keyboardType: TextInputType.number, suffixText: 'mmHg')),
            const SizedBox(width: 12),
            Expanded(child: InputField(label: 'Diastolic', hint: '80', controller: dia,
              keyboardType: TextInputType.number, suffixText: 'mmHg')),
          ]),
          InputField(label: 'SpO2', hint: '98.0', controller: spo2,
            keyboardType: TextInputType.number, suffixText: '%'),
          GradientButton(
            text: 'Save Vitals',
            colors: [const Color(0xFFFF6B6B), const Color(0xFFFF9F43)],
            onPressed: () {
              ref.read(vitalsProvider.notifier).add(
                int.tryParse(hr.text) ?? 72,
                int.tryParse(sys.text) ?? 120,
                int.tryParse(dia.text) ?? 80,
                double.tryParse(spo2.text) ?? 98.0,
                double.tryParse(temp.text) ?? 36.6,
              );
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }
}
