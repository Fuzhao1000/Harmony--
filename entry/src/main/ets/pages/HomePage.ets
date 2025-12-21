import router from '@ohos.router';
import file from '@ohos.file.picker';
import * as picker from '@ohos.file.picker';
import photoAccessHelper from '@ohos.file.photoAccessHelper';

import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';
import {loadUserInfo} from '../pages/LoginPage';
import { saveUserName} from '../pages/LoginPage';
import image from '@ohos.multimedia.image';
import http from '@ohos.net.http';
import util from '@ohos.util';
import preferences from '@ohos.data.preferences'
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs';
import { prompt, Prompt } from '@kit.ArkUI';
import { data } from '@kit.TelephonyKit';

import { BASE_URL } from '../pages/ip';

interface PostItem {
  id:string
  baname:string
  user: string
  userId?: number
  createTime: number
  content: string
  image: string
  likes: number
  comments: number
  liked?: boolean;
  favorited?: boolean;
  isFollowing?: boolean; // 是否已关注该帖子作者
}

interface ForumItem {
  baname: string      // 吧名
  members: number     // 成员数量
  posts: number       // 帖子数量
  icon: Resource      // 吧头像（图片资源）
}

interface UserItem{
  username:string,
  tx:Resource,
  gz:number,
  fans:number,
  phone:number
}

interface UpdateNameResponse {
  success: boolean;
  message?: string;
}

interface UserInfo {
  id: number;
  name: string;
  avatar?: string;
}

interface UserInfoResponse {
  success: boolean;
  name?: string;
  user?: UserInfo;
  message?: string;
}

interface PostListResponse {
  success: boolean;
  posts: PostItem[];
}

interface FavoriteResponse {
  success: boolean;
  favoritePostIds: number[];
}

interface LikeResponse{
  success: boolean // 是否成功
  liked: boolean;   // 当前状态：true=已点赞，false=未点赞
  likes: number
}

interface LikeListResponse {
  success: boolean;
  likedPostIds: number[];
}

interface FollowResponse {
  success: boolean;
  isFollowing: boolean;
  message: string;
  followerFollowingCount?: number;
  followingFollowerCount?: number;
}

interface FollowStatsResponse {
  success: boolean;
  followingCount: number;
  followerCount: number;
}

interface FollowCheckResponse {
  success: boolean;
  isFollowing: boolean;
}

interface CommentItem {
  id: number
  postId: string
  userId: number
  content: string
  createTime: number
  isMine?: boolean
  userName?: string
  avatar?: string
  likes?: number
  liked?: boolean
}

interface CommentListResponse {
  success: boolean
  comments: CommentItem[]
  message?: string
}

interface CommentLikeResponse {
  success: boolean
  liked: boolean
  likes: number
}

interface SendCommentResponse {
  success: boolean
  comment?: CommentItem
  message?: string
}

interface BaseResponse {
  success: boolean
  msg?: string
}

interface BarStat {
  baname: string
  postCount: number
  memberCount: number
}

interface BarStatsResponse {
  success: boolean
  stats: BarStat[]
}

interface UpdatePostData {
  id: string
  content: string
  baname: string
}

interface UpdatePostResponse {
  success: boolean
  post?: PostItem
  message?: string
}

interface DeletePostResponse {
  success: boolean
  message?: string
}

interface MessageUser {
  id: number
  name: string
  avatar?: string
  lastMessage?: string
  lastTime?: number
  unreadCount?: number
}

interface FollowListResponse {
  success: boolean;
  users: MessageUser[];
  message?: string;
}

interface UnreadCountResponse {
  success: boolean;
  count: number;
}

interface LatestMessageItem {
  content: string;
  createTime: number;
}

interface LatestMessageResponse {
  success: boolean;
  message?: LatestMessageItem;
}

interface ConversationItem {
  userId: string | number;  // 后端可能返回String
  lastMessage: string;
  lastMessageTime: number;
  unreadCount: number;
}

interface ConversationsResponse {
  success: boolean;
  conversations: ConversationItem[];
  message?: string;
}

interface PhotoResponse{
  message: string;
  success: boolean;
  url:string;
}

@Entry
@Component
struct HomePage {
  @State currentTab: string = 'home';
  @State isEditing: boolean = false;
  @State userName:string = '';
  @State headImage:string ='app.media.head';
  @State likesClicked: boolean = false;
  @State content: string = ''
  @State selectedBa: string = ''
  @State selectedForum: string = ''
  @State selectedImage: string = ''
  @StorageLink('posts') posts: PostItem[] = []
  @State loading: boolean = false;
  @State publishing: boolean = false
  @State searchKeyword: string = ''  // 搜索关键词
  @State filteredPosts: PostItem[] = []  // 搜索过滤后的帖子
  @State isSearching: boolean = false  // 是否处于搜索状态
  @State favoritePosts: PostItem[] = [];
  @State showShare: boolean = false
  @State forums: ForumItem[] = [
    {
      baname: "浙江农林大学吧",
      members: 0,
      posts: 1,
      icon: $r('app.media.zjnldx')
    },
    {
      baname: "明日方舟吧",
      members: 0,
      posts: 1,
      icon: $r('app.media.mrfz')
    },
    {
      baname: "bilibili吧",
      members: 0,
      posts: 0,
      icon: $r('app.media.bilibili')
    },
  {
  baname: "动漫吧",
  members: 0,
  posts: 0,
  icon: $r('app.media.dm')
  },
    {
      baname: "弱智吧",
      members: 0,
      posts: 0,
      icon: $r('app.media.rz')
    }
  ]
  @State showCommentPanel: boolean = false
  @State currentPost: PostItem | null = null
  @State currentPostId: number = 0   // 当前正在评论的帖子
  @State comments: CommentItem[] = []
  @State commentInput: string = ''
  private commentInputController: TextInputController = new TextInputController()

  @State userId: number = 0
  @State followingCount: number = 0  // 关注数
  @State followerCount: number = 0   // 粉丝数
  @State favoriteCount: number = 0   // 收藏数
  
  // 编辑帖子相关状态
  @State showEditDialog: boolean = false
  @State editingPost: PostItem | null = null
  @State editContent: string = ''
  @State editBaname: string = ''
  
  // 消息相关状态
  @State messageUsers: MessageUser[] = []  // 消息列表（关注的好友）

  // 搜索帖子方法
  searchPosts() {
    if (this.searchKeyword.trim() === '') {
      this.isSearching = false;
      this.filteredPosts = [];
      return;
    }
    
    this.isSearching = true;
    const keyword = this.searchKeyword.toLowerCase().trim();
    
    // 过滤包含关键词的帖子（匹配内容或用户名）
    this.filteredPosts = this.posts.filter(post => 
      post.content.toLowerCase().includes(keyword) ||
      (post.user && post.user.toLowerCase().includes(keyword)) ||
      post.baname.toLowerCase().includes(keyword)
    );
  }
  
  // 清除搜索
  clearSearch() {
    this.searchKeyword = '';
    this.isSearching = false;
    this.filteredPosts = [];
  }

  @Builder
  CommentItemView(item: CommentItem) {
    Column() {
      Column({ space: 10 }) {
        // 用户信息行
        Row({ space: 10 }) {
          // 头像
          Image(item.avatar ?? $r('app.media.head'))
            .width(40)
            .height(40)
            .borderRadius(20)

          Column({ space: 4 }) {
            // 用户名
            Text(item.userName || '匿名用户')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            // 评论时间
            Text(this.formatTime(item.createTime))
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 删除按钮
          if (item.isMine) {
            Text('删除')
              .fontColor('#ff6b6b')
              .fontSize(13)
              .onClick(() => this.deleteComment(item))
          }
        }
        .width('100%')

        // 评论内容
        Text(item.content)
          .fontSize(15)
          .lineHeight(22)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 50 })

        // 点赞
        Row({ space: 6 }) {
          Text(item.liked ? '❤' : '♡')
            .fontSize(16)
            .fontColor(item.liked ? '#ff6b6b' : '#999')
          Text((item.likes || 0).toString())
            .fontSize(13)
            .fontColor(item.liked ? '#ff6b6b' : '#999')
        }
        .padding({ left: 50 })
        .onClick(() => this.toggleCommentLike(item))
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 16, right: 16 })

      // 分隔线
      Divider()
        .strokeWidth(1)
        .color('#e8e8e8')
    }
    .width('100%')
    .backgroundColor(Color.White)
  }

  async  ChangeImage(
  photoUri: string,
  context: Context
): Promise<string> {
    let tempFilePath: string = '';
    let srcFile: fs.File | null = null;

    try {
      // 1. 创建临时文件路径
      const cacheDir = context.cacheDir;
      tempFilePath = `${cacheDir}/temp_upload_${Date.now()}.jpg`;

      // 2. 直接打开相册返回的 URI（系统已授权临时读权限！）
      srcFile = fs.openSync(photoUri, fs.OpenMode.READ_ONLY);

      // 3. 创建目标文件（用 TRUNCATE 清空覆盖）
      const destFile = fs.openSync(tempFilePath,
        fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY
      );

      try {
        // 4. 复制文件内容（大文件安全）
        const bufferSize = 64 * 1024;
        const buffer = new ArrayBuffer(bufferSize);
        let readLen = 0;

        while ((readLen = await fs.read(srcFile.fd, buffer)) > 0) {
          const data = new Uint8Array(buffer, 0, readLen);
          await fs.write(destFile.fd, data.buffer);
        }
      } finally {
        fs.closeSync(destFile);
      }

      // 5. 读取临时文件用于上传
      const uploadFile = await fs.open(tempFilePath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(tempFilePath);
      const fileBuffer = new ArrayBuffer(stat.size);
      await fs.read(uploadFile.fd, fileBuffer);
      await fs.close(uploadFile);

      // 6. 构造 multipart body（保持你的逻辑）
      const boundary = '----WebKitFormBoundary' + Date.now();
      const encoder = new util.TextEncoder();

      const fileName = photoUri.substring(photoUri.lastIndexOf('/') + 1) || 'image.jpg';
      const mimeType = fileName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

      const header = encoder.encode(
        `--${boundary}\r\n` +
          `Content-Disposition: form-data; name="file"; filename="${fileName}"\r\n` +
          `Content-Type: ${mimeType}\r\n\r\n`
      );

      const footer = encoder.encode(`\r\n--${boundary}--\r\n`);

      const body = new Uint8Array(header.byteLength + fileBuffer.byteLength + footer.byteLength);
      body.set(new Uint8Array(header), 0);
      body.set(new Uint8Array(fileBuffer), header.byteLength);
      body.set(new Uint8Array(footer), header.byteLength + fileBuffer.byteLength);

      // 7. 上传
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(`${BASE_URL}/upload/image`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': `multipart/form-data; boundary=${boundary}` },
        extraData: body.buffer
      });
      httpRequest.destroy();

      if (response.responseCode !== 200) {
        throw new Error(`上传失败：${response.responseCode}`);
      }

      const result = JSON.parse(response.result as string) as PhotoResponse;
      if (result.success && result.url) {
        return result.url;
      }
      throw new Error('上传失败');

    } finally {
      if (srcFile) fs.closeSync(srcFile);
      if (tempFilePath) await fs.unlink(tempFilePath).catch(() => {});
    }
}
  async pickImageFromGallery() {
    try {

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      // 打开相册，等待用户选择
      const selectResult = await photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, // 仅选图片
        maxSelectNumber: 1
      });

      if (selectResult && selectResult.photoUris.length > 0) {
        // 获取选中图片的 URI
        const uri = selectResult.photoUris[0];
        console.log("选择的图片地址：" + uri);

        const newImageUrl = await this.ChangeImage(uri, getContext(this));
        console.log("复制的图片地址：" + newImageUrl);

        //this.headImage = `${BASE_URL}${newImageUrl}`;
        this.headImage =`http://10.205.218.246:8080/images/test.png`;
          console.log("pingjie：" + this.headImage);

      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`选图失败：${error.code} - ${error.message}`);
    }
  }

  async pickImageForPost() {
    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      // 打开相册，等待用户选择
      const selectResult = await photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, // 仅选图片
        maxSelectNumber: 1
      });

      if (selectResult && selectResult.photoUris.length > 0) {
        // 获取选中图片的 URI
        const uri = selectResult.photoUris[0];
        console.log("选择的帖子图片地址：" + uri);

        // 更新帖子图片显示
        this.selectedImage = `http://10.205.218.246:8080/images/test.png`;
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`选图失败：${error.code} - ${error.message}`);
    }
  }




  private async loadUserNameFromDB() {
    this.loading = true;
    const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const userInfo = await loadUserInfo(currentContext);
    const userId: number = parseInt(userInfo.id, 10) || 0;
    
    // 保存到实例变量，供评论点赞等功能使用
    this.userId = userId;

    if (!userId) {
      console.error("未登录或用户ID丢失");
      this.loading = false;
      return;
    }

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        `${BASE_URL}/api/user/${userId}`,
        { method: http.RequestMethod.GET }
      );

      // 关键：先检查 HTTP 状态码
      if (response.responseCode === 404) {
        console.warn("服务器用户不存在，使用本地缓存名字:", userInfo.name);
        this.userName = userInfo.name || "默认用户";
        this.loading = false;
        httpRequest.destroy();
        return;  // 直接返回，不覆盖本地
      }

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as UserInfoResponse;

      if (data.success && data.name) {
        this.userName = data.name;
        // 只有服务器返回成功且有名字，才同步到本地
        await saveUserName(this.userName, currentContext);
        
        // 加载关注和粉丝数据
        await this.loadFollowStats();
      } else {
        // 服务器返回了但数据不完整 → 保留本地已有名字
        console.warn("服务器返回异常，使用本地名字:", userInfo.name);
        this.userName = userInfo.name || "默认用户";
      }
    } catch (e) {
      // 网络错误、超时、解析失败等 → 保留本地已有名字
      console.error('加载用户名失败，使用本地缓存:', e);
      this.userName = userInfo.name || "默认用户";
      // 不要在这里调用 saveUserName！
    } finally {
      httpRequest.destroy();
      this.loading = false;
    }
  }

  // 加载关注和粉丝数据
  async loadFollowStats() {
    if (!this.userId) return;
    
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${BASE_URL}/api/follow/stats?userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as FollowStatsResponse;

      if (data.success) {
        this.followingCount = data.followingCount || 0;
        this.followerCount = data.followerCount || 0;
        console.log(`关注数: ${this.followingCount}, 粉丝数: ${this.followerCount}`);
      }
      
      httpRequest.destroy();
      
      // 同时加载收藏数
      await this.loadFavoriteCount();
    } catch (e) {
      console.error('加载关注粉丝数据失败:', e);
    }
  }

  // 加载收藏数
  async loadFavoriteCount() {
    if (!this.userId) return;
    
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${BASE_URL}/api/favorite/list?userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as FavoriteResponse;

      if (data.success) {
        this.favoriteCount = data.favoritePostIds?.length || 0;
        console.log(`收藏数: ${this.favoriteCount}`);
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error('加载收藏数失败:', e);
    }
  }

  // 加载消息列表（关注的好友）
  async loadMessageUsers() {
    if (!this.userId) return;
    
    try {
      const httpRequest = http.createHttp();
      // 使用conversations接口获取所有聊天会话（包括粉丝发来的消息）
      const response = await httpRequest.request(
        `${BASE_URL}/api/message/conversations?userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as ConversationsResponse;

      if (data.success && data.conversations && data.conversations.length > 0) {
        // 为每个会话用户获取详细信息
        const usersWithMessages = await Promise.all(data.conversations.map(async (conv): Promise<MessageUser | null> => {
          try {
            // 转换userId为number类型
            const convUserId: number = typeof conv.userId === 'string' ? parseInt(conv.userId) : conv.userId;
            
            // 获取用户详细信息
            const userResp = await http.createHttp().request(
              `${BASE_URL}/api/user/${convUserId}`,
              { method: http.RequestMethod.GET }
            );
            const userText = typeof userResp.result === "string"
              ? userResp.result
              : new util.TextDecoder("utf-8").decode(userResp.result as Uint8Array);
            const userData = JSON.parse(userText) as UserInfoResponse;
            
            if (userData.success) {
              // 支持两种返回格式：直接返回name或者返回user对象
              const userName = userData.user?.name || userData.name || '未知用户';
              const userAvatar = userData.user?.avatar || '';
              
              return {
                id: convUserId,
                name: userName,
                avatar: userAvatar,
                lastMessage: conv.lastMessage || '暂无消息',
                lastTime: conv.lastMessageTime || Date.now(),
                unreadCount: conv.unreadCount || 0
              };
            }
          } catch (e) {
            console.error(`获取用户${conv.userId}信息失败:`, e);
          }
          return null;
        }));
        
        // 过滤掉获取失败的用户
        this.messageUsers = usersWithMessages.filter((user) => user !== null) as MessageUser[];
        console.log(`加载了 ${this.messageUsers.length} 个会话`);
      } else {
        // 如果没有会话，清空列表
        this.messageUsers = [];
        console.log('暂无会话记录');
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error('加载消息列表失败:', e);
    }
  }

  generatePostId(): string {
    return Date.now().toString();
  }

  // 切换关注状态
  async toggleFollow(post: PostItem) {
    if (!post.userId || post.userId === this.userId) {
      return; // 不能关注自己
    }

    try {
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/follow/toggle?followerId=${this.userId}&followingId=${post.userId}`,
        { method: http.RequestMethod.POST }
      );
      
      const text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      const data = JSON.parse(text) as FollowResponse;
      
      if (data.success) {
        // 更新本地状态 - 更新该用户的所有帖子
        this.posts = this.posts.map(p => {
          if (p.userId === post.userId) {
            const updatedPost: PostItem = {
              id: p.id,
              baname: p.baname,
              user: p.user,
              userId: p.userId,
              createTime: p.createTime,
              content: p.content,
              image: p.image,
              likes: p.likes,
              comments: p.comments,
              liked: p.liked,
              favorited: p.favorited,
              isFollowing: data.isFollowing
            };
            return updatedPost;
          }
          return p;
        });
        
        // 更新自己的关注数
        if (data.isFollowing) {
          this.followingCount++;
        } else {
          this.followingCount = Math.max(0, this.followingCount - 1);
        }
        
        promptAction.showToast({ 
          message: data.isFollowing ? '关注成功' : '取消关注' 
        });
      } else {
        promptAction.showToast({ message: data.message || '操作失败' });
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error("关注操作错误", e);
      promptAction.showToast({ message: '操作失败' });
    }
  }

  async toggleLike(post: PostItem) {
    try {
      const httpRequest = http.createHttp();
      const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const userInfo = await loadUserInfo(currentContext);
      const userId: number = parseInt(userInfo.id, 10) || 0;

      const resp = await httpRequest.request(
        `${BASE_URL}/api/like/toggleLike?userId=${userId}&postId=${Number(post.id)}`,
        {
          method: http.RequestMethod.POST
        }
      );

      const data = JSON.parse(resp.result as string) as LikeResponse;

      if (data.success) {
        // 创建新的posts数组，更新指定帖子的点赞状态
        this.posts = this.posts.map(p => {
          if (p.id === post.id) {
            const newPost: PostItem = {
              id: p.id,
              baname: p.baname,
              user: p.user,
              userId: p.userId,
              createTime: p.createTime,
              content: p.content,
              image: p.image,
              likes: data.likes,
              comments: p.comments,
              liked: data.liked,
              favorited: p.favorited
            };
            return newPost;
          }
          return p;
        });
      }
    } catch (e) {
      console.error("点赞错误", e);
    }
  }

  async onPublishClick() {
    try {
      // 获取当前用户ID
      const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const userInfo = await loadUserInfo(currentContext);
      const userId = parseInt(userInfo.id, 10) || 0;

      let imageUrl = ``;

      if (this.selectedImage) {
        try {
          imageUrl = `http://10.205.218.246:8080/images/test.png`;
          console.log('图片上传成功:', imageUrl);
        } catch (e) {
          console.error('图片上传失败完整错误：', e);
          Prompt.showToast({ message: '图片上传失败' });
          return; // ❗图片失败就不发帖
        }
      }

      // ⭐ 2️⃣ 用「图片 URL」发帖
      const postData: PostItem = {
        id: this.generatePostId(),
        user: this.userName,
        userId: userId,
        content: this.content,
        baname: this.selectedBa,
        createTime: Date.now(),
        image: imageUrl,   // ⭐ 关键改动
        likes: 0,
        comments: 0
      };

      console.log("提交数据：", JSON.stringify(postData));

      // 3. 发送 POST 请求
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${BASE_URL}/api/post/publish`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify(postData)
        }
      );

      if (response.responseCode === 200) {
        console.log('发布成功:', response.result);

        // 发布成功后可以清空
        this.content = '';
        this.selectedBa = '';
        this.selectedImage = '';

        Prompt.showToast({ message: "发布成功" });

          // 切换回首页并刷新帖子
          this.currentTab = 'home';
          await this.fetchPosts();
          await this.fetchBarStats();

      } else {
        console.error('发布失败',  JSON.stringify(response));
        Prompt.showToast({ message: "发布失败" });
      }

    } catch (err) {
      console.error("发布出错：", JSON.stringify(err));
      Prompt.showToast({ message: "网络错误" });
    }
  }

  // 打开编辑对话框
  openEditDialog(post: PostItem) {
    this.editingPost = post;
    this.editContent = post.content;
    this.editBaname = post.baname;
    this.showEditDialog = true;
  }

  // 保存编辑
  async saveEdit() {
    if (!this.editingPost || !this.editContent.trim()) {
      promptAction.showToast({ message: '内容不能为空' });
      return;
    }

    try {
      const httpRequest = http.createHttp();
      
      const updateData: UpdatePostData = {
        id: this.editingPost.id,
        content: this.editContent,
        baname: this.editBaname
      };

      const response = await httpRequest.request(
        `${BASE_URL}/api/post/update?userId=${this.userId}`,
        {
          method: http.RequestMethod.PUT,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify(updateData)
        }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as UpdatePostResponse;

      if (data.success) {
        promptAction.showToast({ message: '编辑成功' });
        this.showEditDialog = false;
        await this.fetchPosts();
      } else {
        promptAction.showToast({ message: data.message || '编辑失败' });
      }

      httpRequest.destroy();
    } catch (e) {
      console.error('编辑帖子失败:', e);
      promptAction.showToast({ message: '网络错误' });
    }
  }

  // 删除帖子
  async deletePost(post: PostItem) {
    try {
      const result = await promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这条帖子吗？',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#FF0000' }
        ]
      });

      if (result.index !== 1) return;

      const httpRequest = http.createHttp();
      
      const response = await httpRequest.request(
        `${BASE_URL}/api/post/delete?postId=${post.id}&userId=${this.userId}`,
        { method: http.RequestMethod.DELETE }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as DeletePostResponse;

      if (data.success) {
        promptAction.showToast({ message: '删除成功' });
        await this.fetchPosts();
        await this.fetchBarStats();
      } else {
        promptAction.showToast({ message: data.message || '删除失败' });
      }

      httpRequest.destroy();
    } catch (e) {
      console.error('删除帖子失败:', e);
      promptAction.showToast({ message: '网络错误' });
    }
  }

  async fetchPosts() {
    try {
      const httpRequest = http.createHttp();

      // 1. 获取用户 ID
      const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const userInfo = await loadUserInfo(currentContext);
      const userId: number = parseInt(userInfo.id, 10) || 0;

      // 2. 获取帖子列表
      const postResp = await httpRequest.request(
        `${BASE_URL}/api/post/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const postData = JSON.parse(postResp.result as string) as PostListResponse;

      if (!postData.success) return;

      // 3. 获取当前用户收藏列表
      const favResp = await httpRequest.request(
        `${BASE_URL}/api/favorite/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );


      const favData = JSON.parse(favResp.result as string) as FavoriteResponse;

      const favSet = new Set(favData.favoritePostIds ?? []);

      const likeResp = await httpRequest.request(
        `${BASE_URL}/api/like/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const likeData = JSON.parse(likeResp.result as string) as LikeListResponse;

      const likedSet = new Set(likeData.likedPostIds ?? []);


      // 4. 生成前端需要的 PostItem 数组，并标记 favorited 和 isFollowing
      this.posts = await Promise.all(postData.posts.map(async (post) => {
        // 检查是否关注了该用户
        let isFollowing = false;
        if (post.userId && post.userId !== userId) {
          try {
            const followResp = await http.createHttp().request(
              `${BASE_URL}/api/follow/check?followerId=${userId}&followingId=${post.userId}`,
              { method: http.RequestMethod.GET }
            );
            const followText = typeof followResp.result === "string"
              ? followResp.result
              : new util.TextDecoder("utf-8").decode(followResp.result as Uint8Array);
            const followData = JSON.parse(followText) as FollowCheckResponse;
            isFollowing = followData.isFollowing || false;
          } catch (e) {
            console.error('检查关注状态失败:', e);
          }
        }
        
        const p: PostItem = {
          id: post.id,
          user: post.user,
          userId: post.userId,  // ★ 保留userId字段用于编辑删除权限判断
          content: post.content,
          baname: post.baname,
          createTime: post.createTime,
          image: post.image,
          likes: post.likes ?? 0,
          comments: post.comments ?? 0,
          liked: likedSet.has(Number(post.id)),
          favorited: favSet.has(Number(post.id)),   // ★ 标记已收藏
          isFollowing: isFollowing  // ★ 标记关注状态
        };
        return p;
      }));

     console.log("加载帖子成功：", JSON.stringify(this.posts, null, 2));
     // console.log("eeeee：", JSON.stringify(favSet, null, 2));
    } catch (err) {
      console.error("获取帖子失败", err);
    }
  }

  async fetchFavoritePosts() {
    try {
      const httpRequest = http.createHttp();
      const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const userInfo = await loadUserInfo(currentContext);
      const userId: number = parseInt(userInfo.id, 10) || 0;

      // 1. 获取收藏的帖子列表
      const resp = await httpRequest.request(
        `${BASE_URL}/api/post/favList?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const favPostList = JSON.parse(resp.result as string) as PostListResponse;

      // 2. 获取收藏 id 列表（favSet）
      const favResp = await httpRequest.request(
        `${BASE_URL}/api/favorite/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const favData = JSON.parse(favResp.result as string)as FavoriteResponse;
      const favSet = new Set(favData.favoritePostIds ?? []);

      const likeResp = await httpRequest.request(
        `${BASE_URL}/api/like/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const likeData = JSON.parse(likeResp.result as string) as LikeListResponse;

      const likedSet = new Set(likeData.likedPostIds ?? []);

      this.favoritePosts= favPostList.posts.map((post) => {
        const p: PostItem = {
          id: post.id,
          user: post.user,
          userId: post.userId,  // ★ 保留userId字段用于编辑删除权限判断
          content: post.content,
          baname: post.baname,
          createTime: post.createTime,
          image: post.image,
          likes: post.likes ?? 0,
          comments: post.comments ?? 0,
          liked: likedSet.has(Number(post.id)),
          favorited: favSet.has(Number(post.id))   // ★ 标记已收藏
        };
        return p;
      });

      console.log("收藏帖子：", this.favoritePosts);

    } catch (err) {
      console.error("加载收藏失败", err);
      this.favoritePosts = [];
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())} ` +
      `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
  }

  // 格式化消息时间（显示更友好的时间）
  formatMessageTime(timestamp?: number): string {
    if (!timestamp) return '';
    
    const now = Date.now();
    const diff = now - timestamp;
    const minute = 60 * 1000;
    const hour = 60 * minute;
    const day = 24 * hour;
    
    if (diff < minute) {
      return '刚刚';
    } else if (diff < hour) {
      return `${Math.floor(diff / minute)}分钟前`;
    } else if (diff < day) {
      return `${Math.floor(diff / hour)}小时前`;
    } else if (diff < 7 * day) {
      return `${Math.floor(diff / day)}天前`;
    } else {
      const date = new Date(timestamp);
      const pad = (n: number) => n.toString().padStart(2, '0');
      return `${date.getMonth()+1}-${pad(date.getDate())}`;
    }
  }

  async toggleFavorite(post: PostItem) {
    const httpRequest = http.createHttp();
    const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const userInfo = await loadUserInfo(currentContext);
    const userId: number = parseInt(userInfo.id, 10) || 0;

    try {
      const response = await httpRequest.request(
        `${BASE_URL}/api/favorite/toggle`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify({
            userId: userId,
            postId: Number(post.id)
          })
        }
      );



      const data = JSON.parse(response.result as string) as PostListResponse;

      if (data.success) {
        post.favorited = !post.favorited;

        prompt.showToast({
          message: post.favorited ? '收藏成功 ★ ' : '已取消收藏 ☆ '
        });

        if(this.currentTab === 'favorite'){
          await this.fetchFavoritePosts();
        }else if(this.currentTab === 'home'){await this.fetchPosts();}
      }
    } catch (err) {
      console.error('收藏失败：', JSON.stringify(err, null, 2));
      prompt.showToast({ message: '收藏失败，请稍后再试' });
    }
  }

  closeComment() {
    this.showCommentPanel = false
    this.commentInput = ''
    this.comments = []
  }

  async  fetchComments(postId: string): Promise<CommentItem[]> {

  const httpRequest = http.createHttp()

  try {
    const response = await httpRequest.request(
      `${BASE_URL}/api/comment/list?postId=${postId}&userId=${this.userId}`,
      {
        method: http.RequestMethod.GET
      }
    )

    const result = JSON.parse(response.result as string) as CommentListResponse

    this.comments = (result.comments ?? []).map(item => {
      const comment: CommentItem = {
        id: item.id,
        postId: item.postId,
        userId: item.userId,
        userName: item.userName,
        avatar: item.avatar,
        content: item.content,
        createTime: item.createTime,
        likes: item.likes || 0,
        liked: item.liked || false,
        isMine: Number(item.userId) === this.userId
      }
      return comment
    })


    if (result.success) {
      return result.comments as CommentItem[]
    } else {
      return []
    }

  } catch (err) {
    console.error('fetchComments error', err)
    return []
  } finally {
    httpRequest.destroy()
  }
}

  async sendComment() {
    const content = this.commentInput.trim()
    if (!content) return

    const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    const userInfo = await loadUserInfo(currentContext)
    const userId = Number(userInfo.id)

    const httpRequest = http.createHttp()

    await httpRequest.request(
      `${BASE_URL}/api/comment/add`
        + `?postId=${this.currentPostId}`
        + `&userId=${userId}`
        + `&content=${encodeURIComponent(content)}`,
      {
        method: http.RequestMethod.POST
      }
    )


    // 清空输入框
    this.commentInput = ''
    // 让键盘消失
    this.commentInputController.stopEditing()

    // ✅ fetchComments 需要参数
    this.fetchComments(String(this.currentPostId))
  }

  async toggleCommentLike(comment: CommentItem) {
    try {
      console.log('点击评论点赞, userId:', this.userId, 'commentId:', comment.id);
      
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/comment/toggleLike?userId=${this.userId}&commentId=${comment.id}`,
        { method: http.RequestMethod.POST }
      );
      
      const text = typeof resp.result === "string"
        ? resp.result
        : JSON.stringify(resp.result);
      
      console.log('点赞响应:', text);
      
      const data = JSON.parse(text) as CommentLikeResponse;
      
      if (data.success) {
        comment.liked = data.liked;
        comment.likes = data.likes;
        console.log('点赞成功, liked:', data.liked, 'likes:', data.likes);
        // 强制刷新评论列表以更新UI
        this.comments = [...this.comments];
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error("评论点赞错误", JSON.stringify(e));
    }
  }

  async fetchBarStats() {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${BASE_URL}/api/post/barStats`,
        { method: http.RequestMethod.GET }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as BarStatsResponse;

      if (data.success && data.stats) {
        // 更新已有的forums数据
        this.forums = this.forums.map(forum => {
          const stat = data.stats.find(s => s.baname === forum.baname);
          if (stat) {
            return {
              baname: forum.baname,
              posts: stat.postCount,
              members: stat.memberCount,
              icon: forum.icon
            };
          }
          return forum;
        });
      }

      httpRequest.destroy();
    } catch (e) {
      console.error('获取吧统计信息失败:', e);
    }
  }

  async deleteComment(item: CommentItem) {
    try {
      console.log('开始删除评论, item.id:', item.id, 'item.userId:', item.userId, 'this.userId:', this.userId)
      
      // 显示确认对话框
      const confirmResult = await promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这条评论吗？',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#FF0000' }
        ]
      });

      if (confirmResult.index !== 1) return;
      
      const httpRequest = http.createHttp()
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
      const userInfo = await loadUserInfo(ctx)
      const userId = Number(userInfo.id)
      
      console.log('从本地获取的userId:', userId)

      const url = `${BASE_URL}/api/comment/delete?commentId=${item.id}&userId=${userId}`
      console.log('请求URL:', url)
      
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.POST
      })
      
      console.log('删除响应:', resp.result)

      const data = JSON.parse(resp.result as string) as BaseResponse

      if (!data.success) {
        console.warn('删除失败:', data.msg)
        prompt.showToast({ message: '删除失败: ' + (data.msg || '未知错误') })
        return
      }

      // ⭐ 关键：前端立即移除
      this.comments = this.comments.filter(c => c.id !== item.id)
      prompt.showToast({ message: '删除成功' })
      console.log('评论已从列表移除')

    } catch (e) {
      console.error('删除评论失败', JSON.stringify(e))
      prompt.showToast({ message: '删除失败，请重试' })
    }
  }

  openComment(postId: number) {
    this.currentPostId = postId
    this.showCommentPanel = true

    // ⭐⭐ 关键：打开时立即获取评论
    this.fetchComments(String(postId))
  }

  aboutToAppear() {
    this.loadUserNameFromDB();
    this.fetchPosts();
    this.fetchBarStats();
  }

  onPageShow() {
    // 页面显示时，如果在消息tab，刷新消息列表（从聊天页面返回时）
    if (this.currentTab === 'message') {
      this.loadMessageUsers();
    }
  }

  build() {
    Stack() {
      // 背景图
      Image($r('app.media.bj2'))
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('120%')


      Column({ space: 30 }) {

        if (this.currentTab === 'home') {

          Row() {
            Image($r('app.media.icon_search'))
              .width(24)
              .height(24)
              .margin({ left: 10 })

            TextInput({ 
              placeholder: "搜索帖子内容、用户名、吧名",
              text: this.searchKeyword
            })
              .fontColor('#333333')
              .fontSize(16)
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .onChange((value) => {
                this.searchKeyword = value;
              })
              .onSubmit(() => {
                this.searchPosts();
              })

            if (this.searchKeyword.length > 0) {
              Text('✕')
                .fontColor('#999999')
                .fontSize(18)
                .margin({ right: 5 })
                .onClick(() => {
                  this.clearSearch();
                })
            }

            Text("搜索")
              .fontColor('#007AFF')
              .fontSize(16)
              .margin({ right: 10 })
              .onClick(() => {
                this.searchPosts();
              })
          }
          .width('95%')
          .height(40)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: -0 })

          // 中间白框占位
          Column() {
            // 搜索结果提示
            if (this.isSearching) {
              Row() {
                Text(`找到 ${this.filteredPosts.length} 个结果`)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ left: 16, top: 10, bottom: 5 })
              }
              .width('100%')
            }

            Scroll() {
              Column({ space: 16 }) {
                // 根据搜索状态显示不同的帖子列表
                ForEach(this.isSearching ? this.filteredPosts : this.posts, (post: PostItem) => {
                  Column() {
                    // 帖子头部
                    Row({ space: 10 }) {
                      Image(this.forums.find(b => b.baname === post.baname)?.icon)
                        .width(40)
                        .height(40)
                        .borderRadius(20)
                        .margin({ right: 10 });

                      Text(post.baname)
                        .fontSize(16)
                        .fontColor(Color.Black)
                        .fontWeight(FontWeight.Medium)
                        .margin({ top: 8, bottom: 8 });

                      Text(post.favorited ? `★ 已收藏` : `☆ 收藏`)
                        .fontColor(post.favorited ? '#ffa500' : '#666666')
                        .fontSize(13)
                        .onClick(() => this.toggleFavorite(post));
                    }

                    // 用户信息
                    Row({ space: 2 }) {
                      if (this.headImage.startsWith('http') || this.headImage.startsWith('https')) {
                        // 网络图片
                        Image(this.headImage)
                          .width(40)
                          .height(40)
                          .borderRadius(20)
                          .backgroundColor('#CCCCCC');
                      }
                      else
                      {
                        Image($r('app.media.head'))
                          .width(40)
                          .height(40)
                          .borderRadius(20)
                          .backgroundColor('#CCCCCC');
                      }
                      Column({ space: 2 }) {
                        Row({ space: 8 }) {
                          Text(post.user)
                            .fontSize(15)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(Color.Black);
                          
                          // 只在不是自己的帖子时显示关注按钮
                          if (post.userId && post.userId !== this.userId) {
                            Text(post.isFollowing ? '已关注' : '+ 关注')
                              .fontSize(11)
                              .fontColor(post.isFollowing ? '#999999' : '#007AFF')
                              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                              .border({
                                width: 1,
                                color: post.isFollowing ? '#cccccc' : '#007AFF',
                                radius: 3
                              })
                              .backgroundColor(post.isFollowing ? '#f5f5f5' : Color.White)
                              .onClick(() => this.toggleFollow(post))
                          }
                        }

                        Text( this.formatTime(post.createTime) )
                          .fontSize(12)
                          .fontColor('#999999');
                      }.alignItems(HorizontalAlign.Start);
                      
                      Blank()
                      
                      // 如果是当前用户的帖子，显示编辑和删除按钮
                      if (post.userId === this.userId) {
                        Row({ space: 15 }) {
                          Text('编辑')
                            .fontSize(14)
                            .fontColor('#007AFF')
                            .onClick(() => this.openEditDialog(post))
                          
                          Text('删除')
                            .fontSize(14)
                            .fontColor('#FF3B30')
                            .onClick(() => this.deletePost(post))
                        }
                      }
                    }
                    .width('100%')

                    // 内容
                    Text(post.content)
                      .fontSize(14)
                      .fontColor(Color.Black)
                      .margin({ top: 8, bottom: 8 });

                    // 图片
                    if (post.image && post.image.startsWith('http')) {
                      Image(post.image)
                        .width(200)
                        .height(200)
                        .objectFit(ImageFit.Cover)
                        .onError(() => {
                          console.error('图片加载失败:', post.image);
                        })
                    } else {
                      // 没图就不渲染
                    }

                    // 操作栏
                    Row({ space: 80 }) {
                      Text(post.liked ? `❤️ 已点赞 ${post.likes}` : `👍 点赞 ${post.likes}`)
                        .fontColor(post.liked ? Color.Red : '#666666')
                        .fontSize(13)
                        .onClick(() => this.toggleLike(post));

                      Text(`💬 评论${post.comments}`)
                        .fontColor('#666666')
                        .fontSize(13)
                        .onClick(() => {
                          this.currentPost = post
                          this.showCommentPanel = true
                          this.openComment(Number(post.id))
                        });

                      Text('↗ 分享')
                        .fontColor('#666666')
                        .fontSize(13)
                        .onClick(() => {
                          this.showShare = true
                        })
                    }
                    .margin({ top: 8 })
                  }
                  .width('105%')
                  .padding(12)
                  .backgroundColor('#F9F9F9')
                  .borderRadius(16)
                  .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 2 })
                  .alignItems(HorizontalAlign.Start);

                });
                
                // 搜索无结果提示
                if (this.isSearching && this.filteredPosts.length === 0) {
                  Column({ space: 10 }) {
                    Text('🔍')
                      .fontSize(48)
                      .margin({ top: 50 })
                    Text('没有找到相关帖子')
                      .fontSize(16)
                      .fontColor('#999999')
                    Text(`关键词: ${this.searchKeyword}`)
                      .fontSize(14)
                      .fontColor('#CCCCCC')
                  }
                  .width('100%')
                  .padding({ top: 30, bottom: 30 })
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                }
              }
              .width('100%')
              .padding({ top: 10, bottom: 20 });
            }
            .width('95%')
            .height('100%')
            .margin({top:10})
            .scrollBar(BarState.Off)
          }
          .width('95%')
          .height(612)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Start)
          .margin({ top: -10 })



        }
        else if (this.currentTab === 'profile') {
          Column() {

            Column() {
              if (this.isEditing) {
                Row({ space: 10 }) {
                  // 关键修改：动态判断 headImage 是网络URL还是本地资源
                  if (this.headImage.startsWith('http') || this.headImage.startsWith('https')) {
                    // 网络图片
                    Image(this.headImage)
                      .width(100)
                      .height(100)
                      .borderRadius(50)
                      .objectFit(ImageFit.Cover)  // 推荐加上，防止变形
                      .alt($r('app.media.head'))  // 加载失败时显示默认头像

                  } else {
                    // 本地资源（初始默认头像或 $r 路径）
                    Image($r(this.headImage))
                      .width(100)
                      .height(100)
                      .borderRadius(50)
                      .objectFit(ImageFit.Cover)
                  }

                  Button("修改头像")
                    .width(80)
                    .height(40)
                    .borderRadius(8)
                    .fontSize(10)
                    .fontColor(Color.White)
                    .backgroundColor("#007AFF")
                    .onClick(async () => {
                      await this.pickImageFromGallery();
                    })

                }
                .margin({ top: -190 })
              } else {
                if (this.headImage.startsWith('http') || this.headImage.startsWith('https')) {
                  Image(this.headImage)
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                } else {
                  Image($r(this.headImage))
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                }
              }
              if (this.isEditing) {
                TextInput({ text: this.userName })
                  .width(200)
                  .height(40)
                  .fontSize(22)
                  .fontColor(Color.Black)
                  .onChange((value) => {
                    this.userName = value
                  })
                  .margin({ top: 10 })
              }
              else
              {
                Text(this.userName?this.userName:"默认用户")
                  .fontSize(22)
                  .fontColor(Color.Black)
                  .margin({ top: 10 })
              }

               Text(this.isEditing ? "保存" : "编辑")
                .fontSize(18)
                .fontColor(Color.White)
                .width(120)
                .height(40)
                .borderRadius(20)
                .backgroundColor(this.isEditing ?'#FF0000':'#007AFF')
                .textAlign(TextAlign.Center)

                .margin({ top: 20 })
                 .onClick(async () => {
                   if (this.isEditing) {
                     const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;


                     const userInfo = await loadUserInfo(currentContext);
                     const userId: number = parseInt(userInfo.id, 10) || 0;  // 转回 number

                     if (!userId) {
                       console.error("未登录或用户ID丢失");
                       return;
                     }
                     const httpRequest: http.HttpRequest = http.createHttp();

                     const response = await httpRequest.request(
                       `${BASE_URL}/api/updateName`,
                       {
                         method: http.RequestMethod.POST,
                         header: { "Content-Type": "application/json" },
                         extraData: {
                           id: String(userId),
                           name: this.userName
                         }
                       }
                     )
                     console.log("请求参数:", JSON.stringify({ id: String(userId), name: this.userName }));

                     let text = typeof response.result === "string"
                       ? response.result
                       : new util.TextDecoder("utf-8").decode(response.result as Uint8Array)

                     const data: UpdateNameResponse = JSON.parse(text) as UpdateNameResponse;

                     if (data.success) {
                       await saveUserName(this.userName, currentContext);
                     }
                     console.log("返回结果:", text);
                     httpRequest.destroy()
                   }

                   this.isEditing = !this.isEditing
                 })

              Row({ space: 30}) {
                Column() {
                  Text("关注").fontSize(16).fontColor(Color.Gray)
                  Text(this.followingCount.toString()).fontSize(18).fontColor(Color.Black)
                }
                .onClick(() => {
                  // 跳转到关注列表
                  router.pushUrl({
                    url: 'pages/FollowListPage',
                    params: {
                      type: 'following',
                      currentUserId: this.userId,
                      targetUserId: this.userId
                    }
                  });
                })

                Column() {
                  Text("粉丝").fontSize(16).fontColor(Color.Gray)
                  Text(this.followerCount.toString()).fontSize(18).fontColor(Color.Black)
                }
                .onClick(() => {
                  // 跳转到粉丝列表
                  router.pushUrl({
                    url: 'pages/FollowListPage',
                    params: {
                      type: 'follower',
                      currentUserId: this.userId,
                      targetUserId: this.userId
                    }
                  });
                })

                Column() {
                  Text("收藏").fontSize(16).fontColor(Color.Gray)
                  Text(this.favoriteCount.toString()).fontSize(18).fontColor(Color.Black)
                }
                .onClick(() => {
                  // 跳转到收藏列表
                  router.pushUrl({
                    url: 'pages/FavoritePostsPage',
                    params: {
                      userId: this.userId
                    }
                  });
                })
              }
              .margin({ top: 10 })

              Button("退出登录")
                .width('80%')
                .height(48)
                .fontSize(18)
                .fontColor(Color.White)
                .backgroundColor(Color.Red)          // 红色更醒目
                .borderRadius(12)
                .margin({ top: 40, bottom: 30 })     // 给点上下间距
                .onClick(async () => {
                  // 1. 弹个确认框（可选，防止误点）
                  const result: promptAction.ShowDialogSuccessResponse = await promptAction.showDialog({
                    title: '退出登录',
                    message: '确定要退出当前账号吗？',
                    buttons: [
                      { text: '取消', color: '#666666' },
                      { text: '确定', color: '#FF0000' }
                    ]
                  });

                  if (result.index !== 1) return; // 点取消直接返回

                  // 2. 清除本地登录信息（preferences）
                  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                  try {
                    const storage = await preferences.getPreferences(context, "userInfo");
                    await storage.clear(); // 清除全部键值对
                    await storage.flush();
                    console.log("本地登录信息已清除");
                  } catch (e) {
                    console.error("清除登录信息失败:", e);
                  }

                  // 3. 可选：把内存里的状态也清空
                  this.userName = "";

                  this.isEditing = false;


                  router.replaceUrl({ url: 'pages/LoginPage' });

                })





          }
            .width('95%')
            .height('calc(115% - 100px)')
            .borderRadius(25)
            .backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
            .margin({ top: 30 })
        }
        }
        else if (this.currentTab === 'forum') {
          Column() {
            Text("所有的吧")
              .fontSize(27)
              .fontColor(Color.Black)
              .margin({ top: 5, bottom: 0 })

            // 使用 Scroll 包裹整个吧列表
            // 使用 Scroll 包裹整个吧列表
            Scroll() {
              Column({ space: 16 }) {
                ForEach(this.forums, (forum: ForumItem) => {
                  Row() {
                    // 吧头像
                    Image(forum.icon)
                      .width(70)
                      .height(70)
                      .borderRadius(12)
                      .margin({ right: 12 })

                    // 吧文字信息
                    Column({ space: 4 }) {
                      Text(forum.baname)
                        .fontSize(18)
                        .fontColor(Color.Black)
                        .fontWeight(FontWeight.Medium)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text(`${forum.posts} 帖子 · ${forum.members} 成员`)
                        .fontSize(14)
                        .fontColor('#666666')
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Start)
                    .width('100%')
                  }
                  .width('92%')
                  .height(90)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor(Color.White)
                  .borderRadius(14)
                  .shadow({ radius: 3, color: '#22000000', offsetX: 0, offsetY: 2 })
                  .onClick(() => {
                    // 跳转到帖子列表页
                    router.pushUrl({
                      url: 'pages/PostListPage',
                      params: {
                        baname: forum.baname
                      }
                    });
                  })
                })
              }
              .padding({ top: 5, left: 16, right: 16, bottom: 16 })
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#F5F5F5')



          }
        }


        if (this.currentTab === 'post'){
          Column({ space: 20 }) {
            // 顶部标题
            Text('发布帖子')
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)
              .margin({ top: 20 })

            // 内容输入框
            TextInput({ placeholder: '请输入帖子内容...' })
              .width('90%')
              .height(100)
              .border({ width: 1, color: '#CCCCCC' })
              .padding(10)
              .fontSize(16)
              .onChange((val) => this.content = val)

            // 选择图片区域
            Column() {
              if (this.selectedImage !== '') {
                Image(this.selectedImage)
                  .width(100)
                  .height(100)
                  .borderRadius(12)
                  //.objectFit('cover')
              } else {
                Text('+')
                  .fontSize(40)
                  .fontColor('#AAAAAA')
              }
            }

              .width(100)
              .height(100)
              .border({ width: 1, color: '#CCCCCC' })
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor('#F5F5F5')
            .onClick(async () => {
              await this.pickImageForPost();
            })


            // 选择的吧
            Text('选择的吧')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)
              .margin({ top: 10, bottom: 5 })

            // 吧列表
            Scroll() {
              Row({ space: 10 }) {
                ForEach(this.forums, (item: ForumItem) => {
                  Column() {
                    Image(item.icon)
                      .width(50)
                      .height(50)
                      .borderRadius(25)
                    Text(item.baname)
                      .fontSize(14)
                      .fontColor(Color.Black)
                      .margin({ top: 4 })
                  }
                  .width(100)
                  .height(100)
                  .border({
                    width: 2,
                    color: this.selectedBa === item.baname ? '#3B82F6' : '#CCCCCC'
                  })
                  .borderRadius(12)
                  .alignItems(HorizontalAlign.Center)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    this.selectedBa = item.baname
                  })
                })
              }.margin({ bottom: 20 })
            }
            .scrollable(ScrollDirection.Horizontal)
            // 发布按钮
            Button('发布')
              .width('90%')
              .height(45)
              .borderRadius(8)
              .backgroundColor(
                this.content.length > 0 && this.selectedBa !== ''
                  ? '#3B82F6'
                  : '#A0C4FF'
              )
              .fontColor(Color.White)
              .fontSize(18)
              .onClick(async () => {
                if (this.content.length === 0 || this.selectedBa === '') return

                // 调用后端 API
                try {
                  await this.onPublishClick()
                } catch (err) {
                  console.error('发布失败', err);
                }

              })

          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding(20)
        }


        if (this.currentTab === 'message'){
          Column() {
            // 顶部导航栏
            Row() {
              Text('消息')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .height(56)
            .backgroundColor('#00a6ff')
            .padding({ left: 16, right: 16 })

            // 消息列表
            if (this.messageUsers.length === 0) {
              // 空状态
              Column({ space: 16 }) {
                Text('📭')
                  .fontSize(48)
                Text('暂无消息')
                  .fontSize(16)
                  .fontColor('#999999')
                Text('开始和好友聊天吧')
                  .fontSize(14)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#f5f5f5')
            } else {
              // 消息列表
              List({ space: 1 }) {
                ForEach(this.messageUsers, (user: MessageUser) => {
                  ListItem() {
                    Row({ space: 12 }) {
                      // 头像
                      Image(user.avatar ? user.avatar : $r('app.media.head'))
                        .width(50)
                        .height(50)
                        .borderRadius(25)

                      // 消息内容
                      Column({ space: 4 }) {
                        Row() {
                          Text(user.name)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .fontColor('#333333')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)
                          
                          // 时间
                          Text(this.formatMessageTime(user.lastTime))
                            .fontSize(12)
                            .fontColor('#999999')
                        }
                        .width('100%')

                        Row() {
                          Text(user.lastMessage || '点击开始聊天')
                            .fontSize(14)
                            .fontColor('#999999')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)
                          
                          // 未读消息数
                          if (user.unreadCount && user.unreadCount > 0) {
                            Text(user.unreadCount.toString())
                              .fontSize(11)
                              .fontColor(Color.White)
                              .backgroundColor('#FF3B30')
                              .borderRadius(10)
                              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                              .textAlign(TextAlign.Center)
                          }
                        }
                        .width('100%')
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor(Color.White)
                    .onClick(() => {
                      // 进入私聊页面
                      router.pushUrl({
                        url: 'pages/ChatPage',
                        params: {
                          userId: this.userId,
                          targetUserId: user.id,
                          targetUserName: user.name,
                          targetUserAvatar: user.avatar
                        }
                      }).catch((err: Error) => {
                        console.error('跳转聊天页面失败:', err);
                        promptAction.showToast({ message: '聊天功能开发中...' });
                      });
                    })
                  }
                })
              }
              .width('100%')
              .layoutWeight(1)
              .backgroundColor('#f5f5f5')
            }
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#f5f5f5')
        }

        if (this.currentTab === 'favorite'){
            Column() {
              Scroll() {
                Column({ space: 16 }) {
                  ForEach(this.favoritePosts, (post: PostItem) => {
                    Column() {
                      // 帖子头部
                      Row({ space: 10 }) {
                        Image(this.forums.find(b => b.baname === post.baname)?.icon)
                          .width(40)
                          .height(40)
                          .borderRadius(20)
                          .margin({ right: 10 });

                        Text(post.baname)
                          .fontSize(16)
                          .fontColor(Color.Black)
                          .fontWeight(FontWeight.Medium)
                          .margin({ top: 8, bottom: 8 });

                        Text(post.favorited ? `★ 已收藏` : `☆ 收藏`)
                          .fontColor(post.favorited ? '#ffa500' : '#666666')
                          .fontSize(13)
                          .onClick(() => this.toggleFavorite(post));
                      }

                      // 用户信息
                      Row({ space: 2 }) {
                        Image($r('app.media.head'))
                          .width(40)
                          .height(40)
                          .borderRadius(20)
                          .backgroundColor('#CCCCCC');

                        Column({ space: 2 }) {
                          Text(post.user)
                            .fontSize(15)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(Color.Black);

                          Text( this.formatTime(post.createTime) )
                            .fontSize(12)
                            .fontColor('#999999');
                        }.alignItems(HorizontalAlign.Start);
                      }

                      // 内容
                      Text(post.content)
                        .fontSize(14)
                        .fontColor(Color.Black)
                        .margin({ top: 8, bottom: 8 });

                      // 图片
                      if (post.image) {
                        Image($r(post.image))
                          .width('100%')
                          .height(180)
                          .borderRadius(12)
                          .objectFit(ImageFit.Cover);
                      }

                      // 操作栏
                      Row({ space: 80 }) {
                        Text(post.liked ? `❤️ 已点赞 ${post.likes}` : `👍 点赞 ${post.likes}`)
                          .fontColor(post.liked ? Color.Red : '#666666')
                          .fontSize(13)
                          .onClick(() => this.toggleLike(post));

                        Text(`💬 评论${post.comments}`)
                          .fontColor('#666666')
                          .onClick(() => {
                            this.currentPost = post
                            this.showCommentPanel = true
                            this.openComment(Number(post.id))
                          })
                          .fontSize(13);

                        Text('↗ 分享')
                          .fontColor('#666666')
                          .fontSize(13)
                          .onClick(() => {
                            this.showShare = true
                          });
                      }
                      .margin({ top: 8 })
                    }
                    .width('105%')
                    .padding(12)
                    .backgroundColor('#F9F9F9')
                    .borderRadius(16)
                    .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 2 })
                    .alignItems(HorizontalAlign.Start);

                  });
                }
                .width('100%')
                .padding({ top: 10, bottom: 20 });
              }
              .width('95%')
              .height('100%')
              .margin({top:10})
              .scrollBar(BarState.Off)
            }
            .width('95%')
            .height(612)
            .borderRadius(25)
            .backgroundColor(Color.White)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Start)
            .margin({ top: -10 })
        }


      }
      .width('100%')
      .height('calc(100% - 70px)')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Start)

      // 底部菜单栏
      Row() {
        Column() {
          Text("首页").fontSize(27).fontColor(this.currentTab === 'home' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'home'
              this.showCommentPanel = false
              this.fetchPosts()
            })
        }

        Column() {
          Text("进吧").fontSize(27).fontColor(this.currentTab === 'forum' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'forum'
              this.showCommentPanel = false
            })
        }

        Column() {
          Text("发布").fontSize(27).fontColor(this.currentTab === 'post' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'post'
              this.showCommentPanel = false
            })
        }

        Column() {
          Text("消息").fontSize(27).fontColor(this.currentTab === 'message' ? '#007AFF' : Color.Black)
            .onClick(async () => {
              this.currentTab = 'message'
              this.showCommentPanel = false
              // 切换到消息页面时，加载关注的好友列表
              await this.loadMessageUsers()
            })
        }

        Column() {
          Text("我的").fontSize(27).fontColor(this.currentTab === 'profile' ? '#007AFF' : Color.Black)
            .onClick(async () => {
              this.currentTab = 'profile'
              this.showCommentPanel = false
              // 切换到个人中心时，重新加载关注和粉丝数据
              await this.loadFollowStats()
            })
        }
      }
      .width('100%')
      .height(70)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.SpaceAround)
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })


      if (this.showShare) {
        // Mask
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .onClick(() => {
            this.showShare = false
          })

        // 底部分享面板
        Column({ space: 20 }) {
          Grid() {
            GridItem(){
              ShareItem('邮件', $r('app.media.youjian'))
            }
            GridItem(){
              ShareItem('微信好友', $r('app.media.weix'))
            }
            GridItem(){
              ShareItem('微博', $r('app.media.weibo'))
            }
            GridItem(){
              ShareItem('QQ好友', $r('app.media.qq'))
            }
            GridItem(){
              ShareItem('更多', $r('app.media.gduo'))
            }

          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .rowsGap(20)
          .height(180)

          Divider()

          Text('取消')
            .fontSize(18)
            .fontColor('#333')
            .padding(12)
            .onClick(() => {
              this.showShare = false
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .position({ y: '65%' })   // 控制面板高度
      }
      
      // 编辑帖子对话框
      if (this.showEditDialog) {
        Stack() {
          // 遮罩
          Rect()
            .fill('#66000000')
            .width('100%')
            .height('100%')
            .onClick(() => this.showEditDialog = false)

          // 编辑面板
          Column({ space: 20 }) {
            Text('编辑帖子')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)

            TextArea({ placeholder: '请输入帖子内容...', text: this.editContent })
              .width('100%')
              .height(150)
              .onChange((value) => this.editContent = value)

            Text('选择吧：' + this.editBaname)
              .fontSize(14)
              .fontColor('#666')

            Row({ space: 10 }) {
              Button('取消')
                .width('45%')
                .backgroundColor('#EEEEEE')
                .fontColor('#333')
                .onClick(() => this.showEditDialog = false)

              Button('保存')
                .width('45%')
                .backgroundColor('#007AFF')
                .onClick(() => this.saveEdit())
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .width('85%')
        }
        .width('100%')
        .height('100%')
      }
      
      if (this.showCommentPanel) {
        Stack() {

          // ===== 遮罩 =====
          Rect()
            .fill('#66000000')
            .width('100%')
            .height('100%')
            .onClick(() => this.closeComment())

          // ===== 评论面板 =====
          Column() {

            // —— Header ——
            Row() {
              Text('评论')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)

              Blank()

              Text('  ✕')
                .fontSize(20)
                .onClick(() => this.closeComment())
            }
            .padding(16)
            .border({ width: { bottom: 1 }, color: '#eee' })

            // —— 内容区（关键）——
            Column() {

              if (this.comments.length === 0) {
                // 空评论状态
                Column() {
                  Text('现在还没有评论哦')
                    .fontSize(14)
                    .fontColor('#999')
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .layoutWeight(1)
              } else {
                // 评论列表
                Scroll() {
                  Column({ space: 0 }) {
                    ForEach(this.comments, (item: CommentItem) => {
                      this.CommentItemView(item)
                    })
                  }
                }
                .layoutWeight(1)
              }

            }
            .layoutWeight(1)

            // —— 输入区 ——
            Row({ space: 8 }) {
              TextInput({
                placeholder: '说点什么吧…',
                text: this.commentInput,
                controller: this.commentInputController
              })
                .onChange((value: string) => {
                  this.commentInput = value
                })
                .height(40)
                .borderRadius(20)
                .backgroundColor('#F5F5F5')
                .padding({ left: 12 })
                .layoutWeight(1)


              Text('发送')
                .fontSize(14)
                .fontColor(this.commentInput.trim() ? Color.Blue : '#999')
                .onClick(() => {
                  if (!this.commentInput.trim()) return
                  this.sendComment()
                })
            }
            .padding(12)
            .backgroundColor(Color.White)

          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .onClick(() => {}) // ⭐ 阻断点击穿透
          .align(Alignment.Bottom)

        }
        .width('100%')
        .height('calc(100% - 70px)')
      }


    }
    .width('100%')
    .height('100%')

  }

}

@Builder
function ShareItem(name: string, icon: Resource, onClick?: () => void) {
  Column({ space: 8 }) {
    Image(icon)
      .width(56)
      .height(56)
      .borderRadius(28)

    Text(name)
      .fontSize(12)
      .fontColor('#333')
  }
  .onClick(() => {
    onClick && onClick()
  })
  .alignItems(HorizontalAlign.Center)
}



