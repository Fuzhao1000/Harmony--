import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';
import util from '@ohos.util';
import { BASE_URL } from '../pages/ip';

interface ChatMessage {
  id: number;
  content: string;
  senderId: number;
  receiverId: number;
  timestamp: number;
  isMine: boolean;
}

interface MessageItem {
  id: number;
  senderId: string | number;
  receiverId: string | number;
  content: string;
  createTime: number;
}

interface MessageListResponse {
  success: boolean;
  messages: MessageItem[];
}

interface SendMessageResponse {
  success: boolean;
  message?: MessageItem;
  error?: string;
}

@Entry
@Component
struct ChatPage {
  @State currentUserId: number = 0
  @State targetUserId: number = 0
  @State targetUserName: string = ''
  @State targetUserAvatar: string = ''
  @State messages: ChatMessage[] = []
  @State inputText: string = ''
  private inputController: TextInputController = new TextInputController()
  private scroller: Scroller = new Scroller()
  private pollingTimer: number = -1

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.currentUserId = params['userId'] as number || 0;
    this.targetUserId = params['targetUserId'] as number || 0;
    this.targetUserName = params['targetUserName'] as string || '未知用户';
    this.targetUserAvatar = params['targetUserAvatar'] as string || '';
    
    console.log(`ChatPage初始化 - currentUserId: ${this.currentUserId}, targetUserId: ${this.targetUserId}`);
    
    // 加载历史消息
    this.loadMessages();
    
    // 标记消息为已读
    this.markAsRead();
    
    // 启动定时轮询新消息（每3秒）
    this.startPolling();
  }

  aboutToDisappear() {
    // 页面销毁时停止轮询
    this.stopPolling();
  }

  // 标记消息为已读
  async markAsRead() {
    try {
      const httpRequest = http.createHttp();
      await httpRequest.request(
        `${BASE_URL}/api/message/markRead`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify({
            userId: this.currentUserId,
            targetUserId: this.targetUserId
          })
        }
      );
      httpRequest.destroy();
    } catch (e) {
      console.error('标记已读失败:', e);
    }
  }

  startPolling() {
    this.pollingTimer = setInterval(() => {
      this.loadMessages();
    }, 3000);
  }

  stopPolling() {
    if (this.pollingTimer !== -1) {
      clearInterval(this.pollingTimer);
      this.pollingTimer = -1;
    }
  }

  async loadMessages() {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${BASE_URL}/api/message/list?userId=${this.currentUserId}&targetUserId=${this.targetUserId}`,
        { method: http.RequestMethod.GET }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      console.log('加载消息响应:', text);
      const data = JSON.parse(text) as MessageListResponse;

      if (data.success && data.messages) {
        console.log(`加载了 ${data.messages.length} 条消息`);
        this.messages = data.messages.map((msg): ChatMessage => {
          // 确保类型转换为number进行比较
          const msgSenderId: number = typeof msg.senderId === 'string' ? parseInt(msg.senderId) : msg.senderId;
          const msgReceiverId: number = typeof msg.receiverId === 'string' ? parseInt(msg.receiverId) : msg.receiverId;
          const isMine = msgSenderId === this.currentUserId;
          console.log(`消息ID:${msg.id}, senderId:${msgSenderId}, currentUserId:${this.currentUserId}, isMine:${isMine}`);
          return {
            id: msg.id,
            content: msg.content,
            senderId: msgSenderId,
            receiverId: msgReceiverId,
            timestamp: msg.createTime,
            isMine: isMine
          };
        });
        
        // 滚动到底部
        setTimeout(() => {
          this.scroller.scrollEdge(Edge.Bottom);
        }, 100);
      } else {
        console.log('加载消息失败或无消息:', data);
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error('加载消息失败:', e);
    }
  }

  async sendMessage() {
    if (!this.inputText.trim()) {
      return;
    }

    const messageContent = this.inputText.trim();
    this.inputText = '';

    try {
      console.log(`发送消息: ${messageContent} from ${this.currentUserId} to ${this.targetUserId}`);
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${BASE_URL}/api/message/send`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify({
            senderId: this.currentUserId,
            receiverId: this.targetUserId,
            content: messageContent
          })
        }
      );

      let text = typeof response.result === "string"
        ? response.result
        : new util.TextDecoder("utf-8").decode(response.result as Uint8Array);

      const data = JSON.parse(text) as SendMessageResponse;
      console.log('发送消息响应:', JSON.stringify(data));

      if (data.success && data.message) {
        const msgSenderId: number = typeof data.message.senderId === 'string' ? parseInt(data.message.senderId) : data.message.senderId;
        const msgReceiverId: number = typeof data.message.receiverId === 'string' ? parseInt(data.message.receiverId) : data.message.receiverId;
        
        console.log('消息发送成功，ID:', data.message.id);
        console.log('返回的senderId:', msgSenderId, '(类型:', typeof msgSenderId, '), 当前用户ID:', this.currentUserId, '(类型:', typeof this.currentUserId, ')');
        
        // 添加到消息列表
        const newMessage: ChatMessage = {
          id: data.message.id || Date.now(),
          content: data.message.content || messageContent,
          senderId: msgSenderId || this.currentUserId,
          receiverId: msgReceiverId || this.targetUserId,
          timestamp: data.message.createTime || Date.now(),
          isMine: true
        };
        
        console.log('添加新消息:', JSON.stringify(newMessage));
        this.messages.push(newMessage);
        
        // 收起键盘
        this.inputController.stopEditing();
        
        // 滚动到底部
        setTimeout(() => {
          this.scroller.scrollEdge(Edge.Bottom);
        }, 100);
      } else {
        console.error('发送消息失败:', data);
        promptAction.showToast({ message: data.error || '发送失败' });
        // 恢复输入框内容
        this.inputText = messageContent;
      }
      
      httpRequest.destroy();
    } catch (e) {
      console.error('发送消息失败:', e);
      promptAction.showToast({ message: '发送失败，请重试' });
      // 恢复输入框内容
      this.inputText = messageContent;
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
  }

  build() {
    Column() {
      // 顶部导航栏
      Row({ space: 12 }) {
        Text('<')
          .fontSize(24)
          .fontColor('#007AFF')
          .width(30)
          .onClick(() => {
            router.back();
          })

        Image(this.targetUserAvatar ? this.targetUserAvatar : $r('app.media.head'))
          .width(36)
          .height(36)
          .borderRadius(18)

        Text(this.targetUserName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)

        Text('•••')
          .fontSize(20)
          .fontColor('#666666')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 0.5 }, color: '#E8E8E8' })

      // 消息列表
      if (this.messages.length === 0) {
        Column({ space: 16 }) {
          Text('💬')
            .fontSize(48)
          Text('开始聊天吧')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FAFAFA')
      } else {
        Scroll(this.scroller) {
          Column({ space: 12 }) {
            ForEach(this.messages, (msg: ChatMessage) => {
              Row() {
                if (msg.isMine) {
                  Blank()
                }

                Column({ space: 4 }) {
                  // 消息气泡
                  Text(msg.content)
                    .fontSize(15)
                    .fontColor(msg.isMine ? Color.White : '#333333')
                    .backgroundColor(msg.isMine ? '#007AFF' : '#F0F0F0')
                    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                    .borderRadius(16)
                    .constraintSize({ maxWidth: '70%' })

                  // 时间
                  Text(this.formatTime(msg.timestamp))
                    .fontSize(11)
                    .fontColor('#999999')
                }
                .alignItems(msg.isMine ? HorizontalAlign.End : HorizontalAlign.Start)

                if (!msg.isMine) {
                  Blank()
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16 })
            }, (msg: ChatMessage) => (msg.id ? msg.id.toString() : msg.timestamp.toString()))
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .backgroundColor('#FAFAFA')
        .align(Alignment.TopStart)
      }

      // 输入框
      Row({ space: 8 }) {
        TextInput({
          placeholder: '说点什么...',
          text: this.inputText,
          controller: this.inputController
        })
          .onChange((value: string) => {
            this.inputText = value;
          })
          .height(40)
          .borderRadius(20)
          .backgroundColor('#F5F5F5')
          .layoutWeight(1)

        Button('发送')
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.inputText.trim() ? '#007AFF' : '#CCCCCC')
          .fontColor(Color.White)
          .onClick(() => {
            this.sendMessage();
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor(Color.White)
      .border({ width: { top: 0.5 }, color: '#E8E8E8' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
