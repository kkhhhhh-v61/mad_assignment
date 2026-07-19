import 'package:flutter/material.dart';

// ==================== App Constants ====================

const appName = 'DoorDish';
const appLogo = 'assets/images/logo.webp';
const currencyPrefix = 'RM';

String formatPrice(double price) =>
    '$currencyPrefix ${price.toStringAsFixed(2)}';

// ==================== Color Palette ====================

const brandColor = Color.fromARGB(255, 255, 160, 122);
const scaffoldBgColor = Color(0xF8FFFFFF);

const textPrimary = Color(0xDD000000);
const textSecondary = Color(0xFF757575);
const textHint = Color(0xFF9E9E9E);

const surfaceLight = Color(0xFFF5F5F5);
const surfaceMuted = Color(0xFFEEEEEE);
const borderLight = Color(0xFFE0E0E0);

const starColor = Color(0xFFFFCA28);
const infoColor = Color(0xFF2196F3);
const dangerColor = Color(0xFFEF5350);

// ==================== Typography ====================

const fontCaption = 12.0;
const fontDetail = 13.0;
const fontBody = 14.0;
const fontBodyLarge = 15.0;
const fontSubtitle = 16.0;
const fontTitle = 18.0;
const fontHeadline = 20.0;
const fontDisplay = 22.0;

// ==================== Spacing ====================

const spacingXs = 4.0;
const spacingSm = 8.0;
const spacingMd = 12.0;
const spacingLg = 16.0;
const spacingXl = 20.0;
const spacing2xl = 24.0;
const spacing3xl = 32.0;

// ==================== Border Radius ====================

const radiusSm = 10.0;
const radiusMd = 12.0;
const radiusLg = 15.0;
const radiusXl = 20.0;
const radiusFull = 25.0;

// ==================== Shadows ====================

const shadowSm = BoxShadow(
  color: Color.fromARGB(15, 0, 0, 0),
  blurRadius: 5,
  offset: Offset(0, 2),
);

const shadowMd = BoxShadow(
  color: Color.fromARGB(20, 0, 0, 0),
  blurRadius: 8,
  spreadRadius: 1,
  offset: Offset(0, 3),
);

const shadowLg = BoxShadow(
  color: Color.fromARGB(40, 0, 0, 0),
  blurRadius: 10,
  spreadRadius: 1,
  offset: Offset(0, 4),
);

const shadowNavBar = BoxShadow(
  color: Color.fromARGB(64, 0, 0, 0),
  blurRadius: 15,
  spreadRadius: 1,
  offset: Offset(0, -2),
);

const shadowBottomBar = BoxShadow(
  color: Color.fromARGB(15, 0, 0, 0),
  blurRadius: 15,
  offset: Offset(0, -5),
);
