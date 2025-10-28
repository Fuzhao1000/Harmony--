import router from '@ohos.router';
import file from '@ohos.file.picker';
import * as picker from '@ohos.file.picker';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { BusinessError } from '@ohos.base';
import image from '@ohos.multimedia.image';

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

@Entry
@Component
struct HomePage {
  @State currentTab: string = 'home';
  @State isEditing: boolean = false;
  @State userName:string = '';
  @State headImage:string ='app.media.head';
  @State likesClicked: boolean = false;
  @StorageLink('posts') posts: PostItem[] = []

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

  addPost() {
    const newPost: PostItem = {
      baname:'浙江农林大学吧',

      user: `用户${this.posts.length + 1}`,
      time: '刚刚',
      content: `这是第${this.posts.length + 1}条帖子（来自 StorageLink）`,
      image: 'app.media.bj2',
      likes: 0,
      comments: 0
    }
    // 在数组头部插入
    this.posts.unshift(newPost)

    try {
      PersistentStorage.persistProp('posts',[])
    } catch (e) {
      console.warn('PersistentStorage.persistProp 失败：', e)
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
            Text("个人信息").fontSize(27).fontColor(Color.Black).margin({top:-20})
            Column() {
              if (this.isEditing){
                Image($r(this.headImage))
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .margin({ top: -190 })
                  .onClick(() => {
                    if (this.isEditing) {
                      this.pickImageFromGallery()
//不会做相册选择图片

                    }
                  })
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
                .onClick(() => {
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


            Row() {
              Column() {
                Text("首页").fontSize(27).fontColor(Color.Black)
                  .onClick(() => {
                    this.currentTab = 'home'
                  })
              }

              Column() {
                Text("进吧").fontSize(27).fontColor(Color.Black)
                  .onClick(() => {
                    this.currentTab = 'forum'
                  })
              }

              Column() {
                Text("发布").fontSize(27).fontColor(Color.Black)
              }

              Column() {
                Text("消息").fontSize(27).fontColor(Color.Black)
              }

              Column() {
                Text("我的").fontSize(27).fontColor(Color.Blue)
                  .onClick(() => {
                    this.currentTab = 'profile'
                  })
              }
            }
            .width('100%')
            .height(75)
            .backgroundColor('#F5F5F5')
            .justifyContent(FlexAlign.SpaceAround)

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
                  .width('92%') // 👈 一行一个吧，整体更宽
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


            // 底部导航栏
            Row() {
              Column() { Text("首页").fontSize(27).fontColor(Color.Black)
                .onClick(() => this.currentTab = 'home')
              }
              Column() { Text("进吧").fontSize(27).fontColor(Color.Blue)
                .onClick(() => this.currentTab = 'forum')
              }
              Column() { Text("发布").fontSize(27).fontColor(Color.Black) }
              Column() { Text("消息").fontSize(27).fontColor(Color.Black) }
              Column() { Text("我的").fontSize(27).fontColor(Color.Black)
                .onClick(() => this.currentTab = 'profile')
              }
            }
            .width('100%')
            .height(60)
            .backgroundColor('#F5F5F5')
            .justifyContent(FlexAlign.SpaceAround)
            .alignItems(VerticalAlign.Center)
            .margin({top:75})
          }
        }

        if (this.currentTab === 'home')
          Row() {
            Column() {
              Text("首页").fontSize(27).fontColor(Color.Blue)
                .onClick(() => {
                  this.currentTab = 'home'
                })
            }

            Column() {
              Text("进吧").fontSize(27).fontColor(Color.Black)
                .onClick(() => {
                  this.currentTab = 'forum'
                })
            }

            Column() {
              Text("发布").fontSize(27).fontColor(Color.Black)
            }

            Column() {
              Text("消息").fontSize(27).fontColor(Color.Black)
            }

            Column() {
              Text("我的").fontSize(27).fontColor(Color.Black)
                .onClick(() => {
                  this.currentTab = 'profile'
                })
            }
          }
          .width('100%')
          .height(51)
          .backgroundColor('#F5F5F5')

          .justifyContent(FlexAlign.SpaceAround)
          .padding({ top: -30 })

      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('80%')

  }

}

