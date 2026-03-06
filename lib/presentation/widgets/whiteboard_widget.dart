import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/innovation_provider.dart';

class WhiteboardWidget extends StatefulWidget {
  final String chatId;
  final String messageId;
  final List<dynamic> initialStrokes;

  const WhiteboardWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.initialStrokes,
  });

  @override
  State<WhiteboardWidget> createState() => _WhiteboardWidgetState();
}

class _WhiteboardWidgetState extends State<WhiteboardWidget> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _parseStrokes(widget.initialStrokes);
  }

  @override
  void didUpdateWidget(WhiteboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStrokes != oldWidget.initialStrokes) {
      _parseStrokes(widget.initialStrokes);
    }
  }

  void _parseStrokes(List<dynamic> raw) {
    _strokes = raw.map((s) {
      final points = s['points'] as List<dynamic>;
      return points.map((p) => Offset(p['x'], p['y'])).toList();
    }).toList();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final newStroke = List<Offset>.from(_currentStroke);
    setState(() {
      _strokes.add(newStroke);
      _currentStroke = [];
    });

    final innovation = context.read<InnovationProvider>();
    final rawStrokes = _strokes.map((s) => {
      'points': s.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    }).toList();

    innovation.updateWhiteboardStrokes(
      chatId: widget.chatId,
      messageId: widget.messageId,
      strokes: rawStrokes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 8,
            left: 8,
            child: Row(
              children: [
                Icon(Icons.brush, size: 14, color: Colors.blueGrey),
                SizedBox(width: 4),
                Text("Shared Whiteboard", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: WhiteboardPainter(strokes: _strokes, currentStroke: _currentStroke),
              size: Size.infinite,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete_sweep, size: 20, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _strokes = [];
                });
                context.read<InnovationProvider>().updateWhiteboardStrokes(
                  chatId: widget.chatId,
                  messageId: widget.messageId,
                  strokes: [],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  WhiteboardPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    if (currentStroke.isNotEmpty) {
      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) => true;
}
