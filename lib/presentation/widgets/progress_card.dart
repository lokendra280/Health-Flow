import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitflow/presentation/widgets/ring_painter.dart';

class ProgressCard extends StatelessWidget {
  final int done, total, streak, longest;
  const ProgressCard({
    required this.done,
    required this.total,
    required this.streak,
    required this.longest,
  });

  @override
  Widget build(BuildContext ctx) {
    final pct = total == 0 ? 0.0 : done / total;
    final msgs = [
      'Start checking in! 💪',
      'Keep the momentum! ⚡',
      'Great work today!',
      'Almost there! Push!',
      'Perfect day! 🎉',
    ];
    final mi = total == 0 ? 0 : (pct * 4).floor().clamp(0, 4);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF52B788)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
            top: -28,
            right: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0x0AFFFFFF)),
            )),
        Row(children: [
          // Ring
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: RingPainter(pct),
              child: Center(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, __) => Text('${(v * 100).round()}%',
                        style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  Text('$done/$total',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: Colors.white60)),
                ],
              )),
            ),
          ),
          const Gap(20),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Progress",
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.white60, letterSpacing: 0.4)),
              const Gap(8),
              Row(children: [
                _MiniChip('🔥', '${streak}d'),
                const Gap(6),
                _MiniChip('🏆', 'Best ${longest}d'),
              ]),
              const Gap(10),
              Text(msgs[mi],
                  style:
                      GoogleFonts.dmSans(fontSize: 12, color: Colors.white54)),
            ],
          )),
        ]),
      ]),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String emoji, label;
  const _MiniChip(this.emoji, this.label);
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const Gap(4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
      );
}
