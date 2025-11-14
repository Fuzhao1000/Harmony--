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

import fs from '@ohos.file.fs';

interface PostItem {
  baname:string
  user: string
  time: string
  content: string
  image?: string
  likes: number
  comments: number
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

  aboutToAppear() {
    if (!this.posts || this.posts.length === 0) {
      this.posts = [
        { baname:'浙江农林大学吧', user: '用户1', time: '1小时前', content: '这是第一条帖子内容。', image: 'app.media.bj2', likes: 0, comments: 0 },
        { baname:'明日方舟吧', user: '用户2', time: '2小时前', content: '今天心情不错～', image: '', likes: 0, comments: 0 },
        { baname:'bilibili吧', user: '用户2', time: '3小时前', content: '有人吗', image: 'app.media.tutu', likes: 0, comments: 0 },
      ]

      try {
        PersistentStorage.persistProp('posts',[])
      } catch (e) {
        console.warn('PersistentStorage.persistProp 可能在当前环境不可用：', e)
      }
    }
  }

 async  publishPost(
  baname: string,
  user: string,
  content: string,
  image?: string
): Promise<PostItem | null> {
  const httpRequest = http.createHttp();

  try {

    // 发送 POST 请求
    const response = await httpRequest.request(
      'http://10.205.218.246:8080/posts',
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ baname, user, content, image })
      }
    );

    // 解析响应
    const text =
      typeof response.result === 'string'
        ? response.result
        : new util.TextDecoder('utf-8').decode(response.result as Uint8Array);

    const data = JSON.parse(text) as PostItem;

    return data;
  } catch (e) {
    console.error('发帖失败', e);
    return null;
  } finally {
    httpRequest.destroy();
  }
}

  async onPublishClick() {
    if (!this.selectedBa || this.content.length === 0) return;

    const newPost = await this.publishPost(
      this.selectedBa,
      this.userName,
      this.content,
      this.selectedImage // 可选
    );

    if (newPost) {
      this.posts.push(newPost);

      // 清空状态
      this.content = '';
      this.selectedBa = '';
      this.selectedImage = '';
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
        `http://10.205.218.246:8080/api/user/${userId}`,  // GET 用户名端点
        {
          method: http.RequestMethod.GET,
          header: { "Content-Type": "application/json" }
          // 如果需要认证，加 token header
        }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as { success: boolean; name: string };
      if (data.success) {
        this.userName = data.name || "默认用户";
        await saveUserName(this.userName, this.getUIContext().getHostContext() as common.UIAbilityContext);  // 同步本地
      } else {
        this.userName = "默认用户";
      }
      console.log("加载用户名结果:", text);
    } catch (e) {
      console.error('加载用户名失败:', e);
      this.userName = "默认用户";
    } finally {
      httpRequest.destroy();
      this.loading = false;
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
        // 顶部搜索框
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
                // 用 StorageLink 绑定的 this.posts 来渲染
                ForEach(this.posts, (post: PostItem) => {
                  Column() {
                    // 帖子头部
                    Row({ space: 10 }) {

                        Image(this.forums.find(b => b.baname === post.baname)?.icon)
                          .width(40)
                          .height(40)
                          .borderRadius(20)

                          .margin({ right: 10 })

                        Text(post.baname)
                          .fontSize(16)
                          .fontColor(Color.Black)
                          .fontWeight(FontWeight.Medium)
                          .margin({
                            top: 8,
                            bottom: 8,
                            right: 15,
                            left: -8
                          })

                    }

                    Row({ space: 2 }) {
                      Image($r('app.media.head'))
                        .width(40)
                        .height(40)
                        .borderRadius(20)
                        .backgroundColor('#CCCCCC')

                      Column({ space: 2 }) {
                        Text(post.user).fontSize(15).fontWeight(FontWeight.Medium).fontColor(Color.Black)
                        Text(post.time).fontSize(12).fontColor('#999999')
                      }.alignItems(HorizontalAlign.Start)
                    }
                    // 内容
                    Text(post.content)
                      .fontSize(14)
                      .fontColor(Color.Black)
                      .margin({ top: 8, bottom: 8 })

                    // 图片（有的话显示）
                    Image($r(post.image ?? null))
                        .width('100%')
                        .height(post.image ? 180 : 0)
                        .borderRadius(12)
                        .objectFit(ImageFit.Cover)


                    // 操作栏
                    Row({ space: 75 }) {

                      Text(this.likesClicked ? `👍 点赞${post.likes}` : `👍 点赞${post.likes}`)
                        .fontColor('#666666')
                        .fontSize(13)
                        .onClick(() => {
                          if(!this.likesClicked) // 切换状态
                          {
                            post.likes+=1
                            this.likesClicked=!this.likesClicked
                          }
                          else{
                            post.likes-=1
                            this.likesClicked=!this.likesClicked
                          }

                        })
                      Text(`💬 评论${post.comments}`).fontColor('#666666').fontSize(13)
                      Text('↗ 分享').fontColor('#666666').fontSize(13)
                    }.margin({ top: 8 })
                  }
                  .padding(12)
                  .backgroundColor('#F9F9F9')
                  .borderRadius(16)
                  .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 2 })

                  .alignItems(HorizontalAlign.Start)
                })
              }
              .width('100%')
              .padding({ top: 10, bottom: 20 })
            }
            .width('95%')
            .height('100%')
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



              // 4️⃣ 蓝框白字“编辑”按钮
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
              }
              .margin({ top: 10 })
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




      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row() {
        Column() {
          Text("首页").fontSize(27).fontColor(this.currentTab === 'home' ? '#007AFF' : Color.Black)
            .onClick(() => {
              this.currentTab = 'home'
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

