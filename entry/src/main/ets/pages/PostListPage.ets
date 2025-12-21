import router from '@ohos.router';
import http from '@ohos.net.http';
import util from '@ohos.util';
import { BASE_URL } from '../pages/ip';
import { loadUserInfo, UserInfo } from '../pages/LoginPage';
import { common } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';

interface PostItem {
  id: string
  baname: string
  user?: string      // 用户名（显示用，从后端返回）
  userId?: number    // 用户ID（发布帖子时使用）
  createTime: number
  content: string
  image?: string
  likes: number
  comments: number
  liked?: boolean;
  favorited?: boolean;
  isFollowing?: boolean; // 是否已关注该帖子作者
}

interface PostListResponse {
  success: boolean;
  posts: PostItem[];
}

interface LikeResponse {
  success: boolean
  liked: boolean;
  likes: number
}

interface FavoriteResponse {
  success: boolean;
  favoritePostIds: number[];
}

interface LikeListResponse {
  success: boolean;
  likedPostIds: number[];
}

interface ToggleFavoriteResponse {
  success: boolean;
}

interface AddFriendResponse {
  success: boolean;
  message: string;
}

interface FollowResponse {
  success: boolean;
  isFollowing: boolean;
  message: string;
  followerFollowingCount?: number;
  followingFollowerCount?: number;
}

interface FollowCheckResponse {
  success: boolean;
  isFollowing: boolean;
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

interface BaseResponse {
  success: boolean
  msg?: string
}

@Entry
@Component
struct PostListPage {
  @State baname: string = ''
  @State posts: PostItem[] = []
  @State loading: boolean = false
  @State userId: number = 0
  @State currentUserName: string = ''
  @State showAddFriendDialog: boolean = false
  @State selectedPostUser: string = ''
  
  // 编辑帖子相关状态
  @State showEditDialog: boolean = false
  @State editingPost: PostItem | null = null
  @State editContent: string = ''
  
  // 评论相关状态
  @State showCommentPanel: boolean = false
  @State currentPost: PostItem | null = null
  @State currentPostId: number = 0
  @State comments: CommentItem[] = []
  @State commentInput: string = ''
  private commentInputController: TextInputController = new TextInputController()

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    this.baname = params['baname'] || '';
    console.log('进入吧:', this.baname);
    this.loadUserAndPosts();
  }

  async loadUserAndPosts() {
    try {
      const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const userInfo = await loadUserInfo(currentContext) as UserInfo;
      this.userId = parseInt(userInfo.id, 10) || 0;
      this.currentUserName = userInfo.username || userInfo.name || '';
      this.loadPosts();
    } catch (e) {
      console.error('加载用户信息失败:', e);
    }
  }

  async loadPosts() {
    if (!this.baname) return;
    
    this.loading = true;
    try {
      const httpRequest = http.createHttp();
      
      const postResp = await httpRequest.request(
        `${BASE_URL}/api/post/listByBar?baname=${encodeURIComponent(this.baname)}&userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );
      
      let text = typeof postResp.result === "string"
        ? postResp.result
        : new util.TextDecoder("utf-8").decode(postResp.result as Uint8Array);
      
      const postData = JSON.parse(text) as PostListResponse;
      
      if (postData.success) {
        // 直接使用后端返回的数据，包含liked和favorited状态
        this.posts = await Promise.all(postData.posts.map(async (post: PostItem) => {
          // 检查是否关注了该用户
          let isFollowing = false;
          if (post.userId && post.userId !== this.userId) {
            try {
              const followResp = await http.createHttp().request(
                `${BASE_URL}/api/follow/check?followerId=${this.userId}&followingId=${post.userId}`,
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
          
          const newPost: PostItem = {
            id: post.id,
            baname: post.baname,
            user: post.user,
            userId: post.userId,  // ★ 添加userId字段用于编辑删除权限判断
            createTime: post.createTime,
            content: post.content,
            image: post.image,
            likes: post.likes,
            comments: post.comments,
            liked: post.liked || false,  // 使用后端返回的liked状态
            favorited: post.favorited || false,  // 使用后端返回的favorited状态
            isFollowing: isFollowing  // 添加关注状态
          };
          return newPost;
        }));
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error('加载帖子失败:', e);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.loading = false;
    }
  }

  async toggleLike(post: PostItem) {
    try {
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/like/toggleLike?userId=${this.userId}&postId=${Number(post.id)}`,
        { method: http.RequestMethod.POST }
      );
      
      const text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      const data = JSON.parse(text) as LikeResponse;
      
      if (data.success) {
        // 使用map()创建新的posts数组，更新指定帖子
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
      
      httpRequest.destroy();
    } catch (e) {
      console.error("点赞错误", e);
    }
  }

  async toggleFavorite(post: PostItem) {
    try {
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/favorite/toggle`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify({
            userId: this.userId,
            postId: Number(post.id)
          })
        }
      );
      
      const text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      const data = JSON.parse(text) as ToggleFavoriteResponse;
      
      if (data.success) {
        const newFavoritedState = !post.favorited;
        // 使用map()创建新的posts数组来触发UI更新
        this.posts = this.posts.map(p => {
          if (p.id === post.id) {
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
              favorited: newFavoritedState,
              isFollowing: p.isFollowing
            };
            return updatedPost;
          }
          return p;
        });
        promptAction.showToast({ 
          message: newFavoritedState ? '收藏成功 ★' : '已取消收藏 ☆' 
        });
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error("收藏错误", e);
      promptAction.showToast({ message: '收藏失败，请稍后再试' });
    }
  }

  async addFriend(friendName: string) {
    try {
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/friend/add`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify({
            userId: this.userId.toString(),
            friendId: friendName,
            friendName: friendName,
            friendAvatar: ''
          })
        }
      );
      
      const text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      const data = JSON.parse(text) as AddFriendResponse;
      
      if (data.success) {
        promptAction.showToast({ message: '添加好友成功' });
      } else {
        promptAction.showToast({ message: data.message || '添加好友失败' });
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error("添加好友错误", e);
      promptAction.showToast({ message: '添加好友失败' });
    }
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
        // 更新本地状态
        this.posts = this.posts.map(p => {
          if (p.id === post.id) {
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

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    
    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前';
    if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
    
    return `${date.getMonth() + 1}-${date.getDate()}`;
  }

  // 打开编辑对话框
  openEditDialog(post: PostItem) {
    this.editingPost = post;
    this.editContent = post.content;
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
        baname: this.baname
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
        await this.loadPosts();
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
        await this.loadPosts();
      } else {
        promptAction.showToast({ message: data.message || '删除失败' });
      }

      httpRequest.destroy();
    } catch (e) {
      console.error('删除帖子失败:', e);
      promptAction.showToast({ message: '网络错误' });
    }
  }

  // 打开评论面板
  openComment(post: PostItem) {
    this.currentPost = post;
    this.currentPostId = Number(post.id);
    this.showCommentPanel = true;
    this.fetchComments(post.id);
  }

  // 关闭评论面板
  closeComment() {
    this.showCommentPanel = false;
    this.commentInput = '';
    this.comments = [];
  }

  // 获取评论列表
  async fetchComments(postId: string): Promise<CommentItem[]> {
    const httpRequest = http.createHttp();
    
    try {
      const response = await httpRequest.request(
        `${BASE_URL}/api/comment/list?postId=${postId}&userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );

      const result = JSON.parse(response.result as string) as CommentListResponse;

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
        };
        return comment;
      });

      if (result.success) {
        return result.comments as CommentItem[];
      } else {
        return [];
      }
    } catch (err) {
      console.error('fetchComments error', err);
      return [];
    } finally {
      httpRequest.destroy();
    }
  }

  // 发送评论
  async sendComment() {
    const content = this.commentInput.trim();
    if (!content) return;

    const httpRequest = http.createHttp();

    await httpRequest.request(
      `${BASE_URL}/api/comment/add` +
        `?postId=${this.currentPostId}` +
        `&userId=${this.userId}` +
        `&content=${encodeURIComponent(content)}`,
      { method: http.RequestMethod.POST }
    );

    this.commentInput = '';
    this.commentInputController.stopEditing();
    this.fetchComments(String(this.currentPostId));
  }

  // 评论点赞
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

  // 删除评论
  async deleteComment(item: CommentItem) {
    try {
      // 显示确认对话框
      const result = await promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这条评论吗？',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#FF0000' }
        ]
      });

      if (result.index !== 1) return;
      
      const httpRequest = http.createHttp();
      
      const url = `${BASE_URL}/api/comment/delete?commentId=${item.id}&userId=${this.userId}`;
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.POST
      });

      const data = JSON.parse(resp.result as string) as BaseResponse;

      if (!data.success) {
        promptAction.showToast({ message: '删除失败: ' + (data.msg || '未知错误') });
        return;
      }

      this.comments = this.comments.filter(c => c.id !== item.id);
      promptAction.showToast({ message: '删除成功' });
    } catch (e) {
      console.error('删除评论失败', JSON.stringify(e));
      promptAction.showToast({ message: '删除失败，请重试' });
    }
  }

  @Builder
  CommentItemView(item: CommentItem) {
    Column() {
      Column({ space: 10 }) {
        Row({ space: 10 }) {
          Image(item.avatar ?? $r('app.media.head'))
            .width(40)
            .height(40)
            .borderRadius(20)

          Column({ space: 4 }) {
            Text(item.userName || '匿名用户')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            Text(this.formatTime(item.createTime))
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (item.isMine) {
            Text('删除')
              .fontColor('#ff6b6b')
              .fontSize(13)
              .onClick(() => this.deleteComment(item))
          }
        }
        .width('100%')

        Text(item.content)
          .fontSize(15)
          .lineHeight(22)
          .fontColor('#333333')
          .width('100%')

        Row({ space: 6 }) {
          Text(item.liked ? '❤' : '♡')
            .fontSize(18)
            .fontColor(item.liked ? '#ff6b6b' : '#999999')
          Text(item.likes?.toString() || '0')
            .fontSize(14)
            .fontColor('#999999')
        }
        .onClick(() => this.toggleCommentLike(item))
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    }
    .width('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  PostItemView(post: PostItem) {
    Column() {
      Row({ space: 12 }) {


        Image($r('app.media.head'))
          .width(40)
          .height(40)
          .borderRadius(20)
          .onClick(() => {
            if (post.user && post.user !== this.currentUserName) {
              this.selectedPostUser = post.user;
              this.showAddFriendDialog = true;
            }
          })

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(post.user || '未知用户')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            
            // 只在不是自己的帖子时显示关注按钮
            if (post.userId && post.userId !== this.userId) {
              Text(post.isFollowing ? '已关注' : '+ 关注')
                .fontSize(12)
                .fontColor(post.isFollowing ? '#999999' : '#007AFF')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .border({
                  width: 1,
                  color: post.isFollowing ? '#cccccc' : '#007AFF',
                  radius: 4
                })
                .backgroundColor(post.isFollowing ? '#f5f5f5' : Color.White)
                .onClick(() => this.toggleFollow(post))
            }
          }

          Text(this.formatTime(post.createTime))
            .fontSize(12)
            .fontColor('#999')
        }
        .alignItems(HorizontalAlign.Start)
        
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
          .padding({ right: 10 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      Text(post.content)
        .fontSize(15)
        .lineHeight(22)
        .padding({ left: 16, right: 16, top: 8 })
        .width('100%')
        .textAlign(TextAlign.Start)

      if (post.image) {
        Image(post.image)
          .width('90%')
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .margin({ top: 12, left: 16 })
      }

      Row({ space: 30 }) {
        Text(post.liked ? `❤️ 已点赞 ${post.likes}` : `👍 点赞 ${post.likes}`)
          .fontColor(post.liked ? '#ff6b6b' : '#666666')
          .fontSize(13)
          .onClick(() => this.toggleLike(post))

        Text(`💬 评论${post.comments}`)
          .fontColor('#666666')
          .fontSize(13)
          .onClick(() => this.openComment(post))

        Text(post.favorited ? `★ 已收藏` : `☆ 收藏`)
          .fontColor(post.favorited ? '#ffa500' : '#666666')
          .fontSize(13)
          .onClick(() => this.toggleFavorite(post))
          .hitTestBehavior(HitTestMode.Block)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ top: 8 })
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        Row() {
          Text('←')
            .fontSize(24)
            .fontColor(Color.White)
            .width(40)
            .onClick(() => {
              router.back();
            })

          Text(this.baname)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)

          Text('💬')
            .fontSize(24)
            .width(40)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/MessageListPage',
                params: {
                  userId: this.userId.toString(),
                  userName: this.currentUserName
                }
              });
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#00a6ff')
        .justifyContent(FlexAlign.SpaceBetween)

        // 帖子列表
        if (this.loading) {
          Column() {
            Text('加载中...')
              .fontSize(16)
              .fontColor('#999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.posts.length === 0) {
          Column() {
            Text('暂无帖子')
              .fontSize(16)
              .fontColor('#999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 0 }) {
            ForEach(this.posts, (post: PostItem) => {
              ListItem() {
                this.PostItemView(post)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#f5f5f5')
          .padding({ left: 8, right: 8 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')

      // 添加好友对话框
      if (this.showAddFriendDialog) {
        Column() {
          Column() {
            Text('添加好友')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 10 })
            
            Text(`确定要添加 ${this.selectedPostUser} 为好友吗?`)
              .fontSize(16)
              .fontColor('#666')
              .margin({ bottom: 20 })
            
            Row({ space: 12 }) {
              Button('取消')
                .backgroundColor('#E0E0E0')
                .fontColor('#333')
                .width(100)
                .onClick(() => {
                  this.showAddFriendDialog = false;
                })
              
              Button('确定')
                .backgroundColor('#4A90E2')
                .fontColor('#FFF')
                .width(100)
                .onClick(() => {
                  this.addFriend(this.selectedPostUser);
                  this.showAddFriendDialog = false;
                })
            }
            .margin({ bottom: 20 })
          }
          .width(280)
          .backgroundColor('#FFF')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.showAddFriendDialog = false;
        })
      }
      
      // 编辑帖子对话框
      if (this.showEditDialog) {
        Stack() {
          // 遮罩
          Rect()
            .fill('rgba(0, 0, 0, 0.5)')
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
      
      // 评论面板
      if (this.showCommentPanel) {
        Column() {
          // 顶部标题栏
          Row() {
            Text('×')
              .fontSize(28)
              .fontColor('#666')
              .onClick(() => this.closeComment())

            Text('评论')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)

            Text('    ')
              .fontSize(28)
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .borderWidth({ bottom: 1 })
          .borderColor('#eeeeee')

          // 评论列表
          if (this.comments.length === 0) {
            Column() {
              Text('暂无评论')
                .fontSize(14)
                .fontColor('#999')
            }
            .layoutWeight(1)
            .width('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            List({ space: 0 }) {
              ForEach(this.comments, (comment: CommentItem) => {
                ListItem() {
                  this.CommentItemView(comment)
                }
              }, (comment: CommentItem) => comment.id.toString())
            }
            .layoutWeight(1)
            .width('100%')
            .divider({
              strokeWidth: 1,
              color: '#f0f0f0'
            })
          }

          // 输入框
          Row({ space: 12 }) {
            TextInput({
              placeholder: '说点什么...',
              text: this.commentInput,
              controller: this.commentInputController
            })
              .layoutWeight(1)
              .height(40)
              .borderRadius(20)
              .backgroundColor('#f5f5f5')
              .padding({ left: 16, right: 16 })
              .onChange((value) => {
                this.commentInput = value;
              })

            Button('发送')
              .height(40)
              .borderRadius(20)
              .backgroundColor(this.commentInput.trim() ? '#007AFF' : '#CCCCCC')
              .fontColor(Color.White)
              .enabled(this.commentInput.trim().length > 0)
              .onClick(() => this.sendComment())
          }
          .width('100%')
          .padding(12)
          .backgroundColor(Color.White)
          .borderWidth({ top: 1 })
          .borderColor('#eeeeee')
        }
        .width('100%')
        .height('70%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .position({ y: '30%' })
      }
    }
    .width('100%')
    .height('100%')
  }
}
