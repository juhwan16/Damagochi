import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pet_model.dart';

class PetWidget extends StatelessWidget {
  final PetState state;
  final double size;
  final String? accessoryAsset;
  final Color? characterColor;

  const PetWidget({
    super.key,
    required this.state,
    this.size = 210,
    this.accessoryAsset,
    this.characterColor,
  });

  String get _svgAsset {
    switch (state) {
      case PetState.happy: return 'assets/svg/pet_happy.svg';
      case PetState.normal: return 'assets/svg/pet_normal.svg';
      case PetState.tired: return 'assets/svg/pet_tired.svg';
      case PetState.sick: return 'assets/svg/pet_sick.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget character = SvgPicture.asset(_svgAsset, width: size, height: size);

    if (characterColor != null) {
      character = ColorFiltered(
        colorFilter: ColorFilter.mode(characterColor!, BlendMode.hue),
        child: character,
      );
    }

    if (accessoryAsset != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          character,
          SvgPicture.asset(accessoryAsset!, width: size, height: size),
        ],
      );
    }

    return character;
  }
}
