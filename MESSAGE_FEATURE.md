# 消息功能使用说明

## 功能概述

消息功能已成功实现，包含以下核心特性：

### 1. 好友管理
- **添加好友**：在帖子列表页面，点击任何用户的头像即可添加为好友
- **好友列表**：查看所有已添加的好友
- **删除好友**：可以删除不需要的好友关系

### 2. 消息系统
- **消息列表**：查看所有会话，显示最后一条消息和未读数
- **私聊对话**：与好友进行一对一聊天
- **未读消息**：自动统计和显示未读消息数量
- **消息已读**：打开对话后自动标记消息为已读

## 使用流程

### 添加好友
1. 进入任意贴吧的帖子列表
2. 点击帖子发布者的头像
3. 在弹出的对话框中确认添加好友
4. 系统会显示"添加好友成功"提示

### 查看消息
1. 在帖子列表页面右上角点击 💬 图标
2. 进入消息列表页面
3. 查看所有好友的会话记录

### 发送消息
1. 在消息列表中点击任意好友
2. 进入聊天对话页面
3. 在底部输入框输入消息内容
4. 点击"发送"按钮或按回车键发送

## 技术实现

### 后端API

#### 好友管理API
- `POST /api/friend/add` - 添加好友
- `GET /api/friend/list?userId={userId}` - 获取好友列表
- `DELETE /api/friend/delete?userId={userId}&friendId={friendId}` - 删除好友
- `GET /api/friend/check?userId={userId}&friendId={friendId}` - 检查是否是好友

#### 消息管理API
- `POST /api/message/send` - 发送消息
- `GET /api/message/history?userId={userId}&friendId={friendId}` - 获取聊天历史
- `GET /api/message/conversations?userId={userId}` - 获取会话列表
- `POST /api/message/read` - 标记消息已读
- `GET /api/message/unread-count?userId={userId}` - 获取未读消息数

### 数据库表结构

#### friends 表
- `id` - 主键
- `user_id` - 用户ID
- `friend_id` - 好友ID
- `friend_name` - 好友名称
- `friend_avatar` - 好友头像URL
- `create_time` - 添加时间
- `status` - 好友状态（PENDING/ACCEPTED/REJECTED）

#### messages 表
- `id` - 主键
- `sender_id` - 发送者ID
- `receiver_id` - 接收者ID
- `content` - 消息内容
- `create_time` - 发送时间
- `is_read` - 是否已读
- `type` - 消息类型（TEXT/IMAGE/SYSTEM）

### 前端页面

#### MessageListPage.ets - 消息列表页面
- 显示所有会话
- 显示最后一条消息
- 显示未读消息数
- 时间格式化显示

#### ChatPage.ets - 聊天对话页面
- 聊天消息展示
- 发送/接收消息
- 自动滚动到最新消息
- 消息已读标记

#### PostListPage.ets - 帖子列表页面（已更新）
- 添加好友功能
- 跳转到消息列表

## 界面设计参考

消息列表页面参考了现代化的聊天应用设计：
- 用户头像圆形展示
- 未读消息红色角标
- 最后消息时间智能显示
- 列表项分隔线
- 空状态提示

聊天对话页面采用经典的即时通讯设计：
- 发送的消息在右侧（蓝色气泡）
- 接收的消息在左侧（白色气泡）
- 时间戳智能显示（间隔5分钟显示一次）
- 底部固定输入框
- 自动滚动到最新消息

## 注意事项

1. **用户识别**：当前使用用户名作为用户ID进行好友关系管理
2. **数据持久化**：消息和好友关系都保存在数据库中
3. **实时更新**：需要手动刷新页面获取最新消息（可后续添加WebSocket实现实时推送）
4. **头像显示**：如果没有设置头像，会显示用户名首字母

## 后续优化建议

1. **实时通信**：集成WebSocket实现消息实时推送
2. **图片消息**：支持发送图片和表情
3. **消息撤回**：支持撤回已发送的消息
4. **群聊功能**：支持创建群组聊天
5. **消息搜索**：添加消息搜索功能
6. **好友申请**：改进好友添加流程，支持申请和确认机制
7. **在线状态**：显示好友在线/离线状态
8. **消息通知**：添加系统通知提醒

## 文件清单

### 后端文件（Java）
- `Friend.java` - 好友实体
- `Message.java` - 消息实体
- `FriendRepository.java` - 好友数据访问层
- `MessageRepository.java` - 消息数据访问层
- `FriendService.java` - 好友业务逻辑层
- `MessageService.java` - 消息业务逻辑层
- `FriendController.java` - 好友控制器
- `MessageController.java` - 消息控制器

### 前端文件（ArkTS）
- `MessageListPage.ets` - 消息列表页面
- `ChatPage.ets` - 聊天对话页面
- `PostListPage.ets` - 帖子列表页面（已更新）
