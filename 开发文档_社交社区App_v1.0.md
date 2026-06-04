# 社交社区 App 开发文档

> 技术栈：Flutter + GetX | NestJS + PostgreSQL | Socket.IO | Docker

---

## 一、项目概述

### 1.1 项目定位

移动端社交社区应用，支持用户发布图文帖子和长文专栏、即时通讯、关注互动、LBS 地理位置等功能，同时提供 Web 端管理后台。

### 1.2 目标用户

面向 < 1 万用户的初期 MVP 阶段，后续可横向扩展。

### 1.3 目标平台

| 平端 | 说明 |
|------|------|
| iOS | Flutter 构建 |
| Android | Flutter 构建 |
| Web | Flutter Web 构建（管理后台独立） |
| Admin | Web 管理后台（Vue3 / React） |

---

## 二、技术架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────┐
│                     Client Layer                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  iOS App  │  │ Android  │  │  Web (Flutter Web)   │  │
│  └─────┬─────┘  └─────┬────┘  └──────────┬───────────┘  │
│        │              │                   │              │
│        └──────────┬───┘───────────────────┘              │
│                   │                                      │
│            ┌──────▼──────┐                               │
│            │  REST API   │                               │
│            │  (HTTPS)    │                               │
│            └──────┬──────┘                               │
│                   │                                      │
│            ┌──────▼──────┐                               │
│            │  WebSocket  │                               │
│            │ (Socket.IO) │                               │
│            └──────┬──────┘                               │
├───────────────────┼──────────────────────────────────────┤
│              Server Layer (NestJS)                       │
│  ┌────────────────▼─────────────────────────────────┐   │
│  │              API Gateway / Load Balancer          │   │
│  └────────────────┬─────────────────────────────────┘   │
│                   │                                      │
│  ┌────────────────▼─────────────────────────────────┐   │
│  │              NestJS Application                   │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐   │   │
│  │  │ Auth │ │ User │ │ Feed │ │ Chat │ │ LBS  │   │   │
│  │  │Module│ │Module│ │Module│ │Module│ │Module│   │   │
│  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘   │   │
│  └────────────────┬─────────────────────────────────┘   │
│                   │                                      │
├───────────────────┼──────────────────────────────────────┤
│              Data Layer                                  │
│  ┌──────────┐ ┌───▼───┐ ┌──────────┐ ┌──────────────┐  │
│  │PostgreSQL│ │ Redis │ │ OSS/COS  │ │ ElasticSearch │  │
│  │ (主数据)  │ │(缓存)  │ │ (文件)   │ │  (搜索)       │  │
│  └──────────┘ └───────┘ └──────────┘ └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 2.2 技术选型明细

| 层级 | 技术 | 版本建议 | 说明 |
|------|------|---------|------|
| **前端框架** | Flutter | 3.x+ | 跨平台 UI |
| **状态管理** | GetX | ^4.6+ | 状态/路由/依赖注入一体 |
| **网络请求** | Dio | ^5.x | HTTP 客户端 |
| **本地存储** | GetStorage / Hive | - | 轻量键值存储 |
| **IM 通信** | socket_io_client | ^2.x | Socket.IO 客户端 |
| **后端框架** | NestJS | ^10.x | TypeScript 企业级框架 |
| **ORM** | TypeORM / Prisma | - | 数据库 ORM |
| **数据库** | PostgreSQL | 15+ | 主数据库 |
| **缓存** | Redis | 7.x | 会话/缓存/消息队列 |
| **文件存储** | 阿里云 OSS / 腾讯 COS | - | 对象存储 |
| **搜索引擎** | Elasticsearch | 8.x | 全文搜索（可选，初期可用 PG 全文搜索） |
| **容器化** | Docker + Docker Compose | - | 部署方案 |
| **管理后台** | Vue3 + Element Plus 或 React + Ant Design | - | Web 管理端 |
| **API 文档** | Swagger (OpenAPI) | - | 自动生成 |

---

## 三、功能模块详细设计

### 3.1 用户认证模块 (Auth)

#### 3.1.1 登录方式

| 方式 | 流程 | 说明 |
|------|------|------|
| 手机验证码 | 输入手机号 → 发送短信 → 输入验证码 → 登录/注册 | 主登录方式 |
| 邮箱密码 | 输入邮箱+密码 → 校验 → 登录 | 辅助方式 |
| 账号密码 | 用户名+密码 → 校验 → 登录 | 辅助方式 |
| 微信 OAuth | 跳转微信授权 → 获取 code → 换取 token → 登录/注册 | 第三方 |
| QQ OAuth | 跳转QQ授权 → 获取 code → 换取 token → 登录/注册 | 第三方 |

#### 3.1.2 认证流程

```
Client                    NestJS                     PostgreSQL
  │                          │                            │
  │── POST /auth/login ─────►│                            │
  │                          │── 查询用户 ────────────────►│
  │                          │◄─ 返回用户数据 ─────────────│
  │                          │                            │
  │                          │── 验证密码/验证码           │
  │                          │── 生成 JWT (Access+Refresh) │
  │                          │                            │
  │◄── 返回 tokens ──────────│                            │
  │                          │                            │
  │── GET /api/xxx (Bearer) ─►│                            │
  │                          │── 验证 JWT                 │
  │                          │── 注入 user 到 request     │
  │◄── 返回数据 ──────────────│                            │
```

#### 3.1.3 Token 策略

- **Access Token**: 有效期 2 小时，存内存/GetStorage
- **Refresh Token**: 有效期 7 天，存 HttpOnly Cookie 或安全存储
- **Token 刷新**: Access Token 过期时用 Refresh Token 自动续期

#### 3.1.4 API 接口

```
POST   /auth/register          # 注册
POST   /auth/login             # 登录（通用）
POST   /auth/login/sms         # 短信验证码登录
POST   /auth/login/wechat      # 微信登录
POST   /auth/login/qq          # QQ登录
POST   /auth/refresh           # 刷新Token
POST   /auth/logout            # 登出
POST   /auth/send-sms          # 发送短信验证码
POST   /auth/reset-password    # 重置密码
```

---

### 3.2 用户模块 (User)

#### 3.2.1 用户资料

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| username | varchar(32) | 用户名（唯一） |
| nickname | varchar(64) | 昵称 |
| avatar | varchar(256) | 头像 URL |
| bio | text | 个人简介 |
| phone | varchar(20) | 手机号（加密存储） |
| email | varchar(128) | 邮箱 |
| gender | enum | 性别 |
| birthday | date | 生日 |
| location | varchar(128) | 所在地 |
| latitude | decimal | 纬度 |
| longitude | decimal | 经度 |
| status | enum | normal/banned/deleted |
| role | enum | user/moderator/admin |
| created_at | timestamp | 注册时间 |
| updated_at | timestamp | 更新时间 |

#### 3.2.2 API 接口

```
GET    /users/me                    # 获取当前用户信息
PATCH  /users/me                    # 更新当前用户信息
GET    /users/:id                   # 获取指定用户信息
GET    /users/:id/posts             # 获取用户发布的帖子
POST   /users/me/avatar             # 上传头像
PATCH  /users/me/location           # 更新地理位置
```

---

### 3.3 用户关系模块 (Social)

#### 3.3.1 关注关系表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| follower_id | UUID | 关注者 |
| following_id | UUID | 被关注者 |
| created_at | timestamp | 关注时间 |

- 唯一约束: (follower_id, following_id)
- 自动维护 follower_count 和 following_count 冗余字段

#### 3.3.2 API 接口

```
POST   /users/:id/follow            # 关注用户
DELETE /users/:id/follow            # 取消关注
GET    /users/:id/followers         # 获取粉丝列表
GET    /users/:id/following         # 获取关注列表
GET    /users/me/feed               # 获取关注的人的动态流
```

---

### 3.4 内容/帖子模块 (Post)

#### 3.4.1 内容类型

**图文帖子 (post)**
- 文字内容（最多 2000 字）
- 图片（最多 9 张）
- 话题标签 (#tag)
- 地理位置（可选）

**长文专栏 (article)**
- 标题
- 富文本内容（Markdown）
- 封面图
- 话题标签
- 分类

#### 3.4.2 数据库设计

**posts 表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| author_id | UUID | 作者 (FK → users) |
| type | enum | post / article |
| content | text | 文字内容 |
| title | varchar(256) | 标题（长文专用） |
| cover_image | varchar(256) | 封面图（长文专用） |
| images | jsonb | 图片URL数组 |
| tags | jsonb | 话题标签数组 |
| location_name | varchar(128) | 位置名称 |
| latitude | decimal | 纬度 |
| longitude | decimal | 经度 |
| like_count | int | 点赞数（冗余） |
| comment_count | int | 评论数（冗余） |
| share_count | int | 分享数（冗余） |
| status | enum | published/hidden/deleted/reviewing |
| created_at | timestamp | 发布时间 |
| updated_at | timestamp | 更新时间 |

**likes 表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| user_id | UUID | 点赞用户 |
| post_id | UUID | 点赞帖子 |
| created_at | timestamp | 点赞时间 |

唯一约束: (user_id, post_id)

**comments 表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| post_id | UUID | 所属帖子 |
| author_id | UUID | 评论者 |
| parent_id | UUID | 父评论（支持嵌套回复） |
| content | text | 评论内容 |
| like_count | int | 点赞数 |
| status | enum | published/hidden/deleted |
| created_at | timestamp | 评论时间 |

#### 3.4.3 Feed 流设计

采用 **推拉结合** 模型：

- **发布时**: 将帖子 ID 推送到所有粉丝的 Feed 缓存（Redis Sorted Set）
- **读取时**: 从 Redis 获取 Feed 列表，再批量查询帖子详情
- **大V用户**: 粉丝数超过阈值时不推送，由粉丝拉取时合并

```
Redis Key Pattern:
  feed:{user_id}  →  Sorted Set (post_id, timestamp)
```

#### 3.4.4 API 接口

```
POST   /posts                       # 发布帖子/长文
GET    /posts                       # 获取帖子列表（广场/推荐）
GET    /posts/:id                   # 获取帖子详情
PATCH  /posts/:id                   # 编辑帖子
DELETE /posts/:id                   # 删除帖子
POST   /posts/:id/like              # 点赞
DELETE /posts/:id/like              # 取消点赞
GET    /posts/:id/comments          # 获取评论列表
POST   /posts/:id/comments          # 发表评论
DELETE /comments/:id                # 删除评论
GET    /posts/search?q=xxx          # 搜索帖子
GET    /posts/nearby?lat=&lng=&r=   # 附近动态
```

---

### 3.5 即时通讯模块 (Chat)

#### 3.5.1 技术方案：Socket.IO

```
Client (Flutter)              NestJS Server                 PostgreSQL
     │                              │                            │
     │── socket.connect ───────────►│                            │
     │   (携带 JWT token)           │── 验证 token               │
     │◄── connect:success ──────────│                            │
     │                              │── 更新用户在线状态 (Redis)   │
     │                              │                            │
     │── chat:send ────────────────►│                            │
     │   {to, content, type}        │── 存储消息 ────────────────►│
     │                              │── 转发给目标用户            │
     │◄── chat:receive ─────────────│── (如对方在线)              │
     │                              │── 推送通知 (如离线)          │
```

#### 3.5.2 数据库设计

**conversations 表（会话）**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| type | enum | private / group |
| name | varchar(128) | 群名称（群聊专用） |
| avatar | varchar(256) | 群头像（群聊专用） |
| created_at | timestamp | 创建时间 |
| updated_at | timestamp | 最后消息时间 |

**conversation_members 表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| conversation_id | UUID | 会话 ID |
| user_id | UUID | 用户 ID |
| role | enum | member / admin / owner |
| unread_count | int | 未读消息数 |
| last_read_at | timestamp | 最后已读时间 |
| joined_at | timestamp | 加入时间 |

**messages 表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| conversation_id | UUID | 会话 ID |
| sender_id | UUID | 发送者 |
| type | enum | text / image / file / system |
| content | text | 消息内容 |
| media_url | varchar(256) | 媒体文件 URL |
| status | enum | sent / delivered / read |
| created_at | timestamp | 发送时间 |

#### 3.5.3 Socket.IO 事件

```typescript
// 客户端 → 服务端
'chat:send'           // 发送消息
'chat:typing'         // 正在输入
'chat:read'           // 标记已读
'user:online'         // 上线通知

// 服务端 → 客户端
'chat:receive'        // 接收消息
'chat:delivered'      // 消息已送达
'chat:read:ack'       // 已读回执
'user:status'         // 用户在线状态变更
```

#### 3.5.4 REST API

```
GET    /conversations                 # 会话列表
POST   /conversations                 # 创建会话
GET    /conversations/:id             # 会话详情
GET    /conversations/:id/messages    # 历史消息（分页）
DELETE /conversations/:id             # 删除会话
```

---

### 3.6 搜索与发现模块 (Search)

#### 3.6.1 搜索范围

- 搜索用户（用户名、昵称）
- 搜索帖子（内容、标签）
- 搜索话题 (#tag)

#### 3.6.2 实现方案

初期使用 **PostgreSQL 全文搜索**（`tsvector` + `tsquery`），后期数据量增长后迁移至 Elasticsearch。

```sql
-- PostgreSQL 全文搜索示例
ALTER TABLE posts ADD COLUMN search_vector tsvector;
CREATE INDEX idx_posts_search ON posts USING gin(search_vector);
```

#### 3.6.3 API 接口

```
GET    /search?q=xxx&type=post|user|tag    # 综合搜索
GET    /search/trending                     # 热门搜索词
GET    /discover/recommended                # 推荐内容
GET    /discover/nearby                     # 附近的人/动态
GET    /tags/:tag/posts                     # 话题下的帖子
```

---

### 3.7 LBS 地理位置模块

#### 3.7.1 功能

- 发布动态时附带位置信息
- 查看附近的人和动态
- 基于距离排序

#### 3.7.2 实现方案

使用 **PostGIS** 扩展（PostgreSQL 地理空间查询）：

```sql
-- 安装 PostGIS
CREATE EXTENSION postgis;

-- 查询附近 N 公里内的帖子
SELECT * FROM posts
WHERE ST_DWithin(
  geography(ST_MakePoint(longitude, latitude)),
  geography(ST_MakePoint($lng, $lat)),
  $radius_meters
)
ORDER BY created_at DESC;
```

#### 3.7.3 API 接口

```
GET    /posts/nearby?lat=&lng=&radius=    # 附近动态
GET    /users/nearby?lat=&lng=&radius=    # 附近的人
```

---

### 3.8 内容审核与安全模块

#### 3.8.1 审核策略

| 阶段 | 策略 | 说明 |
|------|------|------|
| 发布前 | 敏感词过滤 | 本地敏感词库匹配 |
| 发布后 | 异步审核 | 接入第三方内容审核 API（阿里云/腾讯云） |
| 用户举报 | 人工审核 | 管理后台审核处理 |

#### 3.8.2 举报机制

**reports 表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| reporter_id | UUID | 举报者 |
| target_type | enum | post / comment / user |
| target_id | UUID | 被举报对象 ID |
| reason | enum | spam / abuse / illegal / other |
| description | text | 举报描述 |
| status | enum | pending / reviewed / resolved |
| created_at | timestamp | 举报时间 |

#### 3.8.3 API 接口

```
POST   /reports                       # 提交举报
```

---

## 四、数据库 ER 关系图

```
┌──────────┐     ┌───────────────┐     ┌──────────┐
│  users   │────<│   follows     │>────│  users   │
│          │     └───────────────┘     │          │
│          │                            │          │
│          │────<┌───────────────┐     │          │
│          │     │    posts      │     │          │
│          │     └───────┬───────┘     │          │
│          │             │              │          │
│          │────<┌───────▼───────┐     │          │
│          │     │   comments    │     │          │
│          │     └───────────────┘     │          │
│          │                            │          │
│          │────<┌───────────────┐     │          │
│          │     │    likes      │>────│  posts   │
│          │     └───────────────┘     │          │
│          │                            │          │
│          │────<┌───────────────┐     │          │
│          │     │    reports    │     │          │
│          │     └───────────────┘     │          │
│          │                            │          │
│          │────<┌───────────────┐     │          │
│          │     │conv_members   │>────│convs     │
│          │     └───────┬───────┘     │          │
│          │             │              │          │
│          │────<┌───────▼───────┐     │          │
│          │     │   messages    │     │          │
│          │     └───────────────┘     │          │
└──────────┘
```

---

## 五、项目目录结构

### 5.1 Flutter 前端

```
lib/
├── main.dart                    # 入口
├── app/
│   ├── routes/                  # 路由定义
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   ├── bindings/                # GetX Bindings
│   │   └── initial_binding.dart
│   └── theme/                   # 主题样式
│       ├── app_theme.dart
│       └── app_colors.dart
├── core/
│   ├── network/                 # 网络层
│   │   ├── api_client.dart      # Dio 封装
│   │   ├── api_interceptor.dart # Token 拦截器
│   │   └── api_endpoints.dart   # 接口地址
│   ├── storage/                 # 本地存储
│   │   └── storage_service.dart
│   ├── utils/                   # 工具类
│   │   ├── validators.dart
│   │   └── helpers.dart
│   └── constants/               # 常量
│       └── app_constants.dart
├── data/
│   ├── models/                  # 数据模型
│   │   ├── user_model.dart
│   │   ├── post_model.dart
│   │   ├── message_model.dart
│   │   └── conversation_model.dart
│   ├── providers/               # API Provider
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── post_provider.dart
│   │   └── chat_provider.dart
│   └── repositories/            # Repository
│       ├── auth_repository.dart
│       ├── user_repository.dart
│       ├── post_repository.dart
│       └── chat_repository.dart
├── modules/
│   ├── splash/                  # 启动页
│   │   ├── splash_page.dart
│   │   └── splash_controller.dart
│   ├── auth/                    # 认证模块
│   │   ├── login_page.dart
│   │   ├── login_controller.dart
│   │   ├── register_page.dart
│   │   └── register_controller.dart
│   ├── home/                    # 首页/Feed
│   │   ├── home_page.dart
│   │   ├── home_controller.dart
│   │   └── widgets/
│   │       ├── post_card.dart
│   │       └── feed_list.dart
│   ├── discover/                # 发现/搜索
│   │   ├── discover_page.dart
│   │   └── discover_controller.dart
│   ├── chat/                    # 聊天
│   │   ├── chat_list_page.dart
│   │   ├── chat_detail_page.dart
│   │   └── chat_controller.dart
│   ├── post/                    # 发帖
│   │   ├── create_post_page.dart
│   │   └── create_post_controller.dart
│   ├── profile/                 # 个人中心
│   │   ├── profile_page.dart
│   │   ├── profile_controller.dart
│   │   ├── edit_profile_page.dart
│   │   └── user_detail_page.dart
│   └── common/                  # 通用组件
│       ├── widgets/
│       │   ├── custom_app_bar.dart
│       │   ├── avatar_widget.dart
│       │   ├── image_viewer.dart
│       │   └── loading_widget.dart
│       └── mixins/
│           └── pagination_mixin.dart
└── generated/                   # 自动生成
    ├── locales/
    └── assets/
```

### 5.2 NestJS 后端

```
src/
├── main.ts                      # 入口
├── app.module.ts                # 根模块
├── common/                      # 公共模块
│   ├── decorators/
│   │   ├── current-user.decorator.ts
│   │   └── roles.decorator.ts
│   ├── guards/
│   │   ├── jwt-auth.guard.ts
│   │   └── roles.guard.ts
│   ├── interceptors/
│   │   └── transform.interceptor.ts
│   ├── filters/
│   │   └── http-exception.filter.ts
│   └── pipes/
│       └── validation.pipe.ts
├── config/                      # 配置
│   ├── database.config.ts
│   ├── jwt.config.ts
│   ├── redis.config.ts
│   └── oss.config.ts
├── modules/
│   ├── auth/                    # 认证模块
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── strategies/
│   │   │   ├── jwt.strategy.ts
│   │   │   └── local.strategy.ts
│   │   └── dto/
│   │       ├── login.dto.ts
│   │       └── register.dto.ts
│   ├── user/                    # 用户模块
│   │   ├── user.module.ts
│   │   ├── user.controller.ts
│   │   ├── user.service.ts
│   │   ├── entities/
│   │   │   └── user.entity.ts
│   │   └── dto/
│   │       ├── create-user.dto.ts
│   │       └── update-user.dto.ts
│   ├── post/                    # 帖子模块
│   │   ├── post.module.ts
│   │   ├── post.controller.ts
│   │   ├── post.service.ts
│   │   ├── entities/
│   │   │   ├── post.entity.ts
│   │   │   ├── like.entity.ts
│   │   │   └── comment.entity.ts
│   │   └── dto/
│   ├── follow/                  # 关注模块
│   │   ├── follow.module.ts
│   │   ├── follow.controller.ts
│   │   └── follow.service.ts
│   ├── chat/                    # 聊天模块
│   │   ├── chat.module.ts
│   │   ├── chat.gateway.ts      # Socket.IO Gateway
│   │   ├── chat.service.ts
│   │   ├── entities/
│   │   │   ├── conversation.entity.ts
│   │   │   ├── conversation-member.entity.ts
│   │   │   └── message.entity.ts
│   │   └── dto/
│   ├── feed/                    # Feed 流模块
│   │   ├── feed.module.ts
│   │   ├── feed.service.ts
│   │   └── feed.controller.ts
│   ├── search/                  # 搜索模块
│   │   ├── search.module.ts
│   │   ├── search.controller.ts
│   │   └── search.service.ts
│   ├── report/                  # 举报模块
│   │   ├── report.module.ts
│   │   ├── report.controller.ts
│   │   └── report.service.ts
│   ├── upload/                  # 文件上传模块
│   │   ├── upload.module.ts
│   │   ├── upload.controller.ts
│   │   └── upload.service.ts
│   └── notification/            # 通知推送模块
│       ├── notification.module.ts
│       └── notification.service.ts
└── database/                    # 数据库
    ├── migrations/
    └── seeds/
```

---

## 六、认证与安全设计

### 6.1 JWT 双 Token 机制

```
Access Token:  短期有效 (2h)，用于 API 请求认证
Refresh Token: 长期有效 (7d)，用于刷新 Access Token
```

### 6.2 安全策略

| 策略 | 说明 |
|------|------|
| HTTPS | 全链路 HTTPS 加密 |
| 密码加密 | bcrypt 哈希存储 |
| 手机号加密 | AES 加密存储 |
| 限流 | NestJS @nestjs/throttle 接口限流 |
| CORS | 白名单域名控制 |
| SQL 注入 | ORM 参数化查询 |
| XSS | 输入过滤 + 输出编码 |
| 敏感词 | 发布前敏感词库过滤 |
| RBAC | 基于角色的权限控制 (user/moderator/admin) |

---

## 七、国际化 (i18n) 方案

### 7.1 Flutter 前端

使用 `get` 包内置的国际化支持：

```dart
// lib/core/locales/
//   zh_CN.dart
//   en_US.dart

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh_CN': zhCN,
    'en_US': enUS,
  };
}

// 使用
Text('home.title'.tr)
```

### 7.2 支持语言

| 语言代号 | 语言 | 优先级 |
|---------|------|--------|
| zh_CN | 简体中文 | P0（首版） |
| en_US | 英语 | P1（首版） |

---

## 八、Docker 部署方案

### 8.1 docker-compose.yml 结构

```yaml
version: '3.8'
services:
  # NestJS 后端
  api:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/app
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=xxx
    depends_on:
      - db
      - redis

  # PostgreSQL 数据库
  db:
    image: postgres:15-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    ports:
      - "5432:5432"

  # Redis 缓存
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  # 管理后台 (可选)
  admin:
    build: ./admin
    ports:
      - "8080:80"

volumes:
  pgdata:
```

### 8.2 部署流程

```bash
# 1. 克隆代码
git clone <repo-url>

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 填入实际配置

# 3. 启动服务
docker-compose up -d

# 4. 运行数据库迁移
docker-compose exec api npm run migration:run

# 5. 查看日志
docker-compose logs -f api
```

---

## 九、开发里程碑规划

| 阶段 | 内容 | 预计周期 |
|------|------|---------|
| **M1 - 基础架构** | 项目初始化、Docker 环境、数据库设计、用户认证 | 2 周 |
| **M2 - 核心功能** | 帖子发布/浏览、点赞评论、关注体系、Feed 流 | 3 周 |
| **M3 - 社交功能** | 即时通讯 (Socket.IO)、搜索发现、通知推送 | 2 周 |
| **M4 - 高级功能** | LBS 地理位置、内容审核、举报机制 | 2 周 |
| **M5 - 管理后台** | Web 管理后台（用户管理、内容管理、数据统计） | 2 周 |
| **M6 - 优化收尾** | 性能优化、多语言完善、测试、部署上线 | 1 周 |

---

## 十、开发规范

### 10.1 Git 分支策略

```
main           ← 生产分支，只接受 merge
├── develop    ← 开发主分支
│   ├── feature/xxx   ← 功能分支
│   ├── bugfix/xxx    ← 修复分支
│   └── hotfix/xxx    ← 紧急修复
```

### 10.2 Commit 规范

```
<type>(<scope>): <description>

type: feat | fix | docs | style | refactor | test | chore
scope: auth | user | post | chat | feed | search | admin
```

### 10.3 API 规范

- RESTful 风格
- 统一响应格式:

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

- 分页格式:

```json
{
  "code": 0,
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "pageSize": 20
  }
}
```

### 10.4 命名规范

| 项目 | 规范 | 示例 |
|------|------|------|
| Dart 文件 | snake_case | `user_model.dart` |
| Dart 类 | PascalCase | `UserModel` |
| Dart 变量 | camelCase | `userName` |
| 数据库表 | snake_case | `user_posts` |
| 数据库字段 | snake_case | `created_at` |
| API 路径 | kebab-case | `/api/user-posts` |
| NestJS 文件 | dot.case | `user.controller.ts` |

---

## 十一、第三方服务依赖

| 服务 | 用途 | 备注 |
|------|------|------|
| 阿里云 OSS / 腾讯 COS | 文件存储 | 图片、头像、文件 |
| 阿里云短信 / 腾讯云短信 | 短信验证码 | 手机登录 |
| 微信开放平台 | 微信 OAuth | 第三方登录 |
| QQ 互联 | QQ OAuth | 第三方登录 |
| 阿里云内容安全 | 内容审核 | 图文审核 |
| 极光推送 / 个推 | 消息推送 | APP 推送通知 |
| 高德地图 / 腾讯地图 | 地理位置 | LBS 定位服务 |

---

## 十二、关键依赖包清单

### Flutter (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6                    # 状态管理/路由/依赖注入
  dio: ^5.4.0                    # HTTP 客户端
  get_storage: ^2.1.1            # 本地存储
  socket_io_client: ^2.0.3+1    # Socket.IO 客户端
  cached_network_image: ^3.3.0   # 图片缓存
  image_picker: ^1.0.4           # 图片选择
  flutter_easyloading: ^3.0.5    # Loading 组件
  pull_to_refresh: ^2.0.0        # 下拉刷新
  flutter_localizations:
    sdk: flutter                 # 国际化
  intl: any                      # 国际化工具
```

### NestJS (package.json)

```json
{
  "dependencies": {
    "@nestjs/core": "^10.0.0",
    "@nestjs/common": "^10.0.0",
    "@nestjs/typeorm": "^10.0.0",
    "@nestjs/jwt": "^10.0.0",
    "@nestjs/passport": "^10.0.0",
    "@nestjs/platform-socket.io": "^10.0.0",
    "@nestjs/swagger": "^7.0.0",
    "@nestjs/throttler": "^5.0.0",
    "typeorm": "^0.3.17",
    "pg": "^8.11.0",
    "ioredis": "^5.3.0",
    "passport-jwt": "^4.0.1",
    "bcrypt": "^5.1.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "ali-oss": "^6.17.0"
  }
}
```

---

*文档版本：v1.0 | 生成日期：2026-05-22*
