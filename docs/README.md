# Odin RE2 Documentation

欢迎来到 Odin RE2 项目的文档中心。这里包含了项目的完整文档，帮助您了解、使用和贡献代码。

## 📚 文档目录

### 🚀 快速开始
- [项目主页](../README.md) - 项目概述、特性和快速开始指南
- [安装指南](../README.md#installation) - 详细的安装和设置说明
- [基本用法](../README.md#basic-usage) - 简单的使用示例

### 📖 核心文档
- [项目规范](../PROJECT_STANDARDS.md) - 完整的项目规范和编码标准
- [API 文档](API.md) - 完整的 API 参考文档
- [性能指南](PERFORMANCE.md) - 性能特性和优化指南
- [开发指南](DEVELOPMENT.md) - 详细的开发指南

### 🔧 开发相关
- [贡献指南](../CONTRIBUTING.md) - 如何为项目做贡献
- [安全政策](../SECURITY.md) - 安全政策和漏洞报告
- [更新日志](../CHANGELOG.md) - 版本历史和发布说明
- [许可证](../LICENSE) - MIT 许可证条款

### 📋 参考资料
- [语法参考](SyntaxReference.md) - 正则表达式语法参考
- [使用示例](Examples.md) - 详细的使用示例和最佳实践

## 🎯 按需求查找文档

### 如果您是用户

1. **新手入门**: 从 [项目主页](../README.md) 开始
2. **学习 API**: 查看 [API 文档](API.md)
3. **性能优化**: 阅读 [性能指南](PERFORMANCE.md)
4. **语法参考**: 使用 [语法参考](SyntaxReference.md)

### 如果您是开发者

1. **开发环境**: 查看 [开发指南](DEVELOPMENT.md)
2. **代码规范**: 遵循 [项目规范](../PROJECT_STANDARDS.md)
3. **贡献代码**: 按照 [贡献指南](../CONTRIBUTING.md)
4. **安全考虑**: 了解 [安全政策](../SECURITY.md)

### 如果您正在调试

1. **性能问题**: 参考 [性能指南](PERFORMANCE.md)
2. **API 使用**: 查看 [API 文档](API.md)
3. **测试方法**: 阅读 [开发指南](DEVELOPMENT.md#测试策略)

## 📊 项目状态

### 当前版本: v0.3.0

### 核心特性
- ✅ 线性时间匹配保证
- ✅ 高性能状态向量优化 (2253 MB/s)
- ✅ ASCII 快速路径 (95% 优化)
- ✅ Unicode 属性支持
- ✅ 内存池管理
- ✅ RE2 兼容性

### 性能指标
| 特性 | 性能 | 状态 |
|------|------|------|
| 状态向量优化 | 2253 MB/s | ✅ |
| ASCII 快速路径 | O(1) per char | ✅ |
| Unicode 属性 | O(1) lookup | ✅ |
| 编译速度 | 1800-11600ns | ✅ |

## 🔍 文档导航

### 按主题浏览

#### 🚀 性能优化
- [性能指南](PERFORMANCE.md) - 完整的性能分析
- [开发指南 - 性能优化](DEVELOPMENT.md#性能优化) - 开发中的性能技巧
- [项目规范 - 性能规范](../PROJECT_STANDARDS.md#性能规范) - 性能要求和测试

#### 🔧 开发工作流
- [开发指南](DEVELOPMENT.md) - 完整的开发流程
- [贡献指南](../CONTRIBUTING.md) - 贡献流程和规范
- [项目规范](../PROJECT_STANDARDS.md) - 编码规范和标准

#### 🛡️ 安全性
- [安全政策](../SECURITY.md) - 安全政策和最佳实践
- [开发指南 - 安全考虑](DEVELOPMENT.md#安全考虑) - 开发中的安全注意事项

#### 🧪 测试
- [开发指南 - 测试策略](DEVELOPMENT.md#测试策略) - 测试方法和策略
- [项目规范 - 测试规范](../PROJECT_STANDARDS.md#测试规范) - 测试要求和规范

## 📝 文档贡献

### 如何改进文档

1. **报告问题**: 在 GitHub Issues 中报告文档问题
2. **提交改进**: 按照 [贡献指南](../CONTRIBUTING.md) 提交文档改进
3. **翻译贡献**: 帮助翻译文档到其他语言

### 文档规范

- 使用 Markdown 格式
- 包含可运行的代码示例
- 提供清晰的步骤说明
- 保持与代码同步更新

## 🔗 外部资源

### 相关项目
- [Google RE2](https://github.com/google/re2) - 原始 RE2 实现
- [Odin 语言](https://odin-lang.org/) - 编程语言官网
- [Unicode 标准](https://unicode.org/) - Unicode 官方标准

### 工具和资源
- [Odin 文档](https://odin-lang.org/docs/) - Odin 语言文档
- [Regex101](https://regex101.com/) - 正则表达式测试工具
- [Unicode Explorer](https://unicode-explorer.com/) - Unicode 字符查询

## 📞 获取帮助

### 社区支持
- **GitHub Issues**: 报告错误和请求功能
- **GitHub Discussions**: 一般讨论和问题
- **文档反馈**: 在文档仓库中提交问题

### 联系方式
- **安全问题**: security@odin-re2.org
- **一般问题**: GitHub Issues
- **媒体咨询**: press@odin-re2.org

## 🗂️ 文档结构

```
docs/
├── README.md              # 文档导航 (本文件)
├── API.md                 # API 参考文档
├── PERFORMANCE.md         # 性能指南
├── DEVELOPMENT.md         # 开发指南
├── SyntaxReference.md     # 语法参考
└── Examples.md            # 使用示例

../
├── README.md              # 项目主页
├── PROJECT_STANDARDS.md   # 项目规范
├── CONTRIBUTING.md        # 贡献指南
├── SECURITY.md            # 安全政策
├── CHANGELOG.md           # 更新日志
└── LICENSE                # 许可证
```

---

感谢您使用 Odin RE2！如有任何问题或建议，请随时联系我们。