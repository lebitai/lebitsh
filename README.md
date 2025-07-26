# Lebit.sh - Linux System Initialization Toolkit

Lebit.sh provides a suite of tools to help you quickly and efficiently set up and configure your Linux environment. Just run our one-line installation command to get started.

[English](#english) | [中文](#中文)

<a name="english"></a>
## Available Modules

### System Management
System optimization, cleaning, and information gathering tools.

```bash
curl -sSf https://lebit.sh/install | sh -s -- system
```

Features:
- Hardware information collection
- System cleaning and deep cleaning
- Time synchronization tools

### Docker Management
Easily install and configure Docker environments.

```bash
curl -sSf https://lebit.sh/install | sh -s -- docker
```

Features:
- Install Docker and Docker Compose
- Upgrade Docker to the latest version
- Configure Docker settings
- Clean Docker resources
- Docker container monitoring

### Development Environment
Quickly set up development environments, including popular programming languages and tools.

```bash
curl -sSf https://lebit.sh/install | sh -s -- dev
```

Features:
- Install Golang
- Install Node.js (via NVM)
- Install Rust
- Install SQLite3
- Set up quick aliases

### System Tools
Collection of useful system utilities.

```bash
curl -sSf https://lebit.sh/install | sh -s -- tools
```

Features:
- SSL certificate renewal tools

### Mining Tools
Tools for cryptocurrency mining operations.

```bash
curl -sSf https://lebit.sh/install | sh -s -- mining
```

Features:
- Ritual mining
- EthStorage mining
- TitanNetwork mining

## System Features

### Configuration System
Lebit.sh now includes a powerful configuration system allowing users to customize the toolkit's behavior:

- User-level, system-level, and default configuration files
- Configurable log levels, color usage, and other settings
- Support for modifying configuration through built-in editors

### Logging System
The new logging system provides better debugging and troubleshooting capabilities:

- Support for multiple log levels (DEBUG, INFO, WARN, ERROR, CRITICAL)
- Simultaneous logging to console and log files
- Log browsing and search functionality

### Enhanced UI
The user interface has been enhanced to provide a better user experience:

- Color-coded outputs for better readability
- Progress indicators for long-running operations
- Interactive menus for module selection

## Installation

To install Lebit.sh with all modules:

```bash
curl -sSf https://lebit.sh/install | sh
```

To install a specific module directly:

```bash
curl -sSf https://lebit.sh/install | sh -s -- [module-name]
```

## Project Structure

```
lebitsh/
├── config/          # Configuration files
├── logs/            # Log files
├── modules/         # All available modules
│   ├── core/        # Core functionality
│   ├── system/      # System management tools
│   ├── docker/      # Docker utilities
│   ├── dev/         # Development environment tools
│   ├── tools/       # System utilities
│   └── mining/      # Mining tools
├── utils/           # Utility functions and helpers
└── main.sh          # Main entry script
```

## Documentation

For more detailed documentation, please visit our [website](https://lebit.sh).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<a name="中文"></a>
# Lebit.sh - Linux系统初始化工具包

Lebit.sh提供了一系列工具，帮助您快速高效地设置和配置Linux环境。只需运行我们的一行命令安装即可开始使用。

## 可用模块

### 系统管理
系统优化、清理和信息收集工具。

```bash
curl -sSf https://lebit.sh/install | sh -s -- system
```

功能:
- 硬件信息收集
- 系统清理与深度清理
- 时间同步工具

### Docker管理
轻松安装和配置Docker环境。

```bash
curl -sSf https://lebit.sh/install | sh -s -- docker
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
curl -sSf https://lebit.sh/install | sh -s -- dev
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
curl -sSf https://lebit.sh/install | sh -s -- tools
```

功能:
- SSL证书更新工具

### 挖矿工具
加密货币挖矿操作的工具。

```bash
curl -sSf https://lebit.sh/install | sh -s -- mining
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
用户界面经过改进，提供更好的用户体验：

- 颜色编码输出，提高可读性
- 长时间运行操作的进度指示器
- 用于模块选择的交互式菜单

## 项目结构

```
lebitsh/
├── config/          # 配置文件
├── logs/            # 日志文件
├── modules/         # 所有可用模块
│   ├── core/        # 核心功能
│   ├── system/      # 系统管理工具
│   ├── docker/      # Docker工具
│   ├── dev/         # 开发环境工具
│   ├── tools/       # 系统工具
│   └── mining/      # 挖矿工具
├── utils/           # 工具函数和帮助程序
└── main.sh          # 主入口脚本
```

## 安装

安装包含所有模块的Lebit.sh：

```bash
curl -sSf https://lebit.sh/install | sh
```

直接安装特定模块：

```bash
curl -sSf https://lebit.sh/install | sh -s -- [模块名称]
```

## 文档

有关更详细的文档，请访问我们的[网站](https://lebit.sh)。

## 贡献

欢迎贡献！请随时提交Pull Request。

## 许可证

本项目采用MIT许可证 - 有关详细信息，请参阅LICENSE文件。

## 挖矿工具详细说明

### EthStorage
EthStorage是一个去中心化存储网络，允许用户通过贡献磁盘空间来获得奖励。我们的EthStorage挖矿工具提供:

- 自动安装和配置EthStorage节点
- 性能优化设置
- 存储空间管理
- 奖励统计和报告

### Ritual Coin
Ritual项目的CPU挖矿工具，针对消费级硬件优化:

- 多线程CPU挖矿
- 自动核心检测与优化
- 挖矿池集成
- 低资源消耗模式

### TitanNetwork
TitanNetwork节点设置和维护工具:

- 一键节点部署
- 自动网络配置
- 节点监控和统计
- 奖励追踪
