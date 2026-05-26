# MJPEG Stream Player

一个用于播放 HTTP MJPEG 视频流的 iOS 应用。

## 功能特性

- 📹 实时播放 MJPEG 视频流
- 🔧 可自定义流媒体 URL
- 🎯 默认连接到 `http://192.168.1.254:8192`
- 🔄 支持播放/停止控制
- 📱 支持 iOS 设备和模拟器

## 技术实现

### 架构
- **SwiftUI** - 现代化的用户界面
- **Combine** - 响应式数据流
- **URLSession** - 网络请求处理

### 流媒体解析
应用支持两种 MJPEG 流格式：
1. **标准 multipart/x-mixed-replace** - 使用 boundary 分隔的连续流
2. **独立 JPEG 响应** - 每个帧作为单独的 HTTP 响应（如 eCos 服务器）

应用会自动检测服务器响应类型：
- 检测 `Content-Type: image/jpeg` 响应
- 读取 `Content-Length` 头确定图像大小
- 累积数据直到接收完整的 JPEG 图像
- 解码并显示图像帧

### 网络安全配置
- 配置了 App Transport Security (ATS) 允许 HTTP 连接
- 添加了本地网络访问权限
- 支持访问局域网设备

## 使用方法

1. 在 Xcode 中打开 `MJPEG.xcodeproj`
2. 选择目标设备或模拟器
3. 运行应用（⌘R）
4. 输入 MJPEG 流 URL（或使用默认地址）
5. 点击播放按钮开始播放

## 系统要求

- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+

## 项目结构

```
MJPEG/
├── MJPEGApp.swift          # 应用入口
├── ContentView.swift       # 主视图
├── MJPEGStreamView.swift   # 流媒体播放器视图和逻辑
└── Assets.xcassets/        # 应用资源
```

## 调试

应用包含详细的日志输出，可在 Xcode 控制台查看：
- 🎬 连接开始
- 📥 接收响应
- 🆕 准备接收新图像
- 📦 数据块接收
- 💾 缓冲区状态
- 🎨 图像解码
- ✅ 成功/❌ 错误

## 常见问题

### 无法连接到流媒体服务器
- 确保设备/模拟器与服务器在同一网络
- 检查服务器 IP 地址和端口是否正确
- 确认服务器正在运行并可访问

### 显示"连接中"但没有画面
- 查看 Xcode 控制台日志
- 确认服务器返回的是 JPEG 图像数据
- 检查网络连接是否稳定

## 许可证

MIT License

## 作者

![AIDevLog](https://2019.iosdevlog.com/uploads/AIDevLog.jpg)

微信公众号：AI开发日志

Created with <https://github.com/build-your-own-x-with-ai/MJPEG_iOS>
