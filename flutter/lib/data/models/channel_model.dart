import 'package:flutter/material.dart';

class ChannelModel {
  final String tag;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const ChannelModel({
    required this.tag,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<ChannelModel> officialChannels = [
    ChannelModel(
      tag: '生活',
      name: '生活',
      description: '分享日常点滴',
      icon: Icons.home,
      color: Color(0xFF4CAF50),
    ),
    ChannelModel(
      tag: '技术',
      name: '技术',
      description: '技术交流讨论',
      icon: Icons.code,
      color: Color(0xFF2196F3),
    ),
    ChannelModel(
      tag: '音乐',
      name: '音乐',
      description: '音乐分享推荐',
      icon: Icons.music_note,
      color: Color(0xFF9C27B0),
    ),
    ChannelModel(
      tag: '摄影',
      name: '摄影',
      description: '摄影作品展示',
      icon: Icons.camera_alt,
      color: Color(0xFFFF9800),
    ),
    ChannelModel(
      tag: '旅行',
      name: '旅行',
      description: '旅行见闻分享',
      icon: Icons.flight,
      color: Color(0xFF00BCD4),
    ),
    ChannelModel(
      tag: '美食',
      name: '美食',
      description: '美食制作与推荐',
      icon: Icons.restaurant,
      color: Color(0xFFE91E63),
    ),
    ChannelModel(
      tag: '运动',
      name: '运动',
      description: '运动健身打卡',
      icon: Icons.fitness_center,
      color: Color(0xFFFF5722),
    ),
    ChannelModel(
      tag: '阅读',
      name: '阅读',
      description: '读书笔记分享',
      icon: Icons.book,
      color: Color(0xFF795548),
    ),
  ];
}
