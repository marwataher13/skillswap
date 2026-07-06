import 'package:flutter/material.dart';

class AiIconPainter extends CustomPainter {
  final Color color;

  const AiIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer orbiting nodes (learning network nodes)
    final double nodeRadius = size.width * 0.09;
    final p1 = Offset(cx - size.width * 0.25, cy + size.height * 0.22);
    final p2 = Offset(cx + size.width * 0.28, cy + size.height * 0.18);
    final p3 = Offset(cx + size.width * 0.05, cy - size.height * 0.26);

    // Draw connection lines
    canvas.drawLine(p1, p2, linePaint);
    canvas.drawLine(p2, p3, linePaint);
    canvas.drawLine(p3, p1, linePaint);

    // Draw the circular nodes
    canvas.drawCircle(p1, nodeRadius, paint);
    canvas.drawCircle(p2, nodeRadius, paint);
    canvas.drawCircle(p3, nodeRadius, paint);

    // Draw central sparkle (main AI star)
    final sparklePath = Path();
    final double r = size.width * 0.22; // Sparkle radius

    sparklePath.moveTo(cx, cy - r);
    sparklePath.quadraticBezierTo(cx, cy, cx + r, cy);
    sparklePath.quadraticBezierTo(cx, cy, cx, cy + r);
    sparklePath.quadraticBezierTo(cx, cy, cx - r, cy);
    sparklePath.quadraticBezierTo(cx, cy, cx, cy - r);
    sparklePath.close();

    canvas.drawPath(sparklePath, paint);

    // Draw secondary tiny sparkle at top-right for futuristic balance
    final tinySparklePath = Path();
    final double tr = r * 0.45;
    final tcx = cx + size.width * 0.22;
    final tcy = cy - size.height * 0.18;

    tinySparklePath.moveTo(tcx, tcy - tr);
    tinySparklePath.quadraticBezierTo(tcx, tcy, tcx + tr, tcy);
    tinySparklePath.quadraticBezierTo(tcx, tcy, tcx, tcy + tr);
    tinySparklePath.quadraticBezierTo(tcx, tcy, tcx - tr, tcy);
    tinySparklePath.quadraticBezierTo(tcx, tcy, tcx, tcy - tr);
    tinySparklePath.close();

    canvas.drawPath(tinySparklePath, paint);
  }

  @override
  bool shouldRepaint(covariant AiIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
