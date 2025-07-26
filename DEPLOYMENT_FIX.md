# Cloudflare Worker 修复说明

## 问题描述
用户执行 `curl --proto '=https' --tlsv1.2 -sSf lebit.sh/install | sh` 命令时，返回的是 HTML 网页而不是 bash 脚本。

## 问题原因
1. 原始的 Worker 代码没有检测请求的 User-Agent，无法区分 curl 请求和浏览器请求
2. `web` 目录中存在 `install.html` 文件，Cloudflare Sites 优先返回静态文件

## 解决方案

### 1. 修改 Worker 代码 (src/worker.js)
- 添加 User-Agent 检测逻辑
- 对于 curl/wget 请求，返回纯文本的 bash 脚本
- 对于浏览器请求 `/install`，返回带下载头的脚本文件

### 2. 重命名冲突文件
- 将 `web/install.html` 重命名为 `web/installation.html`
- 更新所有引用链接

### 3. 配置调整
- 创建 `wrangler.toml` 配置文件
- 正确配置路由规则

## 测试验证

### 成功的测试结果：
```bash
# 测试 /install 路径
curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh/install | sh

# 返回 bash 脚本内容（正确）
```

### 需要注意的问题：
1. **缓存问题**：Cloudflare 可能会缓存响应，导致更改不立即生效
2. **根路径行为**：当前配置下，curl 访问根路径 `/` 仍返回 HTML（这是预期行为，因为 Worker 只对 `/install` 路径的 curl 请求返回脚本）

## 使用说明

用户现在可以使用以下命令安装：
```bash
curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh/install | sh
```

或者使用短域名：
```bash
curl --proto '=https' --tlsv1.2 -sSf lebit.sh/install | sh
```

## 部署步骤
```bash
# 确保 .env 文件包含必要的环境变量
# CLOUDFLARE_ACCOUNT_ID=你的账户ID
# CLOUDFLARE_API_TOKEN=你的API令牌

# 执行部署
./deploy.sh
```