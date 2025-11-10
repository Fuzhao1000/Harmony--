// entry/src/main/ets/common/UserStorage.ets
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import util from '@ohos.util';
const STORE_NAME = "user_store";

export interface LoginResponse {
  success: boolean;
  id?: number;
  name?: string;
  message?: string;
}




export async function saveUser(context: common.Context, username: string, password: string): Promise<void> {
  const preferences = await dataPreferences.getPreferences(context, STORE_NAME);
  await preferences.put(username, password);
  await preferences.flush();
}

export async function checkUser(phone: string, password: string): Promise<LoginResponse> {
  const httpRequest = http.createHttp();

  try {
    const response = await httpRequest.request(
      "http://10.205.218.246:8080/api/login",
      {
        method: http.RequestMethod.POST,
        header: { "Content-Type": "application/json" },
        extraData: { phone, password }
      }
    );

    let text = typeof response.result === "string"
      ? response.result
      : new util.TextDecoder("utf-8").decode(response.result as  Uint8Array);

    const data = JSON.parse(text) as LoginResponse;
    // ✅ 返回完整对象，包括 id 和 name
    return data;

  } catch (e) {
    return { success: false };
  } finally {
    httpRequest.destroy();
  }
}

