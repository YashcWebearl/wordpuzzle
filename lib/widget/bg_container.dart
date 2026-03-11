import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/bg.png',
          fit: BoxFit.cover,
        ),
        child,
      ],
    );
  }
}
