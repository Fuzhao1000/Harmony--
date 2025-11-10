// entry/src/main/ets/pages/LoginPage.ets
import { checkUser } from '../common/UserStorage';
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';
import { LoginResponse } from '../common/UserStorage';
import preferences from '@ohos.data.preferences';

interface UserInfo {
  id: string;  // 存储后为字符串
  name: string;
}

async function getUserStorage(context: common.UIAbilityContext): Promise<preferences.Preferences> {
  return await preferences.getPreferences(context, "userInfo");
}

async function saveLoginInfo(ok: LoginResponse, context: common.UIAbilityContext) {

    console.log("开始保存，ok 数据:", JSON.stringify(ok));
    const storage = await getUserStorage(context);
    console.log("Storage 获取成功");

    await storage.put("userId", ok.id?.toString() ?? "");
    console.log("userId 保存:", ok.id?.toString() ?? "");

    await storage.put("userName", ok.name ?? "默认用户");
    console.log("userName 保存:", ok.name ?? "默认用户");

    await storage.flush();
    console.log("Flush 完成");

    // 立即测试读取
    const testId = await storage.get("userId", "未保存");
    const testName = await storage.get("userName", "未保存");
    console.log("立即读取测试 - ID:", testId, "Name:", testName);

}

// 更新返回类型为 Promise<UserInfo>
export  async function loadUserInfo(context: common.UIAbilityContext): Promise<UserInfo> {
  try {
    const storage = await getUserStorage(context);
    const id = await storage.get("userId", "");
    const name = await storage.get("userName", "默认用户");
    console.log("loadUserInfo - 用户ID:", id, "用户名称:", name);

    // 显式返回匹配接口的对象（ArkTS 要求这样）
    return {
      id: id,
      name: name
    } as UserInfo;  // 类型断言可选，但推荐注解函数签名
  } catch (error) {
    console.error("loadUserInfo 错误:", error);
    return {
      id: "",
      name: "默认用户"
    } as UserInfo;
  }
}

export async function saveUserName(name: string, context: common.UIAbilityContext) {
  try {
    const storage = await preferences.getPreferences(context, "userInfo");
    await storage.put("userName", name);
    await storage.flush();
    console.log("userName 更新成功:", name);
  } catch (error) {
    console.error("saveUserName 错误:", error);
  }
}
@Entry
@Component


struct LoginPage {

  @State username: string = ""
  @State password: string = ""
  @State errorMsg: string = ""

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

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

            const ok = await checkUser( this.username, this.password)
            if (ok) {
              console.log("checkUser 成功:", ok);
              await saveLoginInfo(ok, this.context);  // 传入 context
              const userInfo = await loadUserInfo(this.context);  // 传入 context
              console.log("保存后加载:", userInfo);
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
