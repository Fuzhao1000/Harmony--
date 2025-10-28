// entry/src/main/ets/common/UserStorage.ets
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const STORE_NAME = "user_store";

export async function saveUser(context: common.Context, username: string, password: string): Promise<void> {
  const preferences = await dataPreferences.getPreferences(context, STORE_NAME);
  await preferences.put(username, password);
  await preferences.flush();
}

export async function checkUser(context: common.Context, username: string, password: string): Promise<boolean> {
  const preferences = await dataPreferences.getPreferences(context, STORE_NAME);
  const storedPwd = await preferences.get(username, ""); 
  return storedPwd === password;
}
