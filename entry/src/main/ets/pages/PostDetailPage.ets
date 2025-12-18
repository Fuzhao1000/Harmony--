import router from '@ohos.router';
import http from '@ohos.net.http';
import util from '@ohos.util';
import { BASE_URL } from '../pages/ip';
import { loadUserInfo, UserInfo } from '../pages/LoginPage';
import { common } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';

interface PostItem {
  id: string
  user?: string
  userId?: number
  createTime: number
  content: string
  image?: string
  likes: number
  comments: number
  liked?: boolean
  favorited?: boolean
}

interface CommentItem {
  id: number
  userId: number
  userName: string
  content: string
  createTime: number
  likes?: number
  liked?: boolean
}

interface ApiResponse<T = any> {
  success: boolean
  message?: string
  data?: T
}

interface LikeData {
  liked: boolean
  likes: number
}

@Entry
@Component
struct PostDetailPage {
  @State post: PostItem | null = null
  @State comments: CommentItem[] = []
  @State loading: boolean = false
  @State userId: number = 0
  @State currentUserName: string = ''
  @State newComment: string = ''
  private commentInputController: TextInputController = new TextInputController()

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.post = params['post'] as PostItem;
    console.log('帖子详情:', JSON.stringify(this.post));
    this.loadUserAndComments();
  }

  async loadUserAndComments() {
    try {
      const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const userInfo = await loadUserInfo(currentContext) as UserInfo;
      this.userId = parseInt(userInfo.id, 10) || 0;
      this.currentUserName = userInfo.username || userInfo.name || '';
      this.loadComments();
    } catch (e) {
      console.error('加载用户信息失败:', e);
    }
  }

  async loadComments() {
    if (!this.post) return;
    
    this.loading = true;
    try {
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/comment/list?postId=${this.post.id}&userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );
      
      let text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      const data = JSON.parse(text) as ApiResponse;
      
      console.log('评论数据:', JSON.stringify(data));
      
      if (data.success && data.data) {
        this.comments = data.data as CommentItem[];
        console.log('评论数量:', this.comments.length);
        if (this.comments.length > 0) {
          console.log('第一条评论:', JSON.stringify(this.comments[0]));
        }
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error('加载评论失败:', e);
    } finally {
      this.loading = false;
    }
  }

  async toggleCommentLike(comment: CommentItem) {
    try {
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/comment/toggleLike?userId=${this.userId}&commentId=${comment.id}`,
        { method: http.RequestMethod.POST }
      );
      
      const text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      const data = JSON.parse(text) as ApiResponse<LikeData>;
      
      if (data.success && data.data) {
        comment.liked = data.data.liked;
        comment.likes = data.data.likes;
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error("评论点赞错误", e);
    }
  }

  async addComment() {
    if (!this.newComment.trim() || !this.post) {
      promptAction.showToast({ message: '请输入评论内容' });
      return;
    }

    console.log('准备发送评论...');
    console.log('postId:', this.post.id);
    console.log('userId:', this.userId);
    console.log('content:', this.newComment.trim());

    try {
      const httpRequest = http.createHttp();
      
      const url = `${BASE_URL}/api/comment/add`
        + `?postId=${this.post.id}`
        + `&userId=${this.userId}`
        + `&content=${encodeURIComponent(this.newComment.trim())}`;
      
      console.log('请求URL:', url);
      
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.POST
      });
      
      console.log('响应状态:', resp.responseCode);
      
      const text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      console.log('响应数据:', text);
      
      const data = JSON.parse(text) as ApiResponse;
      
      if (data.success) {
        promptAction.showToast({ message: '评论成功' });
        this.newComment = '';
        // 让输入框失去焦点，键盘消失
        this.commentInputController.stopEditing();
        this.loadComments();
        if (this.post) {
          this.post.comments = this.post.comments + 1;
        }
      } else {
        promptAction.showToast({ message: data.message || '评论失败' });
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error('评论失败:', JSON.stringify(e));
      promptAction.showToast({ message: '评论失败: ' + e });
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    
    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前';
    if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
    if (diff < 604800000) return Math.floor(diff / 86400000) + '天前';
    
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }

  @Builder
  CommentItemView(comment: CommentItem) {
    Column() {
      Column({ space: 10 }) {
        // 用户信息行
        Row({ space: 10 }) {
          // 头像
          Image($r('app.media.head'))
            .width(40)
            .height(40)
            .borderRadius(20)

          Column({ space: 4 }) {
            // 用户名
            Text(comment.userName || '匿名用户')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            // 评论时间
            Text(this.formatTime(comment.createTime))
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        // 评论内容
        Text(comment.content)
          .fontSize(15)
          .lineHeight(22)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 50 })

        // 点赞
        Row({ space: 6 }) {
          Text(comment.liked ? '❤' : '♡')
            .fontSize(16)
            .fontColor(comment.liked ? '#ff6b6b' : '#999')
          Text((comment.likes || 0).toString())
            .fontSize(13)
            .fontColor(comment.liked ? '#ff6b6b' : '#999')
        }
        .padding({ left: 50 })
        .onClick(() => this.toggleCommentLike(comment))
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

  build() {
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

        Text('帖子详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#00a6ff')
      .justifyContent(FlexAlign.SpaceBetween)

      // 内容区域
      Column() {
        // 帖子内容
        if (this.post) {
          Column() {
            Row({ space: 12 }) {
              Image($r('app.media.head'))
                .width(40)
                .height(40)
                .borderRadius(20)

              Column({ space: 4 }) {
                Text(this.post.user || '未知用户')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)

                Text(this.formatTime(this.post.createTime))
                  .fontSize(12)
                  .fontColor('#999')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12 })

            Text(this.post.content)
              .fontSize(15)
              .lineHeight(22)
              .padding({ left: 16, right: 16, top: 8 })

            if (this.post.image) {
              Image(this.post.image)
                .width('90%')
                .height(200)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
                .margin({ top: 12, left: 16 })
            }

            Row({ space: 30 }) {
              Row({ space: 6 }) {
                Text(this.post.liked ? '❤' : '♡')
                  .fontSize(20)
                  .fontColor(this.post.liked ? '#ff6b6b' : '#666')
                Text(this.post.likes.toString())
                  .fontSize(14)
                  .fontColor(this.post.liked ? '#ff6b6b' : '#666')
              }

              Row({ space: 6 }) {
                Text('💬')
                  .fontSize(20)
                Text(this.post.comments.toString())
                  .fontSize(14)
                  .fontColor('#666')
              }

              Row({ space: 6 }) {
                Text(this.post.favorited ? '★' : '☆')
                  .fontSize(20)
                  .fontColor(this.post.favorited ? '#ffa500' : '#666')
                Text(this.post.favorited ? '已收藏' : '收藏')
                  .fontSize(14)
                  .fontColor(this.post.favorited ? '#ffa500' : '#666')
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ bottom: 12 })
        }

        // 评论区标题
        Row() {
          Text(`评论 (${this.comments.length})`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#f5f5f5')

        // 评论列表 - 可滚动
        if (this.loading) {
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999')
          }
          .width('100%')
          .height(200)
          .backgroundColor(Color.White)
          .justifyContent(FlexAlign.Center)
        } else if (this.comments.length === 0) {
          Column() {
            Text('暂无评论，快来抢沙发吧~')
              .fontSize(14)
              .fontColor('#999')
          }
          .width('100%')
          .height(150)
          .backgroundColor(Color.White)
          .justifyContent(FlexAlign.Center)
        } else {
          Column() {
            List({ space: 0 }) {
              ForEach(this.comments, (comment: CommentItem) => {
                ListItem() {
                  this.CommentItemView(comment)
                }
              }, (comment: CommentItem) => comment.id.toString())
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(Color.White)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#f5f5f5')

      // 底部评论输入框
      Row({ space: 12 }) {
        TextInput({ placeholder: '写下你的评论...', text: this.newComment, controller: this.commentInputController })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#f0f0f0')
          .borderRadius(20)
          .onChange((value: string) => {
            this.newComment = value;
          })

        Button('发送')
          .height(40)
          .fontSize(14)
          .backgroundColor('#00a6ff')
          .fontColor(Color.White)
          .onClick(() => {
            this.addComment();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(Color.White)
      .shadow({ radius: 4, color: '#00000020', offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
