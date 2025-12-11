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

interface PostItem {
  id:string
  baname:string
  user: string
  createTime: number
  content: string
  image?: string
  likes: number
  comments: number
  liked?: boolean;
  favorited?: boolean;
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

interface UserInfoResponse {
  success: boolean;
  name: string;
  // 如果还有其他字段也一起加上
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
  @State favoritePosts: PostItem[] = [];

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
      posts: 1,
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

        // 更新头像显示
        this.headImage = uri;
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
        this.selectedImage = uri;
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

    if (!userId) {
      console.error("未登录或用户ID丢失");
      this.loading = false;
      return;
    }

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        `http://10.205.218.246:8080/api/user/${userId}`,
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

  generatePostId(): string {
    return Date.now().toString();
  }

  async toggleLike(post: PostItem) {
    try {
      const httpRequest = http.createHttp();
      const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const userInfo = await loadUserInfo(currentContext);
      const userId: number = parseInt(userInfo.id, 10) || 0;

      const resp = await httpRequest.request(
        `http://10.205.218.246:8080/api/like/toggleLike?userId=${userId}&postId=${Number(post.id)}`,
        {
          method: http.RequestMethod.POST
        }
      );


      const data = JSON.parse(resp.result as string) as LikeResponse;


        post.liked = data.liked;
        post.likes = data.likes;

      await this.fetchPosts()
    } catch (e) {
      console.error("点赞错误", e);
    }
  }


  async onPublishClick() {
    try {

      const postData: PostItem = {
        id: this.generatePostId(),
        user: this.userName,
        content: this.content,
        baname: this.selectedBa,
        createTime: Date.now(),
        image: this.selectedImage,
        likes:0,
        comments:0
      };

      console.log("提交数据：", JSON.stringify(postData));

      // 3. 发送 POST 请求
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        'http://10.205.218.246:8080/api/post/publish',
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

      } else {
        console.error('发布失败',  JSON.stringify(response));
        Prompt.showToast({ message: "发布失败" });
      }

    } catch (err) {
      console.error("发布出错：", JSON.stringify(err));
      Prompt.showToast({ message: "网络错误" });
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
        `http://10.205.218.246:8080/api/post/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const postData = JSON.parse(postResp.result as string) as PostListResponse;

      if (!postData.success) return;

      // 3. 获取当前用户收藏列表
      const favResp = await httpRequest.request(
        `http://10.205.218.246:8080/api/favorite/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );


      const favData = JSON.parse(favResp.result as string) as FavoriteResponse;

      const favSet = new Set(favData.favoritePostIds ?? []);

      const likeResp = await httpRequest.request(
        `http://10.205.218.246:8080/api/like/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const likeData = JSON.parse(likeResp.result as string) as LikeListResponse;

      const likedSet = new Set(likeData.likedPostIds ?? []);


      // 4. 生成前端需要的 PostItem 数组，并标记 favorited
      this.posts = postData.posts.map((post) => {
        const p: PostItem = {
          id: post.id,
          user: post.user,
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

     // console.log("加载帖子成功：", JSON.stringify(this.posts, null, 2));
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
        `http://10.205.218.246:8080/api/post/favList?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const favPostList = JSON.parse(resp.result as string) as PostListResponse;

      // 2. 获取收藏 id 列表（favSet）
      const favResp = await httpRequest.request(
        `http://10.205.218.246:8080/api/favorite/list?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );
      const favData = JSON.parse(favResp.result as string)as FavoriteResponse;
      const favSet = new Set(favData.favoritePostIds ?? []);

      // 3. 生成收藏贴列表并加上 favorited=true
      this.favoritePosts= favPostList.posts.map((post) => {
        const p: PostItem = {
          id: post.id,
          user: post.user,
          content: post.content,
          baname: post.baname,
          createTime: post.createTime,
          image: post.image,
          likes: post.likes ?? 0,
          comments: post.comments ?? 0,
          liked: false,
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

  async toggleFavorite(post: PostItem) {
    const httpRequest = http.createHttp();
    const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const userInfo = await loadUserInfo(currentContext);
    const userId: number = parseInt(userInfo.id, 10) || 0;

    try {
      const response = await httpRequest.request(
        'http://10.205.218.246:8080/api/favorite/toggle',
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
          message: post.favorited ? '收藏成功 ❤️' : '已取消收藏 ♡'
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

  aboutToAppear() {
    this.loadUserNameFromDB();
    this.fetchPosts();
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

            Text("在此输入")
              .fontColor('#AAAAAA')
              .fontSize(16)

            Text("搜索")
              .fontColor('#007AFF')
              .fontSize(16)
              .margin({ right: 10 })
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

            Scroll() {
              Column({ space: 16 }) {
                ForEach(this.posts, (post: PostItem) => {
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

                      Text(post.favorited ? `♥ 已收藏` : `♡ 收藏`)
                        .fontColor(post.favorited ? Color.Red : '#666666')
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
                        .fontSize(13);

                      Text('↗ 分享')
                        .fontColor('#666666')
                        .fontSize(13);
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
        else if (this.currentTab === 'profile') {
          Column() {

            Column() {
              if (this.isEditing){
                Row({ space: 10 }) {  // 水平并排，间距 10
                  Image($r(this.headImage))  // 显示当前头像（不再有 onClick）
                    .width(100)
                    .height(100)
                    .borderRadius(50)

                  Button("修改头像")  // 新按钮
                    .width(80)
                    .height(40)
                    .borderRadius(8)
                    .fontSize(10)
                    .fontColor(Color.White)
                    .backgroundColor("#007AFF")  // 蓝色背景，可自定义
                    .onClick(async () => {
                      await this.pickImageFromGallery();  // 点击调用选择函数
                    })
                }
                .margin({ top: -190 })  // 整体上移
              }
              else
              {
                Image($r('app.media.head'))  // 头像资源
                  .width(100)
                  .height(100)
                  .borderRadius(50)  // 圆形
                  .margin({ top: -190 })
              }
              if (this.isEditing) {
                TextInput()

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
                       "http://10.205.218.246:8080/api/updateName",
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
                  Text("0").fontSize(18).fontColor(Color.Black)
                }

                Column() {
                  Text("粉丝").fontSize(16).fontColor(Color.Gray)
                  Text("0").fontSize(18).fontColor(Color.Black)
                }

                Column() {
                  Button("收藏").fontSize(16).fontColor(Color.White).onClick(() => {
                    this.currentTab = "favorite";
                    this.fetchFavoritePosts();
                  })
                  Text("0").fontSize(18).fontColor(Color.Black)

                }
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
              .margin({ top: 10, bottom: 10 })

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

                    // 跳转到吧详情页逻辑
                  })
                })
              }
              .padding({ top: 10, left: 16, right: 16, bottom: 16 })
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

                        Text(post.favorited ? `♥ 已收藏` : `♡ 收藏`)
                          .fontColor(post.favorited ? Color.Red : '#666666')
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
                        Text(`👍 点赞${post.likes}`)
                          .fontColor('#666666')
                          .fontSize(13)
                          .onClick(() => this.toggleLike(post));

                        Text(`💬 评论${post.comments}`)
                          .fontColor('#666666')
                          .fontSize(13);

                        Text('↗ 分享')
                          .fontColor('#666666')
                          .fontSize(13);
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
      .alignItems(HorizontalAlign.Center)

      Row() {
        Column() {
          Text("首页").fontSize(27).fontColor(this.currentTab === 'home' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'home'
              this.fetchPosts()
            })
        }

        Column() {
          Text("进吧").fontSize(27).fontColor(this.currentTab === 'forum' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'forum'
            })
        }

        Column() {
          Text("发布").fontSize(27).fontColor(this.currentTab === 'post' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'post'
            })
        }

        Column() {
          Text("消息").fontSize(27).fontColor(this.currentTab === 'message' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'massage'
            })
        }

        Column() {
          Text("我的").fontSize(27).fontColor(this.currentTab === 'profile' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'profile'
            })
        }
      }
      .width('100%')
      .height(70)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({top:850})
    }
    .width('100%')
    .height('80%')

  }

}

