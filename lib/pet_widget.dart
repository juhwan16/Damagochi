import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pet_model.dart';

class PetWidget extends StatelessWidget {
  final PetState state;
  final double size;
  final String? accessoryAsset;
  final Color? characterColor;
  final String petPrefix;

  const PetWidget({
    super.key,
    required this.state,
    this.size = 210,
    this.accessoryAsset,
    this.characterColor,
    this.petPrefix = 'pet',
  });

  String get _svgAsset {
    switch (state) {
      case PetState.happy: return 'assets/svg/${petPrefix}_happy.svg';
      case PetState.normal: return 'assets/svg/${petPrefix}_normal.svg';
      case PetState.tired: return 'assets/svg/${petPrefix}_tired.svg';
      case PetState.sick: return 'assets/svg/${petPrefix}_sick.svg';
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
