// entry/src/main/ets/pages/RegisterPage.ets
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { saveUser } from '../common/UserStorage'; // 按你项目的实际路径调整

@Entry
@Component
struct RegisterPage {
  @State phone: string = ""
  @State password: string = ""
  @State confirmPassword: string = ""
  @State checked: boolean = false
  @State infoMsg: string = ""
  @State saving: boolean = false

  // 表单是否有效
  isFormValid(): boolean {
    return (
      this.phone.length === 11 &&
      /^[0-9]{11}$/.test(this.phone) &&
        this.checked === true &&
        this.password.length > 0 &&
        this.password === this.confirmPassword
    )
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景图
      Image($r('app.media.bj1'))
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('120%')

      // 上层居中的白框
      Column({ space: 25 }) {
        Text("欢迎注册百度账号")
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
            this.phone = v.replace(/\D/g, ""); // 只保留数字
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

        // 确认密码输入框
        TextInput({ placeholder: "请再次输入密码" })
          .type(InputType.Password)
          .backgroundColor("#F5F5F5")
          .fontColor(Color.Black)
          .borderRadius(10)
          .padding(15)
          .width('80%')
          .textAlign(TextAlign.Center)
          .onChange((v) => {
            this.confirmPassword = v;
          });

        // 注册按钮
        Button("立即注册")
          .width("80%")
          .height(48)
          .borderRadius(12)
          .fontColor("#FFFFFF")
          .backgroundColor(this.isFormValid() ? "#007AFF" : "#ADD8E6")
          .onClick(async () => {
            if (!this.isFormValid()) {
              this.infoMsg = "请填写完整信息，确保两次密码一致";
              return;
            }
            console.log("验证通过，开始保存用户");
            const ctx = getContext(this) as common.Context;
            await saveUser(ctx, this.phone, this.password);
            this.infoMsg = "注册成功，2秒后跳转...";

            setTimeout(() => {
              router.push({ url: "pages/LoginPage" });
            }, 2000);
          });

        // 协议勾选
        Row() {
          Checkbox()
            .onChange((v: boolean) => {
              this.checked = v;
            })

          Text("请您阅读并同意百度用户协议和隐私政策")
            .fontColor(Color.Black)
            .fontSize(12)
        }
        .margin({ top: 10 })
        .alignItems(VerticalAlign.Center)
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
