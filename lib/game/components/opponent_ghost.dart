import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;
import '../../features/multiplayer/domain/multiplayer_models.dart';

class OpponentGhost extends PositionComponent {
  final Stream<MultiplayerPlayer?>? opponentStream;
  final Vector2 Function(int platformIndex)? platformPositionResolver;
  final Vector2 fallbackOrigin;
  final Vector2 fallbackIsoStep;
  final double jumpDuration;
  final double jumpArcHeight;
  final Color ghostColor;

  StreamSubscription<MultiplayerPlayer?>? _subscription;
  MultiplayerPlayer? _latestPlayer;

  int _currentPlatformIndex = 0;
  Vector2 _startPos = Vector2.zero();
  Vector2 _targetPos = Vector2.zero();
  double _jumpElapsed = 1.0;
  double _bobClock = 0.0;
  bool _hasInitializedPosition = false;

  OpponentGhost({
    this.opponentStream,
    this.platformPositionResolver,
    Vector2? fallbackOrigin,
    Vector2? fallbackIsoStep,
    this.jumpDuration = 0.42,
    this.jumpArcHeight = 54.0,
    this.ghostColor = const Color(0xFF00ACC1),
    int priority = 20,
  })  : fallbackOrigin = fallbackOrigin ?? Vector2(180, 420),
        fallbackIsoStep = fallbackIsoStep ?? Vector2(88, -44),
        super(
          size: Vector2(44, 62),
          anchor: Anchor.bottomCenter,
          priority: priority,
        );

  @override
  void onMount() {
    super.onMount();
    _subscription = opponentStream?.listen(applySnapshot);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    _subscription = null;
    super.onRemove();
  }

  void applySnapshot(MultiplayerPlayer? player) {
    _latestPlayer = player;
    if (player == null) return;

    final nextPos = _resolvePlatformPosition(player.platformIndex);
    if (!_hasInitializedPosition) {
      _hasInitializedPosition = true;
      _currentPlatformIndex = player.platformIndex;
      _startPos = nextPos.clone();
      _targetPos = nextPos.clone();
      position.setFrom(nextPos);
      _jumpElapsed = jumpDuration;
      return;
    }

    if (player.platformIndex != _currentPlatformIndex) {
      _currentPlatformIndex = player.platformIndex;
      _startPos = position.clone();
      _targetPos = nextPos.clone();
      _jumpElapsed = 0.0;
    }
  }

  Vector2 _resolvePlatformPosition(int platformIndex) {
    if (platformPositionResolver != null) {
      return platformPositionResolver!(platformIndex);
    }
    return Vector2(
      fallbackOrigin.x + (fallbackIsoStep.x * platformIndex),
      fallbackOrigin.y + (fallbackIsoStep.y * platformIndex),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_latestPlayer == null) return;

    _bobClock += dt;

    if (_jumpElapsed < jumpDuration) {
      _jumpElapsed = math.min(_jumpElapsed + dt, jumpDuration);
      final t = (_jumpElapsed / jumpDuration).clamp(0.0, 1.0);
      final easedT = 1 - math.pow(1 - t, 3).toDouble();
      final x = _startPos.x + (_targetPos.x - _startPos.x) * easedT;
      final baseY = _startPos.y + (_targetPos.y - _startPos.y) * easedT;
      final arcOffset = 4 * jumpArcHeight * t * (1 - t);
      position.setValues(x, baseY - arcOffset);
    } else {
      final bob = math.sin(_bobClock * 3.8) * 3.0;
      position.setValues(_targetPos.x, _targetPos.y + bob);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final player = _latestPlayer;
    if (player == null) return;

    final isRespawning = player.isRespawning;
    final hasFinished = player.hasFinished;
    final baseColor = isRespawning
        ? const Color(0xFFFF7043)
        : (hasFinished ? const Color(0xFF43A047) : ghostColor);
    final pulse = 0.55 + 0.2 * math.sin(_bobClock * 5.0);
    final alpha = player.connected ? (isRespawning ? pulse : 0.68) : 0.28;
    final outlineAlpha = (alpha + 0.15).clamp(0.0, 1.0);

    final centerX = size.x / 2;
    final bottomY = size.y;

    final shadowPaint = Paint()
      ..color = baseColor.withValues(alpha: alpha * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, bottomY - 2),
        width: 30,
        height: 10,
      ),
      shadowPaint,
    );

    if (isRespawning) {
      final ringRadius = 18 + (math.sin(_bobClock * 8) * 4);
      final ringPaint = Paint()
        ..color = const Color(0xFFFF7043).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, bottomY - 4),
          width: ringRadius * 2.1,
          height: ringRadius * 0.9,
        ),
        ringPaint,
      );
    }

    final bodyPaint = Paint()..color = baseColor.withValues(alpha: alpha);
    final outlinePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: outlineAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final bodyPath = Path()
      ..moveTo(centerX - 13, bottomY - 6)
      ..quadraticBezierTo(centerX - 11, bottomY - 34, centerX, bottomY - 38)
      ..quadraticBezierTo(centerX + 11, bottomY - 34, centerX + 13, bottomY - 6)
      ..close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, outlinePaint);

    final headCenter = Offset(centerX, bottomY - 46);
    canvas.drawCircle(headCenter, 10.5, bodyPaint);
    canvas.drawCircle(headCenter, 10.5, outlinePaint);

    final badgeText = isRespawning
        ? '${player.displayName} · Respawning'
        : (hasFinished ? '${player.displayName} ★' : player.displayName);

    final textPainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 130);

    final pillWidth = textPainter.width + 12;
    final pillHeight = textPainter.height + 6;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, bottomY - 66),
        width: pillWidth,
        height: pillHeight,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      pillRect,
      Paint()..color = baseColor.withValues(alpha: 0.85),
    );
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        (bottomY - 66) - textPainter.height / 2,
      ),
    );
  }
}