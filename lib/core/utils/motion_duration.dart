// Motion duration utilities for MoneyWise — respects accessibility reduce-motion setting.
import 'package:flutter/material.dart';

Duration motionDuration(BuildContext context, Duration d) =>
    MediaQuery.of(context).disableAnimations ? Duration.zero : d;

const Duration microMotion = Duration(milliseconds: 100);
const Duration shortMotion = Duration(milliseconds: 200);
const Duration mediumMotion = Duration(milliseconds: 350);
