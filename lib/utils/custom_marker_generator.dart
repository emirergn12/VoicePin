import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarkerGenerator {
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Cache'i temizle (boyut veya renk güncellemelerinde)
  static void clearCache() {
    _cache.clear();
  }

  static Future<BitmapDescriptor> getCategoryMarker(
    String category,
    Color color,
  ) async {
    if (_cache.containsKey(category)) {
      return _cache[category]!;
    }

    final BitmapDescriptor descriptor = await _createCustomMarkerBitmap(
      category: category,
      color: color,
    );

    _cache[category] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> _createCustomMarkerBitmap({
    required String category,
    required Color color,
  }) async {
    // Küçültülmüş, zarif ve şık kompakt boyutlar (110x130 yerine 56x66)
    const double width = 56.0;
    const double height = 66.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 1. Gölge (Tabanda hafif ve küçük)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      const Rect.fromLTWH(13, 56, 30, 7),
      shadowPaint,
    );

    // 2. Pin gövde rotası
    final Path pinPath = Path();
    const double radius = 20.0;
    const Offset center = Offset(width / 2, radius + 4);

    pinPath.addOval(Rect.fromCircle(center: center, radius: radius));

    final Path pointerPath = Path()
      ..moveTo(width / 2 - 9, center.dy + 11)
      ..lineTo(width / 2, height - 9)
      ..lineTo(width / 2 + 9, center.dy + 11)
      ..close();

    pinPath.addPath(pointerPath, Offset.zero);

    // Dolgu (Kategori Rengi)
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, fillPaint);

    // Beyaz Çerçeve
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(pinPath, borderPaint);

    // İç Şeffaf Daire
    final Paint innerCirclePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, innerCirclePaint);

    // 3. İkon Görseli
    IconData iconData;
    switch (category) {
      case 'Shopping':
        iconData = Icons.shopping_bag_rounded;
        break;
      case 'Work':
        iconData = Icons.work_rounded;
        break;
      case 'Personal':
        iconData = Icons.person_rounded;
        break;
      case 'Other':
        iconData = Icons.push_pin_rounded;
        break;
      default:
        iconData = Icons.mic_rounded;
        break;
    }

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 19.0,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
