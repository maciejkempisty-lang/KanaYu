import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'design.dart';

class Resident extends StatefulWidget {
  const Resident({super.key});
  @override
  State<Resident> createState() => _ResidentState();
}

class _ResidentState extends State<Resident> {
  late final loader = rive.FileLoader.fromAsset(
    'assets/rive/yuu_kigi.riv',
    riveFactory: rive.Factory.rive,
  );
  @override
  void dispose() {
    loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: rive.RiveWidgetBuilder(
      fileLoader: loader,
      builder: (context, state) {
        if (state is rive.RiveLoaded) {
          state.controller.active = !MediaQuery.disableAnimationsOf(context);
          return rive.RiveWidget(
            controller: state.controller,
            fit: rive.Fit.contain,
          );
        }
        if (state is rive.RiveFailed) {
          return Icon(Icons.spa_rounded, size: 56, color: forest);
        }
        return Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    ),
  );
}
