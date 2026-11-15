import 'package:flutter/widgets.dart';

const kDesktopBreakpoint = 700.0;

bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
