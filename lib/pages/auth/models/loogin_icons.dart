import 'package:flutter/material.dart';

class LooginIcons {
  final String imge;
  final VoidCallback ontap;

  LooginIcons({required this.imge, required this.ontap});
}

List<LooginIcons> icons = [
  LooginIcons(imge: 'assets/icons/apple.png', ontap: () {}),
  LooginIcons(imge: 'assets/icons/facebook.png', ontap: () {}),
  LooginIcons(imge: 'assets/icons/google.png', ontap: () {}),
];
