# Introduction
A summary of the default configuration of the development tools collection, including:  
-- Visual Studio Code  
-- Windows Terminal Preview   

## Windows Ternimal Preview  
--Profiles.json 

## iTerm2-Color-Schemes  
- Fonts: MesloLFG* (4 files) on macOS  
- Config file of Colors : Coolnight  


# Global Description
By default that the config files of development tools(such as : vs code and Windows terminal etc.,)

# Lebit.sh - Linux系统初始化工具包

Lebit.sh提供了一系列工具，帮助您快速高效地设置和配置Linux环境。只需运行我们的一行命令安装即可开始使用。

## 可用模块

### 系统管理
系统优化、清理和信息收集工具。

```bash
curl --proto '=https' --tlsv1.2 -sSf https://system.lebit.sh | sh
```

功能:
- 硬件信息收集
- 系统清理与深度清理
- 时间同步工具

### Docker管理
轻松安装和配置Docker环境。

```bash
curl --proto '=https' --tlsv1.2 -sSf https://docker.lebit.sh | sh
```

功能:
- 安装Docker和Docker Compose
- 升级Docker到最新版本
- 配置Docker设置
- 清理Docker资源
- Docker容器监控

### 开发环境
快速设置开发环境，包括流行的编程语言和工具。

```bash
curl --proto '=https' --tlsv1.2 -sSf https://dev.lebit.sh | sh
```

功能:
- 安装Golang
- 安装Node.js (通过NVM)
- 安装Rust
- 安装SQLite3
- 设置快速别名

### 系统工具
实用系统工具集合。

```bash
curl --proto '=https' --tlsv1.2 -sSf https://tools.lebit.sh | sh
```

功能:
- SSL证书更新工具

### 挖矿工具
加密货币挖矿操作的工具。

```bash
curl --proto '=https' --tlsv1.2 -sSf https://mining.lebit.sh | sh
```

功能:
- Ritual挖矿
- EthStorage挖矿
- TitanNetwork挖矿

## 系统功能

### 配置系统
Lebit.sh现在包含一个功能强大的配置系统，允许用户自定义工具包的行为：

- 用户级、系统级和默认配置文件
- 可配置的日志级别、颜色使用和其他设置
- 支持通过内置编辑器修改配置

### 日志系统
新的日志系统提供更好的调试和问题排查能力：

- 支持多个日志级别（DEBUG、INFO、WARN、ERROR、CRITICAL）
- 同时记录到控制台和日志文件
- 日志浏览和搜索功能

### 增强UI
改进的用户界面提供更好的交互体验：

- 彩色输出和格式化
- 进度指示器和状态显示
- 系统信息概览

## 如何使用

### 通用安装
交互式菜单，包含所有可用模块:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh | sh
```

### 直接模块访问
您也可以直接访问特定模块:

```bash
# 访问Docker模块
curl --proto '=https' --tlsv1.2 -sSf https://docker.lebit.sh | sh

# 访问模块的替代方式
curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh | sh -s -- docker
```

## 要求
- 基于Linux的操作系统 (Ubuntu, Debian, CentOS, RHEL, Fedora等)
- Root访问权限 (sudo权限)

## 项目结构

```
lebitsh/
├── common/           # 公共库和函数
│   ├── config.sh     # 配置管理系统
│   ├── logging.sh    # 日志记录系统
│   ├── ui.sh         # 用户界面组件
│   └── utils.sh      # 通用工具函数
├── config/           # 配置文件
│   └── defaults.conf # 默认配置
├── modules/          # 功能模块
│   ├── dev/          # 开发环境模块
│   ├── docker/       # Docker管理模块
│   ├── mining/       # 挖矿工具模块
│   ├── system/       # 系统管理模块
│   └── tools/        # 系统工具模块
├── install.sh        # 安装脚本
└── main.sh           # 主入口脚本
```

## 贡献
欢迎贡献！请随时提交问题或拉取请求，帮助我们改进工具包。

## 许可证
MIT

## 挖矿工具详细说明

### EthStorage

1. 节点安装命令如下:  
   `wget -O ethstorage_install.sh https://raw.githubusercontent.com/xiaoliwe/mining/main/EthStorage/install.sh && chmod +x ethstorage_install.sh && ./ethstorage_install.sh`  
    以初始化挖矿环境。  

2. 官方文档在这里: https://docs.ethstorage.io/storage-provider-guide/tutorials

### Ritual

1. 节点安装命令如下:  
   `wget -O ritual_install.sh https://raw.githubusercontent.com/xiaoliwe/mining/main/Ritual/install.sh && chmod +x ritual_install.sh && ./ritual_install.sh`  
   以初始化挖矿环境。

2. 官方文档在这里: https://docs.ritual.net/

### TitanNetwork

1. 节点安装命令如下:  
   `wget -O titan_install.sh https://raw.githubusercontent.com/xiaoliwe/mining/main/TitanNetwork/install.sh && chmod +x titan_install.sh && ./titan_install.sh`  
   以初始化挖矿环境。

2. 官方文档在这里: https://docs.titan.network/
