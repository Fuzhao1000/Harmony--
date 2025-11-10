// entry/src/main/ets/pages/RegisterPage.ets
import router from '@ohos.router';
import http from '@ohos.net.http';
import prompt from '@system.prompt';
import util from '@ohos.util';

interface RegisterResponse {
  success: boolean;
  message?: string;
}

@Entry
@Component
struct RegisterPage {
  @State phone: string = ""
  @State password: string = ""
  @State confirmPassword: string = ""
  @State checked: boolean = false
  @State infoMsg: string = ""
  @State saving: boolean = false

  isFormValid(): boolean {
    return (
      this.phone.length === 11 &&
      /^[0-9]{11}$/.test(this.phone) &&
        this.checked === true &&
        this.password.length >= 6 &&
        this.password === this.confirmPassword
    )
  }

  // 新增：发送注册请求到后端
  async registerUser() {
    this.saving = true;
    this.infoMsg = "注册中...";

    const httpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await httpRequest.request(
        "http://10.205.218.246:8080/api/register",
        {
          method: http.RequestMethod.POST,
          header: { "Content-Type": "application/json" },
          extraData: { phone: this.phone, password: this.password },
        }
      );

      // 安全处理 result
      let data: RegisterResponse;
      if (typeof response.result === "string") {
        data = JSON.parse(response.result) as RegisterResponse;
      } else if (response.result instanceof Uint8Array) {
        const decoder = new util.TextDecoder('utf-8');
        const text: string = decoder.decode(response.result);  // 类型明确：string
        data = JSON.parse(text) as RegisterResponse;
      } else {
        data = response.result as RegisterResponse; // 已经是对象
      }

      if (response.responseCode === 200 && data.success) {
        this.infoMsg = "注册成功，2秒后跳转登录";
        setTimeout(() => router.pushUrl({ url: "pages/LoginPage" }), 2000);
      } else {
        this.infoMsg = data.message ?? "注册失败";
      }
    } catch (e) {
      console.error("注册请求异常:", e);
      this.infoMsg = "网络错误，请稍后重试";
    } finally {
      this.saving = false;
      httpRequest.destroy();
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image($r('app.media.bj1'))
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('120%')

      Column({ space: 25 }) {
        Text("欢迎注册百度账号")
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 40 })

        TextInput({ placeholder: "请输入手机号" })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .backgroundColor("#F5F5F5")
          .borderRadius(10)
          .padding(15)
          .width('80%')
          .textAlign(TextAlign.Center)
          .onChange((v) => {
            this.phone = v.replace(/\D/g, "");
          });

        TextInput({ placeholder: "请输入密码" })
          .type(InputType.Password)
          .backgroundColor("#F5F5F5")
          .borderRadius(10)
          .padding(15)
          .width('80%')
          .textAlign(TextAlign.Center)
          .onChange((v) => this.password = v);

        TextInput({ placeholder: "请再次输入密码" })
          .type(InputType.Password)
          .backgroundColor("#F5F5F5")
          .borderRadius(10)
          .padding(15)
          .width('80%')
          .textAlign(TextAlign.Center)
          .onChange((v) => this.confirmPassword = v);

        Button(this.saving ? "注册中..." : "立即注册")
          .width("80%")
          .height(48)
          .borderRadius(12)
          .fontColor("#FFFFFF")
          .backgroundColor(this.isFormValid() && !this.saving ? "#007AFF" : "#ADD8E6")
          .enabled(this.isFormValid() && !this.saving)
          .onClick(() => {
            if (!this.isFormValid()) {
              this.infoMsg = "请填写完整信息，两次密码需一致";
              return;
            }
            this.registerUser();  // 调用后端接口
          });

        Row() {
          Checkbox()
            .onChange((v: boolean) => this.checked = v)
          Text("请您阅读并同意百度用户协议和隐私政策")
            .fontColor(Color.Black)
            .fontSize(12)
        }
        .margin({ top: 10 })
        .alignItems(VerticalAlign.Center)

        // 显示提示信息
        if (this.infoMsg) {
          Text(this.infoMsg)
            .fontColor(this.infoMsg.includes("成功") ? Color.Green : Color.Red)
            .fontSize(14)
            .margin({ top: 10 })
        }

        Button("已有账号？去登录")
          .width("80%")
          .height(40)
          .borderRadius(12)
          .fontColor("#007AFF")
          .backgroundColor("#FFFFFF")
          .border({ width: 1, color: "#007AFF" }) // 蓝色边框
          .margin({ top: 15 })
          .onClick(() => {
            router.pushUrl({ url: "pages/LoginPage" });
          });
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