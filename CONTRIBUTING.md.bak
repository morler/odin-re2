# Contributing to Odin RE2

感谢您对 Odin RE2 项目的关注！本文档将指导您如何为项目做出贡献。

## 开发环境设置

### 系统要求

- **操作系统**: Windows (MSYS2), Linux, macOS
- **Odin 编译器**: 最新稳定版
- **Git**: 用于版本控制

### 设置步骤

1. **克隆仓库**
```bash
git clone https://github.com/your-repo/odin-re2.git
cd odin-re2
```

2. **验证环境**
```bash
# 检查 Odin 编译器
odin version

# 构建项目
odin build . -o:speed

# 运行测试
odin test .
```

3. **开发工具配置**
```bash
# 安装开发依赖（如果需要）
make deps

# 设置 Git hooks（可选）
cp scripts/pre-commit .git/hooks/
```

## 贡献流程

### 1. 选择任务

- 查看 [Issues](https://github.com/your-repo/odin-re2/issues) 中的开放任务
- 寻找标记为 `good first issue` 的任务
- 或提出新的功能建议

### 2. 创建分支

```bash
# 从 main 分支创建功能分支
git checkout main
git pull origin main
git checkout -b feature/your-feature-name

# 或创建修复分支
git checkout -b fix/issue-number-description
```

### 3. 开发和测试

#### 编码规范

请遵循 [PROJECT_STANDARDS.md](PROJECT_STANDARDS.md) 中定义的编码规范：

- 使用 `lower_snake_case` 命名过程和变量
- 使用 `UpperCamelCase` 命名类型
- 保持 100 字符行长度限制
- 使用 Tab 缩进

#### 测试要求

```bash
# 运行所有测试
odin test .

# 运行集成测试
odin test run_tests.odin

# 运行性能测试
odin run benchmark/performance_benchmark.odin

# 代码格式化
odin fmt .

# 代码检查
odin check . -vet -vet-style
```

#### 测试编写

为每个新功能编写测试：

```odin
@(test)
test_your_new_feature :: proc() {
    // 设置
    arena := regexp.new_arena()
    
    // 测试
    pattern := "your_test_pattern"
    ast, err := regexp.parse_regexp_internal(pattern, {})
    
    // 验证
    assert(err == .NoError)
    assert(ast != nil)
    
    // 清理（arena 自动处理）
}
```

### 4. 提交更改

#### 提交信息格式

```
<type>: <summary>

<body>

<footer>
```

**类型说明**:
- `feat`: 新功能
- `fix`: 错误修复
- `perf`: 性能优化
- `docs`: 文档更新
- `style`: 代码风格
- `refactor`: 重构
- `test`: 测试相关

**示例**:
```
feat: add Unicode script support for Arabic

- Implement Arabic script detection using range matching
- Add Unicode property lookup for Arabic characters
- Update performance benchmarks with Arabic text
- Add comprehensive test cases for Arabic matching

Closes #123
```

#### 提交步骤

```bash
# 添加更改
git add .

# 提交（确保信息格式正确）
git commit -m "feat: add your feature description"

# 推送到分支
git push origin feature/your-feature-name
```

### 5. 创建 Pull Request

#### PR 要求

- 标题清晰描述更改
- 描述中包含：
  - 更改的目的和动机
  - 实现方法的简要说明
  - 测试覆盖情况
  - 性能影响（如适用）
- 引用相关的 Issue
- 包含测试结果或基准测试数据

#### PR 模板

```markdown
## 描述
简要描述此 PR 的目的和实现的功能。

## 更改类型
- [ ] Bug 修复
- [ ] 新功能
- [ ] 性能优化
- [ ] 文档更新
- [ ] 重构
- [ ] 其他: ___________

## 测试
- [ ] 所有现有测试通过
- [ ] 添加了新的测试用例
- [ ] 性能基准测试通过（如适用）

## 检查清单
- [ ] 代码遵循项目规范
- [ ] 已运行 `odin fmt .`
- [ ] 已运行 `odin check . -vet -vet-style`
- [ ] 文档已更新（如需要）
- [ ] 提交信息格式正确

## 相关 Issue
Closes #issue_number

## 其他信息
任何其他相关信息或注意事项。
```

## 开发指南

### 项目结构理解

请熟悉以下关键模块：

- **regexp/regexp.odin**: 主要 API 接口
- **regexp/parser.odin**: 正则表达式解析器
- **regexp/matcher.odin**: NFA 匹配引擎
- **regexp/unicode.odin**: Unicode 支持
- **regexp/memory.odin**: 内存池管理

### 性能考虑

Odin RE2 专注于性能，请遵循以下原则：

1. **内存效率**: 使用内存池避免堆分配
2. **算法复杂度**: 保持 O(n) 线性时间
3. **缓存友好**: 使用 64 字节对齐的数据结构
4. **ASCII 优化**: 优先处理 ASCII 字符（95% 情况）

### 调试技巧

```bash
# 调试构建
odin build . -debug -o:debug

# 运行调试版本
./debug.exe

# 性能分析
odin build . -o:speed -profile
```

### 常见开发任务

#### 添加新的 Unicode 支持

1. 在 `regexp/unicode.odin` 中添加脚本范围
2. 更新 Unicode 属性查找表
3. 添加相应的测试用例
4. 更新性能基准测试

#### 性能优化

1. 识别性能瓶颈
2. 实现优化方案
3. 运行基准测试验证
4. 更新 `docs/PERFORMANCE.md`

#### 错误修复

1. 重现问题
2. 编写最小测试用例
3. 修复根本原因
4. 确保所有测试通过

## 代码审查

### 审查标准

Pull Request 将按以下标准审查：

1. **功能正确性**: 代码按预期工作
2. **测试覆盖**: 充分的测试用例
3. **性能影响**: 不显著影响性能
4. **代码质量**: 遵循项目规范
5. **文档完整性**: 必要的文档更新
6. **向后兼容**: 不破坏现有 API

### 审查流程

1. 自动化检查（CI/CD）
2. 维护者人工审查
3. 反馈和修改
4. 批准和合并

## 社区准则

### 行为准则

- 尊重所有贡献者
- 保持友好和专业的交流
- 接受建设性的反馈
- 专注于对社区最有利的事情

### 沟通渠道

- **GitHub Issues**: 错误报告和功能请求
- **GitHub Discussions**: 一般讨论和问题
- **Pull Requests**: 代码审查和讨论

## 获得帮助

如果您需要帮助：

1. 查看现有文档和示例
2. 搜索已有的 Issues 和 Discussions
3. 创建新的 Discussion 寻求帮助
4. 在 PR 中标记 `@maintainers` 请求审查

## 认可贡献者

所有贡献者都会在项目中得到认可：

- README 中的贡献者列表
- 发布说明中的致谢
- 代码提交历史中的记录

感谢您为 Odin RE2 项目做出贡献！您的参与使这个项目变得更好。

---

如有任何问题，请随时通过 GitHub Issues 或 Discussions 联系我们。