import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/health_calc.dart';
import '../../data/models/models.dart';
import '../providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  const ProfileScreen({super.key, this.isSetup = false});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();
  bool _isMale = true;

  @override
  void initState() {
    super.initState();
    final u = ref.read(userProvider);
    if (u != null) {
      _name.text = u.name; _weight.text = u.weightKg.toString();
      _height.text = u.heightCm.toString(); _age.text = u.age.toString();
      _isMale = u.isMale;
    }
  }

  void _save() {
    if (_name.text.isEmpty || _weight.text.isEmpty || _height.text.isEmpty || _age.text.isEmpty) return;
    final u = UserProfile(
      name: _name.text,
      weightKg: double.tryParse(_weight.text) ?? 70,
      heightCm: double.tryParse(_height.text) ?? 170,
      age: int.tryParse(_age.text) ?? 25,
      isMale: _isMale,
    );
    ref.read(userProvider.notifier).save(u);
    if (widget.isSetup) Navigator.pushReplacementNamed(context, '/home');
    else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!'))); }
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(userProvider);
    final bmi = u != null ? HealthCalc.bmi(u.weightKg, u.heightCm) : null;

    return Scaffold(
      appBar: widget.isSetup ? null : AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.isSetup) ...[
              const SizedBox(height: 20),
              Text('Welcome! 👋', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text('Set up your profile to get started', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 28),
            ],
            if (bmi != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF6C63FF)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _bmiInfo('BMI', bmi.toStringAsFixed(1)),
                  _bmiInfo('Category', HealthCalc.bmiCategory(bmi)),
                  _bmiInfo('Daily Steps', '${HealthCalc.dailyStepGoal(bmi)}'),
                  _bmiInfo('Walk km', HealthCalc.dailyWalkingKm(bmi).toStringAsFixed(1)),
                ]),
              ),
              const SizedBox(height: 20),
            ],
            InputField(label: 'Name', hint: 'Your name', controller: _name),
            InputField(label: 'Weight', hint: '70', controller: _weight,
              keyboardType: TextInputType.number, suffixText: 'kg'),
            InputField(label: 'Height', hint: '170', controller: _height,
              keyboardType: TextInputType.number, suffixText: 'cm'),
            InputField(label: 'Age', hint: '25', controller: _age,
              keyboardType: TextInputType.number, suffixText: 'yrs'),
            const Text('Gender', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _genderBtn('Male', Icons.male, true),
              const SizedBox(width: 12),
              _genderBtn('Female', Icons.female, false),
            ]),
            const SizedBox(height: 24),
            GradientButton(text: widget.isSetup ? 'Get Started' : 'Save Profile', onPressed: _save),
          ]),
        ),
      ),
    );
  }

  Widget _bmiInfo(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);

  Widget _genderBtn(String label, IconData icon, bool male) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _isMale = male),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isMale == male ? (male ? const Color(0xFF6C63FF) : const Color(0xFFFF6B9D)) : const Color(0xFF1A1D26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isMale == male ? Colors.transparent : Colors.white12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}
