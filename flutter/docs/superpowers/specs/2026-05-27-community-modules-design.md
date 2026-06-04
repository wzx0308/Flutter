# 社区模块功能设计文档

## 概述

为"安隅"社交应用添加社区模块功能，包括首页频道展示、频道内容浏览、用户主页、关注和聊天功能。

## 核心设计决策

### 频道系统：基于标签的映射

官方频道 = 预定义的标签映射。帖子的 `tags[]` 字段已存在，后端 `/tags/:tag/posts` 端点已可用。无需修改后端数据库结构。

- 官方频道在前端硬编码，每个频道对应一个标签
- 用户发帖时选择标签，帖子自动归入对应频道
- 用户自定义标签可生成社区频道（在发现页展示）

## 官方频道定义

| 频道名 | 标签 | 图标 | 颜色 |
|--------|------|------|------|
| 生活 | 生活 | Icons.home | #4CAF50 |
| 技术 | 技术 | Icons.code | #2196F3 |
| 音乐 | 音乐 | Icons.music_note | #9C27B0 |
| 摄影 | 摄影 | Icons.camera_alt | #FF9800 |
| 旅行 | 旅行 | Icons.flight | #00BCD4 |
| 美食 | 美食 | Icons.restaurant | #E91E63 |
| 运动 | 运动 | Icons.fitness_center | #FF5722 |
| 阅读 | 阅读 | Icons.book | #795548 |

## 页面设计

### 1. 首页（Tab 0）

**当前状态**：Tab 0 显示 FeedPage（帖子时间线）
**目标状态**：Tab 0 显示官方频道网格

**布局**：
- 顶部：标题"社区" + 搜索按钮
- 主体：2列网格，每个频道卡片显示图标、名称、简介、最新帖子封面图
- 底部：保持现有 BottomNavigationBar

**交互**：
- 点击频道卡片 → 进入频道详情页
- 点击搜索 → 进入搜索页

### 2. 频道详情页

**路径**：`/channel/:tag`

**布局**：
- AppBar：频道名称 + 频道图标
- 主体：帖子列表（复用 PostCard 组件）
- 下拉刷新 + 上拉加载更多

**数据流**：
```
GET /posts?tag={tag}&page=1&pageSize=20
```

### 3. 发现页（Tab 1）

**当前状态**：已有 DiscoverPage
**目标状态**：保持现有功能，混合展示所有频道内容

无需修改，现有实现已满足需求。

### 4. 用户主页

**路径**：`/user/detail/:id`

**布局**：
- AppBar：用户昵称 + 更多操作按钮
- 头部区域：
  - 头像（圆形，可点击放大）
  - 昵称
  - 个人简介
  - 统计数据：粉丝数 | 关注数 | 帖子数
  - 操作按钮：关注/取消关注 + 发消息（互相关注后显示）
- 主体：用户动态列表（该用户发布的帖子）

**数据流**：
```
GET /users/:id → 用户信息
GET /posts?authorId=:id&page=1 → 用户动态
GET /users/:id/followers → 粉丝列表（获取数量）
GET /users/:id/following → 关注列表（获取数量）
GET /users/me → 当前用户信息（用于检测互相关注）
```

**互相关注检测逻辑**：
1. 获取当前用户的关注列表
2. 检查目标用户是否在列表中
3. 同时检查目标用户是否关注了当前用户
4. 只有双向关注才显示"发消息"按钮

### 5. 帖子详情页

**修改**：
- 作者头像/昵称可点击 → 跳转用户主页
- 评论中用户头像/昵称可点击 → 跳转用户主页

### 6. 聊天功能

**触发条件**：互相关注后才能发消息

**流程**：
1. 在用户主页点击"发消息"
2. 调用 `POST /conversations` 创建或获取会话
3. 跳转到聊天详情页

## 数据模型

### ChannelModel（前端静态）

```dart
class ChannelModel {
  final String tag;        // 标签名（如"音乐"）
  final String name;       // 频道名称
  final String description; // 频道简介
  final IconData icon;     // 图标
  final Color color;       // 主题色
  final String? coverImage; // 封面图（可选）
}
```

## API 端点映射

| 功能 | 端点 | 方法 |
|------|------|------|
| 频道帖子列表 | `/posts?tag={tag}` | GET |
| 用户信息 | `/users/:id` | GET |
| 用户动态 | `/posts?authorId=:id` | GET |
| 关注用户 | `/users/:id/follow` | POST |
| 取消关注 | `/users/:id/follow` | DELETE |
| 粉丝列表 | `/users/:id/followers` | GET |
| 关注列表 | `/users/:id/following` | GET |
| 创建会话 | `/conversations` | POST |
| 发现推荐 | `/discover/recommended` | GET |

## 文件变更清单

### 新建文件

| 文件路径 | 说明 |
|----------|------|
| `lib/data/models/channel_model.dart` | 频道数据模型 |
| `lib/data/providers/follow_provider.dart` | 已存在，无需修改 |
| `lib/modules/channel/channel_page.dart` | 频道详情页 |
| `lib/modules/channel/channel_controller.dart` | 频道页控制器 |
| `lib/modules/profile/user_detail_page.dart` | 用户主页 |
| `lib/modules/profile/user_detail_controller.dart` | 用户主页控制器 |
| `lib/modules/home/widgets/channel_grid.dart` | 频道网格组件 |
| `lib/modules/home/widgets/channel_card.dart` | 频道卡片组件 |

### 修改文件

| 文件路径 | 修改内容 |
|----------|----------|
| `lib/modules/home/home_page.dart` | Tab 0 改为频道网格 |
| `lib/modules/post/post_detail_page.dart` | 作者头像可点击跳转 |
| `lib/modules/feed/feed_page.dart` | 评论者头像可点击跳转 |
| `lib/modules/feed/widgets/post_card.dart` | 作者头像可点击跳转 |
| `lib/app/routes/app_routes.dart` | 添加频道和用户主页路由 |
| `lib/app/routes/app_pages.dart` | 添加路由映射和绑定 |
| `lib/core/locales/zh_cn.dart` | 添加频道相关 i18n |
| `lib/core/locales/en_us.dart` | 添加频道相关 i18n |
| `lib/core/locales/ja_jp.dart` | 添加频道相关 i18n |

## i18n 键值

```dart
// 中文
'community': '社区',
'channel': '频道',
'channel_posts': '频道动态',
'fans_count': '粉丝',
'following_count': '关注',
'posts_count': '帖子',
'follow': '关注',
'unfollow': '取消关注',
'mutual_follow': '互相关注',
'send_message': '发消息',
'user_posts': '动态',
'no_posts_in_channel': '该频道暂无内容',

// 英文
'community': 'Community',
'channel': 'Channel',
'channel_posts': 'Channel Posts',
'fans_count': 'Fans',
'following_count': 'Following',
'posts_count': 'Posts',
'follow': 'Follow',
'unfollow': 'Unfollow',
'mutual_follow': 'Mutual',
'send_message': 'Message',
'user_posts': 'Posts',
'no_posts_in_channel': 'No posts in this channel',

// 日文
'community': 'コミュニティ',
'channel': 'チャンネル',
'channel_posts': 'チャンネル投稿',
'fans_count': 'フォロワー',
'following_count': 'フォロー中',
'posts_count': '投稿',
'follow': 'フォロー',
'unfollow': 'フォロー解除',
'mutual_follow': '相互フォロー',
'send_message': 'メッセージ',
'user_posts': '投稿',
'no_posts_in_channel': 'このチャンネルにはまだ投稿がありません',
```

## 错误处理

- 网络请求失败 → 显示重试按钮
- 用户不存在 → 显示错误提示并返回
- 关注/取关失败 → Snackbar 提示
- 聊天创建失败 → Snackbar 提示
- 帖子加载失败 → 显示空状态 + 重试

## 测试要点

1. 首页频道网格正确显示 8 个官方频道
2. 点击频道进入频道详情页，帖子列表正确加载
3. 频道详情页下拉刷新和上拉加载更多正常
4. 用户主页正确显示用户信息和动态
5. 关注/取消关注功能正常
6. 互相关注后"发消息"按钮出现
7. 点击"发消息"正确创建会话并跳转
8. 帖子详情页作者头像点击跳转正确
9. 评论中用户头像点击跳转正确
10. 深色模式下所有页面样式正确
11. 国际化文本正确显示
