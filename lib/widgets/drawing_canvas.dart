import 'package:flutter/material.dart';
import 'package:simple_text_projector_ui/services/websocket_service.dart';

class DrawingCanvas extends StatefulWidget {
  final double width;
  final double height;
  final double scaleFactor;
  final Size remoteScreenSize;

  const DrawingCanvas({
    required this.width,
    required this.height,
    required this.scaleFactor,
    required this.remoteScreenSize,
    super.key,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Offset? dragStart;
  Offset? dragCurrent;
  Rect? drawnRect;
  WebSocketService webSocketService = WebSocketService();

  final GlobalKey _canvasKey = GlobalKey();

  Offset _toLocal(Offset global) {
    final box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return box.globalToLocal(global);
  }

  void _onPanStart(DragStartDetails details) {
    final local = _clampToCanvas(_toLocal(details.globalPosition));
    setState(() {
      dragStart = local;
      dragCurrent = local;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final local = _clampToCanvas(_toLocal(details.globalPosition));
    setState(() {
      dragCurrent = local;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (dragStart != null && dragCurrent != null) {
      setState(() {
        drawnRect = Rect.fromPoints(dragStart!, dragCurrent!);
        print("Rectangle drawn at ${drawnRect!.topLeft} with size ${drawnRect!.size}");
        dragStart = null;
        dragCurrent = null;
      });

      final realBottomLeft = drawnRect!.bottomLeft / widget.scaleFactor;
      final realSize = drawnRect!.size / widget.scaleFactor;

      final realWidth = realSize.width;
      final realHeight = realSize.height;

      final realX = realBottomLeft.dx;
      final realY = widget.remoteScreenSize.height - realBottomLeft.dy;

      print("Real rectangle:");
      print("- Top left: $realX, $realY");
      print("- Size: $realWidth × $realHeight");

      Map<String, dynamic> sizeCommand = {
        "set": "box_size",
        "box_size": {
          "index": 0,
          "width": realWidth,
          "height": realHeight
        }
      };

      Map<String, dynamic> positionCommand = {
        "set": "box_position",
        "box_position": {
          "index": 0,
          "x": realX,
          "y": realY
        }
      };

      webSocketService.sendCommand(positionCommand, "box_position");
      webSocketService.sendCommand(sizeCommand, "box_size");
    }
  }

  void _onTapDown(TapDownDetails details) {
    final local = _toLocal(details.globalPosition);
    if (drawnRect != null && drawnRect!.contains(local)) {
      print("Rectangle tapped!");
    }
  }

  Offset _clampToCanvas(Offset pos) {
    double x = pos.dx.clamp(0.0, widget.width);
    double y = pos.dy.clamp(0.0, widget.height);
    return Offset(x, y);
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapDown: _onTapDown,
      child: Container(
        key: _canvasKey,
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: CustomPaint(
          painter: _RectanglePainter(
            dragStart: dragStart,
            dragCurrent: dragCurrent,
            finalRect: drawnRect,
          ),
        ),
      ),
    );
  }
}

class _RectanglePainter extends CustomPainter {
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Rect? finalRect;

  _RectanglePainter({
    this.dragStart,
    this.dragCurrent,
    this.finalRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (dragStart != null && dragCurrent != null) {
      final liveRect = Rect.fromPoints(dragStart!, dragCurrent!);
      canvas.drawRect(liveRect, paint);
    }

    if (finalRect != null) {
      canvas.drawRect(finalRect!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
