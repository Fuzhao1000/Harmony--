import router from '@ohos.router';
import http from '@ohos.net.http';
import util from '@ohos.util';
import { BASE_URL } from '../pages/ip';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';

interface PostItem {
  id: string;
  baname: string;
  user?: string;
  userId?: number;
  createTime: number;
  content: string;
  image?: string;
  likes: number;
  comments: number;
  liked?: boolean;
  favorited?: boolean;
}

interface PostListResponse {
  success: boolean;
  posts: PostItem[];
}

interface FavoriteResponse {
  success: boolean;
  favoritePostIds: number[];
}

interface LikeListResponse {
  success: boolean;
  likedPostIds: number[];
}

interface LikeResponse {
  success: boolean;
  liked: boolean;
  likes: number;
}

interface ToggleFavoriteResponse {
  success: boolean;
}

@Entry
@Component
struct FavoritePostsPage {
  @State posts: PostItem[] = []
  @State loading: boolean = false
  @State userId: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.userId = params['userId'] as number || 0;
    this.loadFavoritePosts();
  }

  async loadFavoritePosts() {
    this.loading = true;
    
    try {
      const httpRequest = http.createHttp();

      // 1. 获取收藏的帖子列表
      const resp = await httpRequest.request(
        `${BASE_URL}/api/post/favList?userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );
      const favPostList = JSON.parse(resp.result as string) as PostListResponse;

      // 2. 获取收藏 id 列表
      const favResp = await httpRequest.request(
        `${BASE_URL}/api/favorite/list?userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );
      const favData = JSON.parse(favResp.result as string) as FavoriteResponse;
      const favSet = new Set(favData.favoritePostIds ?? []);

      // 3. 获取点赞列表
      const likeResp = await httpRequest.request(
        `${BASE_URL}/api/like/list?userId=${this.userId}`,
        { method: http.RequestMethod.GET }
      );
      const likeData = JSON.parse(likeResp.result as string) as LikeListResponse;
      const likedSet = new Set(likeData.likedPostIds ?? []);

      // 4. 组合数据
      this.posts = favPostList.posts.map((post) => {
        const p: PostItem = {
          id: post.id,
          user: post.user,
          userId: post.userId,
          content: post.content,
          baname: post.baname,
          createTime: post.createTime,
          image: post.image,
          likes: post.likes ?? 0,
          comments: post.comments ?? 0,
          liked: likedSet.has(Number(post.id)),
          favorited: favSet.has(Number(post.id))
        };
        return p;
      });

      httpRequest.destroy();
    } catch (err) {
      console.error("获取收藏帖子失败", err);
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

      const data = JSON.parse(resp.result as string) as LikeResponse;

      if (data.success) {
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

      const data = JSON.parse(resp.result as string) as ToggleFavoriteResponse;

      if (data.success) {
        const newFavoritedState = !post.favorited;
        
        if (!newFavoritedState) {
          // 取消收藏，从列表中移除
          this.posts = this.posts.filter(p => p.id !== post.id);
          promptAction.showToast({ message: '已取消收藏 ☆' });
        } else {
          // 重新收藏（理论上不应该发生）
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
                likes: p.likes,
                comments: p.comments,
                liked: p.liked,
                favorited: newFavoritedState
              };
              return newPost;
            }
            return p;
          });
          promptAction.showToast({ message: '收藏成功 ★' });
        }
      }

      httpRequest.destroy();
    } catch (e) {
      console.error("收藏错误", e);
      promptAction.showToast({ message: '收藏失败，请稍后再试' });
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

  @Builder
  PostItemView(post: PostItem) {
    Column() {
      // 帖子头部
      Row({ space: 12 }) {
        Image($r('app.media.head'))
          .width(40)
          .height(40)
          .borderRadius(20)

        Column({ space: 4 }) {
          Text(post.user || '未知用户')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)

          Text(this.formatTime(post.createTime))
            .fontSize(12)
            .fontColor('#999')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 吧名标签
        Text(post.baname)
          .fontSize(12)
          .fontColor('#007AFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E3F2FD')
          .borderRadius(4)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      // 帖子内容
      Text(post.content)
        .fontSize(15)
        .lineHeight(22)
        .padding({ left: 16, right: 16, top: 8 })
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 帖子图片
      if (post.image) {
        Image(post.image)
          .width('90%')
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .margin({ top: 12, left: 16 })
      }

      // 操作栏
      Row({ space: 30 }) {
        Text(post.liked ? `❤️ 已点赞 ${post.likes}` : `👍 点赞 ${post.likes}`)
          .fontColor(post.liked ? '#ff6b6b' : '#666666')
          .fontSize(13)
          .onClick(() => {
            this.toggleLike(post);
          })
          .hitTestBehavior(HitTestMode.Block)

        Text(`💬 评论${post.comments}`)
          .fontColor('#666666')
          .fontSize(13)
          .onClick(() => {
            // 跳转到帖子详情页查看评论
            router.pushUrl({
              url: 'pages/PostDetailPage',
              params: {
                post: post
              }
            });
          })
          .hitTestBehavior(HitTestMode.Block)

        Text(post.favorited ? `★ 已收藏` : `☆ 收藏`)
          .fontColor(post.favorited ? '#ffa500' : '#666666')
          .fontSize(13)
          .onClick(() => {
            this.toggleFavorite(post);
          })
          .hitTestBehavior(HitTestMode.Block)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ top: 8 })
    .onClick(() => {
      // 点击帖子跳转到详情页
      router.pushUrl({
        url: 'pages/PostDetailPage',
        params: {
          post: post
        }
      });
    })
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

        Text('我的收藏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)

        Text('')
          .width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#00a6ff')
      .justifyContent(FlexAlign.SpaceBetween)

      // 列表内容
      if (this.loading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.posts.length === 0) {
        Column() {
          Text('暂无收藏')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
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
  }
}
