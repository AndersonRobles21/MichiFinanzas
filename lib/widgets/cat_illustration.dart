import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

abstract final class CatAssets {
  static const inicio = 'lib/assets/image/gatoInicio_alpha.png';
  static const ahorros = 'lib/assets/image/gatoAhorros_alpha.png';
  static const ingresos = 'lib/assets/image/gatoIngresos_alpha.png';
  static const gastos = 'lib/assets/image/gatoGastos_alpha.png';
  static const estadisticas = 'lib/assets/image/gatoEstadisticas_alpha.png';
  static const exitoso = 'lib/assets/image/gatoExitoso_alpha.png';
  static const vacio = 'lib/assets/image/gatoVacio_alpha.png';
  static const icono = 'lib/assets/image/gatoIcono_alpha.png';
}

class AnimatedCat extends StatefulWidget {
  const AnimatedCat({
    required this.asset,
    required this.label,
    required this.width,
    required this.height,
    this.floating = false,
    this.bounceTrigger = 0,
    super.key,
  });

  final String asset;
  final String label;
  final double width;
  final double height;
  final bool floating;
  final int bounceTrigger;

  @override
  State<AnimatedCat> createState() => _AnimatedCatState();
}

class _AnimatedCatState extends State<AnimatedCat>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _bounceController;
  late final TweenSequence<double> _bounceTween;
  int _lastBounceTrigger = 0;

  bool get _motionAllowed =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false) &&
      TickerMode.valuesOf(context).enabled;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _bounceTween = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -10.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -10.0,
          end: 2.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 2.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
    _playNewBounce();
  }

  @override
  void didUpdateWidget(covariant AnimatedCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimations();
    _playNewBounce();
  }

  void _syncAnimations() {
    if (!_motionAllowed) {
      _floatController.stop();
      _bounceController.stop();
      return;
    }
    if (widget.floating && !_floatController.isAnimating) {
      _floatController.repeat(reverse: true, count: 2);
    } else if (!widget.floating && _floatController.isAnimating) {
      _floatController.stop();
      _floatController.value = 0;
    }
  }

  void _playNewBounce() {
    if (widget.bounceTrigger == _lastBounceTrigger) return;
    _lastBounceTrigger = widget.bounceTrigger;
    if (_motionAllowed) _bounceController.forward(from: 0);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _bounceController]),
      builder: (context, child) {
        final floatOffset = widget.floating
            ? Tween<double>(
                begin: -3.5,
                end: 3.5,
              ).transform(Curves.easeInOut.transform(_floatController.value))
            : 0.0;
        final bounceOffset = _bounceTween.transform(_bounceController.value);
        return Transform.translate(
          offset: Offset(0, floatOffset + bounceOffset),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                widget.asset,
                fit: BoxFit.contain,
                semanticLabel: widget.label,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets_rounded, color: AppColors.primary),
              ),
            ),
          ),
        );
      },
    );
  }
}

void showCatMessage(
  BuildContext context,
  String message, {
  bool isSuccess = false,
  String? successAsset,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isSuccess) ...[
              AnimatedCat(
                key: UniqueKey(),
                asset: successAsset ?? CatAssets.exitoso,
                label: isSuccess ? 'Gato celebrando' : 'Gato',
                width: 44,
                height: 38,
                bounceTrigger: 1,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
