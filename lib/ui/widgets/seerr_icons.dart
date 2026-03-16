import 'package:flutter/widgets.dart';

/// Moon/crescent icon for the Seerr variant.
class SeerrIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SeerrIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SeerrPainter(color)),
    );
  }
}

class _SeerrPainter extends CustomPainter {
  static final _outerCircle = _parsePath('M48,96C74.51,96,96,74.51,96,48C96,21.49,74.51,0,48,0C21.49,0,0,21.49,0,48C0,74.51,21.49,96,48,96Z');
  static final _crescent = _parsePath(
    'M80,52C80,67.46,67.46,80,52,80C36.54,80,24,67.46,24,52C24,49.13,24.43,46.36,25.23,43.75'
    'C27.43,48.62,32.32,52,38,52C45.73,52,52,45.73,52,38C52,32.32,48.62,27.43,43.76,25.23'
    'C46.36,24.43,49.13,24,52,24C67.46,24,80,36.54,80,52Z',
  );
  static final _topLeftArc = _parsePath(
    'M48,12C28.12,12,12,28.12,12,48C12,50.21,10.21,52,8,52C5.79,52,4,50.21,4,48'
    'C4,23.7,23.7,4,48,4C50.21,4,52,5.79,52,8C52,10.21,50.21,12,48,12Z',
  );
  static final _shadowRing = _parsePath(
    'M80,52C80,67.46,67.46,80,52,80C36.86,80,24.53,67.99,24.02,52.98'
    'C24.01,53.32,24,53.66,24,54C24,70.57,37.43,84,54,84C70.57,84,84,70.57,84,54'
    'C84,37.43,70.57,24,54,24C53.66,24,53.32,24.01,52.98,24.02'
    'C67.99,24.53,80,36.87,80,52Z',
  );

  final Color color;
  _SeerrPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96;
    canvas.save();
    canvas.scale(s, s);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = color.withValues(alpha: 0.15);
    canvas.drawPath(_outerCircle, paint);

    paint.color = color.withValues(alpha: 0.35);
    canvas.drawCircle(const Offset(52, 52), 28, paint);

    paint.color = color.withValues(alpha: 0.55);
    canvas.drawPath(_crescent, paint);

    paint.color = color.withValues(alpha: 0.25);
    canvas.drawPath(_topLeftArc, paint);

    paint.color = color.withValues(alpha: 0.12);
    canvas.drawPath(_shadowRing, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SeerrPainter old) => old.color != color;
}

/// Jellyfish icon for the Jellyseerr variant.
class JellyseerrIcon extends StatelessWidget {
  final double size;
  final Color color;

  const JellyseerrIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _JellyseerrPainter(color)),
    );
  }
}

class _JellyseerrPainter extends CustomPainter {
  static final _bgCircle = _parsePath(
    'M96.1,48C96.1,74.31,74.92,95.71,48.62,96C22.31,96.28,0.68,75.33,0.11,49.03'
    'C-0.45,22.73,20.26,0.87,46.56,0.03C72.86,-0.82,94.93,19.66,96.06,45.95',
  );
  static final _leftTentacle = _parsePath(
    'M42.87,45.59L40.38,45.59C37.05,58.01,35.49,75.95,36.21,89.47'
    'C37,104.35,41.06,118.67,42.41,118.67C43.76,118.67,41.7,109.56,42.62,89.5'
    'C43.24,76.12,47.03,63.55,47.32,45.59L42.87,45.59Z',
  );
  static final _rightTentacle = _parsePath(
    'M64.09,45.86L66.58,45.86C69.91,58.28,71.47,76.22,70.75,89.74'
    'C69.96,104.62,65.9,118.94,64.55,118.94C63.2,118.94,65.26,109.83,64.34,89.77'
    'C63.72,76.39,59.93,63.82,59.64,45.86L64.09,45.86Z',
  );
  static final _leftOuterTentacle = _parsePath(
    'M38.05,70.69L32.99,69.56C32.99,69.56,31.82,76.99,31.38,80.71'
    'C30.67,86.73,29.81,95.05,30.15,101.42C30.52,108.43,32.44,115.18,33.07,115.18'
    'C33.7,115.18,32.73,110.89,33.17,101.43C33.46,95.13,34.5,87.56,35.75,80.71'
    'C36.37,77.33,38.17,70.69,38.17,70.69Z',
  );
  static final _rightInnerTentacle = _parsePath(
    'M59.41,70.16L60.96,70.16C63.04,77.92,63.43,89.12,62.98,97.56'
    'C62.49,106.85,59.95,115.79,59.11,115.79C58.27,115.79,59.56,110.1,58.98,97.58'
    'C58.59,89.23,56.82,81.38,56.63,70.17L59.41,70.16Z',
  );
  static final _leftLongTentacle = _parsePath(
    'M35.18,39.95L29.51,37.93C29.51,37.93,27.43,51.19,26.64,57.85'
    'C25.38,68.6,22.89,83.46,23.5,94.84C24.17,107.37,27.59,119.42,28.72,119.42'
    'C29.85,119.42,28.12,111.75,28.9,94.86C29.42,83.6,32.87,72.92,34.04,57.85'
    'C34.51,51.86,35.41,39.95,35.41,39.95Z',
  );
  static final _centerTentacle = _parsePath(
    'M53.91,45.86L48.8,46.73C48.8,46.73,49.48,56.66,49.48,62.31'
    'C49.48,71.47,49.84,80.73,49.81,90.34C49.78,101.39,51.62,119.89,52.58,119.89'
    'C53.54,119.89,56.64,96.07,57.3,81.83C57.74,72.33,56.33,63.99,56.08,58.31'
    'C55.86,53.25,55.15,45.86,55.15,45.86Z',
  );
  static final _body = _parsePath(
    'M82.09,48.88C82.09,61.78,79.9,62.56,76.31,68.03C73.73,71.95,78.95,74.99,76.86,76.07'
    'C74.36,77.36,75.15,75.02,70.19,73.69C68.04,73.12,63.35,73.75,61.45,74.12'
    'C59.57,74.48,53.84,71.29,52.31,70.88C50.04,70.27,44.47,73.23,41.08,73.23'
    'C37.69,73.23,34.14,70.27,29.62,71.48C24.26,72.92,17.79,76.42,16.81,75.27'
    'C14.93,73.08,20.91,71.41,18.69,67.51C17.29,65.04,12.42,58.53,12.28,51.95'
    'C11.83,30.79,29.35,12.92,48.12,12.92C66.89,12.92,82.07,29.2,82.07,47.41',
  );
  static final _eyeHighlight = _parsePath(
    'M46.95,19.63C36.7,19.63,22.37,30.24,22.37,40.49C22.37,41.63,21.45,42.55,20.31,42.55'
    'C19.17,42.55,18.25,41.63,18.25,40.49C18.25,27.97,34.42,15.51,46.95,15.51'
    'C48.09,15.51,49.01,16.43,49.01,17.57C49.01,18.71,48.09,19.63,46.95,19.63Z',
  );
  static final _eyeArea = _parsePath(
    'M62.12,58.41C61.03,60.19,59.55,61.62,57.8,62.6C57.05,63.01,56.26,63.34,55.44,63.58'
    'C52.99,64.68,50.24,65.27,47.45,65.33C37.92,65.5,30.01,59.41,29.7,51.68'
    'C29.55,47.89,31.81,43.96,33.56,40.93C35.04,38.37,37.59,33.96,40.95,32.2'
    'C47.8,28.6,57.03,32.41,61.65,40.75C62.99,43.17,63.84,45.82,64.13,48.46'
    'C64.34,49.32,64.46,50.2,64.47,51.08C64.5,53.37,63.84,55.63,62.56,57.66'
    'C62.43,57.92,62.29,58.17,62.14,58.41Z',
  );
  static final _iris = _parsePath(
    'M47.07,39.46C53.01,39.46,57.82,44.27,57.82,50.21C57.82,56.15,53.01,60.96,47.07,60.96'
    'C41.13,60.96,36.32,56.15,36.32,50.21C36.32,49.11,36.48,48.05,36.79,47.04'
    'C37.63,48.91,39.51,50.21,41.69,50.21C44.66,50.21,47.06,47.8,47.06,44.84'
    'C47.06,42.66,45.76,40.78,43.89,39.94C44.89,39.63,45.95,39.46,47.06,39.46Z',
  );

  final Color color;
  _JellyseerrPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96;
    canvas.save();
    canvas.scale(s, s);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = color.withValues(alpha: 0.13);
    canvas.drawPath(_bgCircle, paint);

    paint.color = color.withValues(alpha: 0.4);
    canvas.drawPath(_leftTentacle, paint);
    canvas.drawPath(_rightTentacle, paint);

    paint.color = color.withValues(alpha: 0.53);
    canvas.drawPath(_leftOuterTentacle, paint);
    canvas.drawPath(_rightInnerTentacle, paint);

    paint.color = color.withValues(alpha: 0.67);
    canvas.drawPath(_leftLongTentacle, paint);
    canvas.drawPath(_centerTentacle, paint);

    paint.color = color;
    canvas.drawPath(_body, paint);
    canvas.drawPath(_eyeHighlight, paint);

    paint.color = color.withValues(alpha: 0.87);
    canvas.drawPath(_eyeArea, paint);

    paint.color = color;
    canvas.drawPath(_iris, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_JellyseerrPainter old) => old.color != color;
}

Path _parsePath(String d) {
  final path = Path();
  final re = RegExp(r'([MLCZ])|(-?\d+\.?\d*)');
  final matches = re.allMatches(d).toList();
  var i = 0;

  double next() => double.parse(matches[i++].group(0)!);

  while (i < matches.length) {
    final token = matches[i].group(0)!;
    if (token == 'M') {
      i++;
      path.moveTo(next(), next());
    } else if (token == 'L') {
      i++;
      path.lineTo(next(), next());
    } else if (token == 'C') {
      i++;
      path.cubicTo(next(), next(), next(), next(), next(), next());
    } else if (token == 'Z') {
      i++;
      path.close();
    } else {
      path.lineTo(next(), next());
    }
  }
  return path;
}
