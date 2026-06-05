# Harmony-- 百度贴吧

<div align="center">

![HarmonyOS](https://img.shields.io/badge/HarmonyOS-000000?style=for-the-badge&logo=harmonyos&logoColor=white)
![ArkTS](https://img.shields.io/badge/ArkTS-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)
![Java](https://img.shields.io/badge/Java%2021-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

**一个基于 HarmonyOS 和 Spring Boot 的百度贴吧风格社交平台**

</div>

---

## 项目简介

Harmony-- 是一个仿百度贴吧的社交平台应用，采用 **HarmonyOS (ArkTS)** 作为前端框架，**Spring Boot** 构建后端 RESTful API，**MySQL** 作为数据存储。实现了贴吧浏览、帖子管理、即时通讯、好友系统等核心社交功能。

## 功能特性

### 前端 (HarmonyOS)

- **用户认证** — 手机号注册/登录，本地持久化登录状态
- **贴吧浏览** — 首页展示贴吧列表，显示成员数和帖子数
- **帖子管理** — 发布帖子、查看帖子列表、帖子详情
- **评论系统** — 对帖子进行评论、点赞评论
- **点赞收藏** — 点赞帖子、收藏喜欢的帖子
- **关注系统** — 关注/取关用户，查看关注列表
- **好友系统** — 添加/删除好友，好友关系管理
- **即时通讯** — 与好友一对一聊天，消息已读/未读
- **个人设置** — 修改昵称、上传头像

### 后端 API

| 接口 | 方法 | 功能 |
|------|------|------|
| `/api/user/register` | POST | 用户注册 |
| `/api/user/login` | POST | 用户登录 |
| `/api/post/list` | GET | 获取帖子列表 |
| `/api/post/create` | POST | 创建帖子 |
| `/api/comment/create` | POST | 添加评论 |
| `/api/like/toggle` | POST | 点赞/取消点赞 |
| `/api/favorite/toggle` | POST | 收藏/取消收藏 |
| `/api/follow/toggle` | POST | 关注/取关 |
| `/api/friend/add` | POST | 添加好友 |
| `/api/friend/list` | GET | 好友列表 |
| `/api/message/send` | POST | 发送消息 |
| `/api/message/history` | GET | 聊天历史 |
| `/api/message/conversations` | GET | 会话列表 |
| `/api/bar/list` | GET | 贴吧列表 |

## 技术栈

### 前端
- **语言**: ArkTS
- **框架**: HarmonyOS SDK (API 12+)
- **构建工具**: Hvigor
- **存储**: Preferences API

### 后端
- **语言**: Java 21
- **框架**: Spring Boot 3.5.7
- **数据访问**: Spring Data JPA + Hibernate
- **安全**: Spring Security
- **数据库**: MySQL 8.0+
- **构建**: Maven

## 项目结构

```
Harmony--/
├── AppScope/                    # 应用全局配置
├── entry/                       # 前端主模块
│   ├── src/main/ets/
│   │   ├── common/              # 公共工具
│   │   ├── pages/               # 页面组件
│   │   └── resources/           # 资源文件
│   └── src/mock/                # 模拟数据
├── backend/                     # 后端服务
│   └── user-api/                # Spring Boot 应用
│       ├── src/main/java/
│       │   ├── config/          # 配置类
│       │   ├── controller/      # 控制器
│       │   ├── service/         # 业务逻辑
│       │   ├── repository/      # 数据访问
│       │   └── entity/          # 实体类
│       └── pom.xml
├── MESSAGE_FEATURE.md           # 消息功能文档
└── PR_TEST.md                   # PR 测试记录
```

## 快速开始

### 环境要求
- DevEco Studio NEXT / HarmonyOS API 12+
- JDK 21+
- Maven 3.8+
- MySQL 8.0+

### 启动后端

```bash
cd backend/user-api
# 编辑 application.properties，配置数据库连接
./mvnw spring-boot:run
```

数据库表会自动通过 JPA 的 `ddl-auto=update` 创建。

### 启动前端

1. 使用 **DevEco Studio** 打开项目根目录
2. 在 `entry/src/main/ets/pages/ip.ets` 中配置后端 API 地址
3. 连接真机或启动模拟器运行

## 数据库设计

| 表名 | 说明 |
|------|------|
| `users` | 用户表 |
| `bars` | 贴吧表 |
| `posts` | 帖子表 |
| `comments` | 评论表 |
| `likes` | 点赞记录 |
| `favorites` | 收藏记录 |
| `follows` | 关注关系 |
| `friends` | 好友关系 |
| `messages` | 聊天消息 |

## 后续优化方向

- WebSocket 实现消息实时推送
- 图片消息 / 表情包支持
- 群聊功能
- 好友申请与确认机制
- 在线状态显示
- 消息搜索功能

## 关于

本项目为 HarmonyOS 应用开发课程项目，基于 HarmonyOS 与 Spring Boot 构建的全栈社交应用。
