import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pet_model.dart';

class PetWidget extends StatelessWidget {
  final PetState state;

  const PetWidget({super.key, required this.state});

  String get _svgAsset {
    switch (state) {
      case PetState.happy:
        return 'assets/svg/pet_happy.svg';
      case PetState.normal:
        return 'assets/svg/pet_normal.svg';
      case PetState.tired:
        return 'assets/svg/pet_tired.svg';
      case PetState.sick:
        return 'assets/svg/pet_sick.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _svgAsset,
      width: 210,
      height: 210,
    );
  }
}
