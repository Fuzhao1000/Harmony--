import router from '@ohos.router';


@Entry
@Component
struct WelcomePage {

  // 页面初始化生命周期
  onInit() {
    // 延迟 3 秒跳转到注册页面
    setTimeout(() => {
      router.push({url:'pages/RegisterPage'})
    }, 3000)
  }

  build() {

    Column({ space: 30 }) {

      Image($r('app.media.logo'))
        .objectFit(ImageFit.Cover)
        .width('45%')
        .height('25%')

      Text('百度贴吧').fontSize(32).fontWeight('bold')

      Button("进入百度贴吧")
        .width(200)
        .height(50)
        .borderRadius(25)           // 圆角
        .fontColor(Color.White)     // 白字
        .backgroundColor("#007AFF") // 蓝底
        .onClick(() => {
          router.push({ url: "pages/RegisterPage" }) // 跳转注册页
        })
    }

    .margin({ top: 200,left: 80 })


  }
}