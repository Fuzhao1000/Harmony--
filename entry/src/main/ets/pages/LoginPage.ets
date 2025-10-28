// entry/src/main/ets/pages/LoginPage.ets
import { checkUser } from '../common/UserStorage';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

@Entry
@Component
struct LoginPage {
  @State username: string = ""
  @State password: string = ""
  @State errorMsg: string = ""

  // 表单是否有效
  isFormValid(): boolean {
    return (
      this.username.length === 11 &&
      /^[0-9]{11}$/.test(this.username) &&
        this.password.length > 0
    )
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景图
      Image($r('app.media.bj1'))
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('120%')

      // 中心白框
      Column({ space: 25 }) {
        Text("欢迎登录百度账号")
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 40 })

        // 手机号输入框
        TextInput({ placeholder: "请输入手机号" })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .backgroundColor("#F5F5F5")
          .fontColor(Color.Black)
          .borderRadius(10)
          .padding(15)
          .width('80%')
          .textAlign(TextAlign.Center)
          .onChange((v) => {
            this.username = v.replace(/\D/g, "");
          });

        // 密码输入框
        TextInput({ placeholder: "请输入密码" })
          .type(InputType.Password)
          .backgroundColor("#F5F5F5")
          .fontColor(Color.Black)
          .borderRadius(10)
          .padding(15)
          .width('80%')
          .textAlign(TextAlign.Center)
          .onChange((v) => {
            this.password = v;
          });

        // 错误提示
        if (this.errorMsg !== "") {
          Text(this.errorMsg)
            .fontColor(Color.Red)
            .fontSize(14)
        }

        // 登录按钮
        Button("登录")
          .width("80%")
          .height(48)
          .borderRadius(12)
          .fontColor("#FFFFFF")
          .backgroundColor(this.isFormValid() ? "#007AFF" : "#ADD8E6")
          .onClick(async () => {
            if (!this.isFormValid()) {
              this.errorMsg = "请输入正确的手机号和密码";
              return;
            }
            const ctx = getContext(this) as common.Context
            const ok = await checkUser(ctx, this.username, this.password)
            if (ok) {
              router.pushUrl({ url: "pages/HomePage" })
            } else {
              this.errorMsg = "手机号或密码错误"
            }
          });

        // 去注册按钮
        Button("去注册")
          .width("80%")
          .height(40)
          .borderRadius(12)
          .fontColor("#007AFF")
          .backgroundColor("#F0F8FF")
          .onClick(() => {
            router.pushUrl({ url: "pages/RegisterPage" })
          })
      }
      .backgroundColor(Color.White)
      .borderRadius(20)
      .padding(20)
      .width('85%')
    }
    .width('100%')
    .height('100%')
  }
}
