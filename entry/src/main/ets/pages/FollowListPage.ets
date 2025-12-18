import router from '@ohos.router';
import http from '@ohos.net.http';
import util from '@ohos.util';
import { BASE_URL } from '../pages/ip';
import promptAction from '@ohos.promptAction';

interface UserItem {
  id: number;
  name: string;
  followingCount: number;
  followerCount: number;
  isFollowing?: boolean;
}

interface FollowListResponse {
  success: boolean;
  users: UserItem[];
  message?: string;
}

interface FollowResponse {
  success: boolean;
  isFollowing: boolean;
  message: string;
}

interface FollowCheckResponse {
  success: boolean;
  isFollowing: boolean;
}

@Entry
@Component
struct FollowListPage {
  @State listType: string = 'following' // 'following' 或 'follower'
  @State pageTitle: string = '关注列表'
  @State users: UserItem[] = []
  @State loading: boolean = false
  @State currentUserId: number = 0
  @State targetUserId: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.listType = params['type'] as string || 'following';
    this.currentUserId = params['currentUserId'] as number || 0;
    this.targetUserId = params['targetUserId'] as number || this.currentUserId;
    this.pageTitle = this.listType === 'following' ? '关注列表' : '粉丝列表';
    
    this.loadUserList();
  }

  async loadUserList() {
    this.loading = true;
    
    try {
      const httpRequest = http.createHttp();
      const endpoint = this.listType === 'following' 
        ? `/api/follow/following-list?userId=${this.targetUserId}`
        : `/api/follow/follower-list?userId=${this.targetUserId}`;
      
      const response = await httpRequest.request(
        `${BASE_URL}${endpoint}`,
        { method: http.RequestMethod.GET }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as FollowListResponse;

      if (data.success) {
        // 为每个用户检查关注状态
        this.users = await Promise.all(data.users.map(async (user) => {
          let isFollowing = false;
          
          // 只有当查看的是别人的列表且不是自己时才检查关注状态
          if (user.id !== this.currentUserId) {
            try {
              const followResp = await http.createHttp().request(
                `${BASE_URL}/api/follow/check?followerId=${this.currentUserId}&followingId=${user.id}`,
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

          const userWithFollow: UserItem = {
            id: user.id,
            name: user.name,
            followingCount: user.followingCount,
            followerCount: user.followerCount,
            isFollowing: isFollowing
          };
          return userWithFollow;
        }));
      } else {
        promptAction.showToast({ message: data.message || '加载失败' });
      }

      httpRequest.destroy();
    } catch (e) {
      console.error('加载列表失败:', e);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.loading = false;
    }
  }

  async toggleFollow(user: UserItem) {
    if (user.id === this.currentUserId) {
      return; // 不能关注自己
    }

    try {
      const httpRequest = http.createHttp();
      
      const resp = await httpRequest.request(
        `${BASE_URL}/api/follow/toggle?followerId=${this.currentUserId}&followingId=${user.id}`,
        { method: http.RequestMethod.POST }
      );
      
      const text = typeof resp.result === "string"
        ? resp.result
        : new util.TextDecoder("utf-8").decode(resp.result as Uint8Array);
      
      const data = JSON.parse(text) as FollowResponse;
      
      if (data.success) {
        // 更新本地状态
        this.users = this.users.map(u => {
          if (u.id === user.id) {
            // 更新粉丝数：关注时+1，取消关注时-1
            const newFollowerCount = data.isFollowing 
              ? u.followerCount + 1 
              : Math.max(0, u.followerCount - 1);
            
            const updatedUser: UserItem = {
              id: u.id,
              name: u.name,
              followingCount: u.followingCount,
              followerCount: newFollowerCount,
              isFollowing: data.isFollowing
            };
            return updatedUser;
          }
          return u;
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

  @Builder
  UserItemView(user: UserItem) {
    Row() {
      // 头像
      Image($r('app.media.head'))
        .width(50)
        .height(50)
        .borderRadius(25)
        .margin({ right: 12 })

      // 用户信息
      Column({ space: 4 }) {
        Text(user.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Row({ space: 16 }) {
          Text(`关注 ${user.followingCount}`)
            .fontSize(13)
            .fontColor('#999999')
          
          Text(`粉丝 ${user.followerCount}`)
            .fontSize(13)
            .fontColor('#999999')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 关注按钮（自己不显示）
      if (user.id !== this.currentUserId) {
        Text(user.isFollowing ? '已关注' : '+ 关注')
          .fontSize(13)
          .fontColor(user.isFollowing ? '#999999' : '#007AFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .border({
            width: 1,
            color: user.isFollowing ? '#cccccc' : '#007AFF',
            radius: 4
          })
          .backgroundColor(user.isFollowing ? '#f5f5f5' : Color.White)
          .onClick(() => this.toggleFollow(user))
      }
    }
    .width('100%')
    .padding(16)
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

        Text(this.pageTitle)
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
      } else if (this.users.length === 0) {
        Column() {
          Text(this.listType === 'following' ? '暂无关注' : '暂无粉丝')
            .fontSize(16)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 1 }) {
          ForEach(this.users, (user: UserItem) => {
            ListItem() {
              this.UserItemView(user)
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
}
