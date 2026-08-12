import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'nature_ui.dart';

class InteractiveBookCoverModal extends StatefulWidget {
  final String heroTag;
  final String thumbnailUrl;
  final String title;
  final String author;

  const InteractiveBookCoverModal({
    super.key,
    required this.heroTag,
    required this.thumbnailUrl,
    required this.title,
    required this.author,
  });

  static void show({
    required BuildContext context,
    required String heroTag,
    required String thumbnailUrl,
    required String title,
    required String author,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: OakShelfTheme.forestDeep.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: InteractiveBookCoverModal(
              heroTag: heroTag,
              thumbnailUrl: thumbnailUrl,
              title: title,
              author: author,
            ),
          );
        },
      ),
    );
  }

  @override
  State<InteractiveBookCoverModal> createState() =>
      _InteractiveBookCoverModalState();
}

class _InteractiveBookCoverModalState extends State<InteractiveBookCoverModal>
    with SingleTickerProviderStateMixin {
  // 3D Rotation Angles (Starts perfectly straight and upright)
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  double _dragOffsetY = 0.0;

  late AnimationController _springController;
  late Animation<double> _animX;
  late Animation<double> _animY;
  late Animation<double> _animOffsetY;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _springController.addListener(() {
      setState(() {
        _rotateX = _animX.value;
        _rotateY = _animY.value;
        _dragOffsetY = _animOffsetY.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_springController.isAnimating) {
      _springController.stop();
    }
    setState(() {
      const double sensitivity = 0.005;
      _rotateY += details.delta.dx * sensitivity;
      _rotateX -= details.delta.dy * sensitivity;

      // Clamp rotation for realistic, elegant 3D perspective range
      _rotateX = _rotateX.clamp(-0.45, 0.45);
      _rotateY = _rotateY.clamp(-0.55, 0.55);

      _dragOffsetY += details.delta.dy * 0.15;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragOffsetY > 120.0) {
      Navigator.of(context).pop();
    } else {
      // Smoothly spring back to upright resting position
      _animX = Tween<double>(begin: _rotateX, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
      );
      _animY = Tween<double>(begin: _rotateY, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
      );
      _animOffsetY = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
      );

      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final coverWidth = size.width * 0.68;
    final coverHeight = coverWidth * 1.5;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Tap backdrop to close
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Top Header: Close button & guidance chip
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Drag book to tilt in 3D',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Interactive 3D Cover Card
            Center(
              child: Transform.translate(
                offset: Offset(0, _dragOffsetY),
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Hero(
                    tag: widget.heroTag,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012) // Perspective depth
                        ..rotateX(_rotateX)
                        ..rotateY(_rotateY),
                      child: Container(
                        width: coverWidth,
                        height: coverHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.55),
                              blurRadius: 24,
                              spreadRadius: 1,
                              offset: Offset(
                                -_rotateY * 20,
                                14 + _rotateX * 14,
                              ),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Front Cover Image
                              widget.thumbnailUrl.isNotEmpty
                                  ? Image.network(
                                      widget.thumbnailUrl,
                                      width: coverWidth,
                                      height: coverHeight,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          NatureBookCover(
                                            imageUrl: '',
                                            title: widget.title,
                                            width: coverWidth,
                                            height: coverHeight,
                                            radius: 8,
                                          ),
                                    )
                                  : NatureBookCover(
                                      imageUrl: '',
                                      title: widget.title,
                                      width: coverWidth,
                                      height: coverHeight,
                                      radius: 8,
                                    ),

                              // Spine shadow line (Left edge)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 12,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.4),
                                        Colors.black.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.4, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Dynamic reflection sheen when tilting
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment(
                                          -_rotateY * 2.5,
                                          -_rotateX * 2.5,
                                        ),
                                        end: Alignment(
                                          _rotateY * 2.5,
                                          _rotateX * 2.5,
                                        ),
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(
                                            (_rotateX.abs() + _rotateY.abs())
                                                .clamp(0.0, 0.22),
                                          ),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.35, 0.5, 0.65],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Book Title & Author
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${widget.author}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
