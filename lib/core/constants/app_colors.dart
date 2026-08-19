import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette (Primary Slate & Cyber Emerald)
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color darkSidebar = Color(0xFF0B1120); // Slate 950
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkCardHover = Color(0xFF283548);
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkInputBg = Color(0xFF131D31);
  
  // Accents & Branding
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  static const Color primaryGlow = Color(0x3310B981);

  static const Color accentCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color accentIndigo = Color(0xFF6366F1); // Indigo 500
  static const Color accentAmber = Color(0xFFF59E0B); // Amber 500
  static const Color accentRose = Color(0xFFF43F5E); // Rose 500
  static const Color accentPurple = Color(0xFFA855F7); // Purple 500

  // Status Colors
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusOffline = Color(0xFF64748B);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusConnecting = Color(0xFFF59E0B);

  // Text Colors (Dark)
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSidebar = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Terminal Themes
  static const Color terminalBg = Color(0xFF0D1117);
  static const Color terminalHeader = Color(0xFF161B22);
  static const Color terminalBorder = Color(0xFF30363D);

  // Preset Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFF84CC16), // Lime
  ];
}
