@Entry
@Component
struct TrainPage {
  build() {
    Column() {
      // 上方 25%
      Column({ space: 10 }) {
        // 第一行：杭州 <> 衢州
        Text("杭州 <> 衢州")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width('100%')

        // 第二行：日期信息
        Row({ space: 12 }) {
          this.buildDate("周二", "9.30")
          this.buildDate("周三", "10.01")
          this.buildDate("周四", "10.02")
          this.buildDate("周五", "10.03")
          this.buildDate("周六", "10.04")
          this.buildDate("周日", "10.05")
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }
      .height('20%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      // 下方 75% 白色圆角卡片
      Column() {
        Column({ space: 15 }) {
          // 第一行：直达 中转
          Row({ space: 20 }) {
            Text("直达").fontSize(16).fontColor(Color.Black)
            Text("|").fontSize(16).fontColor(Color.Black)
            Text("中转").fontSize(16).fontColor(Color.Black)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')

          // 第二行：四个方框 + 灰色文字
          Row({ space: 9 }) {
            this.buildCheckBox("只看高铁动车")
            this.buildCheckBox("只看普通车")
            this.buildCheckBox("只看有票")
            this.buildCheckBox("其他")
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')

          // 第三行：四个黑边白底框
          Row({ space: 15 }) {
            this.buildTag("杭州东")
            this.buildTag("杭州南")
            this.buildTag("杭州")
            this.buildTag("衢州")
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')


          // 白框中间的列表
          List({ space: 12 }) {
            // 每一条车次信息
            ListItem() {
              Column() {
                // 外层白色圆角框
                Column() {
                  // 第一行：出发时间 + 始发站 + 车次信息 + 到达时间 + 终点站
                  Row({ space: 2 }) {
                    // 出发时间
                    Column() {
                      Text("00:03")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("始")
                          .fontSize(12)
                          .fontColor('#FFA500')
                        Text(" 杭州东")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .width('30%')

                    // 车次 + 耗时
                    Column({ space: 2 }) {
                      Text("G9507")
                        .fontSize(14)
                        .fontColor(Color.Black)
                      Text("1时2分")
                        .fontSize(12)
                        .fontColor(Color.Gray)
                    }
                    .alignItems(HorizontalAlign.Center)
                    .width('15%')

                    // 到达时间
                    Column() {
                      Text("01:05")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("终")
                          .fontSize(12)
                          .fontColor(Color.Green)
                        Text(" 衢州")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }

                    }
                    .alignItems(HorizontalAlign.End)
                    .width('30%')
                  }
                  .margin({ bottom: 8 })

                  // 第二行：票务信息
                  Row({ space: 10 }) {
                    Text("二等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("有票")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("一等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("有票")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("商务")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("14张")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("无座")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("无")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                  }
                }
                .padding(12)
                .backgroundColor('#E0E0E0')
                .borderRadius(12)
                .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
              }.margin({left:60})

            }
            ListItem() {
              Column() {
                // 外层白色圆角框
                Column() {
                  // 第一行：出发时间 + 始发站 + 车次信息 + 到达时间 + 终点站
                  Row({ space: 2 }) {
                    // 出发时间
                    Column() {
                      Text("05:40")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("始")
                          .fontSize(12)
                          .fontColor('#FFA500')
                        Text(" 杭州东")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .width('30%')

                    // 车次 + 耗时
                    Column({ space: 2 }) {
                      Text("G9507")
                        .fontSize(14)
                        .fontColor(Color.Black)
                      Text("1时9分")
                        .fontSize(12)
                        .fontColor(Color.Gray)
                    }
                    .alignItems(HorizontalAlign.Center)
                    .width('15%')

                    // 到达时间
                    Column() {
                      Text("06:59")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("过")
                          .fontSize(12)
                          .fontColor(Color.Blue)
                        Text(" 衢州")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }

                    }
                    .alignItems(HorizontalAlign.End)
                    .width('30%')
                  }
                  .margin({ bottom: 8 })

                  // 第二行：票务信息
                  Row({ space: 10 }) {
                    Text("二等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("候补")
                      .fontSize(12)
                      .fontColor(Color.Blue)

                    Text("一等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("有票")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("商务")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("1张")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("无座")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("无")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                  }
                }
                .padding(12)
                .backgroundColor('#E0E0E0')
                .borderRadius(12)
                .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
              }.margin({left:60})

            }
            ListItem() {
              Column() {
                // 外层白色圆角框
                Column() {
                  // 第一行：出发时间 + 始发站 + 车次信息 + 到达时间 + 终点站
                  Row({ space: 2 }) {
                    // 出发时间
                    Column() {
                      Text("00:03")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("始")
                          .fontSize(12)
                          .fontColor('#FFA500')
                        Text(" 杭州东")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .width('30%')

                    // 车次 + 耗时
                    Column({ space: 2 }) {
                      Text("G9507")
                        .fontSize(14)
                        .fontColor(Color.Black)
                      Text("1小时2分")
                        .fontSize(12)
                        .fontColor(Color.Gray)
                    }
                    .alignItems(HorizontalAlign.Center)
                    .width('15%')

                    // 到达时间
                    Column() {
                      Text("01:05")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("终")
                          .fontSize(12)
                          .fontColor(Color.Green)
                        Text(" 衢州")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }

                    }
                    .alignItems(HorizontalAlign.End)
                    .width('30%')
                  }
                  .margin({ bottom: 8 })

                  // 第二行：票务信息
                  Row({ space: 10 }) {
                    Text("二等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("有票")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("一等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("有票")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("商务")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("14张")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("无座")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("无")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                  }
                }
                .padding(12)
                .backgroundColor('#E0E0E0')
                .borderRadius(12)
                .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
              }.margin({left:60})

            }
            ListItem() {
              Column() {
                // 外层白色圆角框
                Column() {
                  // 第一行：出发时间 + 始发站 + 车次信息 + 到达时间 + 终点站
                  Row({ space: 2 }) {
                    // 出发时间
                    Column() {
                      Text("00:03")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("始")
                          .fontSize(12)
                          .fontColor('#FFA500')
                        Text(" 杭州东")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .width('30%')

                    // 车次 + 耗时
                    Column({ space: 2 }) {
                      Text("G9507")
                        .fontSize(14)
                        .fontColor(Color.Black)
                      Text("1小时2分")
                        .fontSize(12)
                        .fontColor(Color.Gray)
                    }
                    .alignItems(HorizontalAlign.Center)
                    .width('15%')

                    // 到达时间
                    Column() {
                      Text("01:05")
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.Black)
                      Row() {
                        Text("终")
                          .fontSize(12)
                          .fontColor(Color.Green)
                        Text(" 衢州")
                          .fontSize(12)
                          .fontColor(Color.Black)
                      }

                    }
                    .alignItems(HorizontalAlign.End)
                    .width('30%')
                  }
                  .margin({ bottom: 8 })

                  // 第二行：票务信息
                  Row({ space: 10 }) {
                    Text("二等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("有票")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("一等")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("有票")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("商务")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("14张")
                      .fontSize(12)
                      .fontColor(Color.Green)

                    Text("无座")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text("无")
                      .fontSize(12)
                      .fontColor(Color.Gray)
                  }
                }
                .padding(12)
                .backgroundColor('#E0E0E0')
                .borderRadius(12)
                .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
              }.margin({left:60})

            }

          }
          .width('100%')


          Blank().layoutWeight(1)
          Row({ space: 5 }) {
            this.buildFilter("筛选")
            this.buildFilter("耗时最短")
            this.buildFilter("发时最早")
            this.buildFilter("价格最低")
            this.buildFilter("候补下单")
          }
          .width('90%')
          .justifyContent(FlexAlign.SpaceAround)
          .padding({ top: 10, bottom: 20  })
        }
        .padding(15)
      }
      .height('85%')
      .width('120%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 30, topRight: 30 }) // 上边圆角
      .shadow({ radius: 10, color: Color.Gray })   // 阴影（可选）
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Blue) // 整个背景蓝色
  }

  @Builder
  buildDate(week: string, date: string) {
    Column() {
      Text(week)
        .fontSize(14)
        .fontColor(Color.White)

      Text(date)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
    }
    .alignItems(HorizontalAlign.Center)
  }
  @Builder
  buildCheckBox(label: string) {
    Row({ space: 4 }) {
      // 模拟一个方框
      Blank().width(14).height(14).border({ width: 1, color: Color.Gray })
      Text(label).fontSize(14).fontColor(Color.Gray)
    }
  }

  // 黑边白底的标签
  @Builder
  buildTag(label: string) {
    Text(label)
      .fontSize(14)
      .fontColor(Color.Gray)
      .border({ width: 1, color: Color.Black })
      .backgroundColor(Color.White)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(6)
  }

  @Builder
  buildFilter(label: string) {
    Text(label)
      .fontSize(14)
      .fontColor(Color.Black)
      .backgroundColor(Color.White)
      .border({ width: 1, color: Color.Gray })
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(8)
  }
}