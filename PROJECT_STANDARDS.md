# Odin RE2 项目规范文档

## 项目概述

Odin RE2 是一个用 Odin 语言实现的高性能正则表达式引擎，兼容 Google RE2 语法，提供线性时间匹配保证。该项目专注于性能优化、内存效率和 Unicode 支持。

## 项目架构

### 核心模块结构

```
odin-re2/
├── regexp/                    # 核心引擎实现
│   ├── regexp.odin           # 主要 API 和公共接口
│   ├── parser.odin           # 正则表达式解析器
│   ├── matcher.odin          # NFA 匹配引擎
│   ├── inst.odin             # 指令集定义
│   ├── ast.odin              # 抽象语法树
│   ├── unicode.odin          # Unicode 支持
│   ├── utf8_optimized.odin   # UTF-8 优化
│   ├── memory.odin           # 内存池管理
│   ├── errors.odin           # 错误处理
│   └── sparse_set.odin       # 稀疏集合数据结构
├── src/                      # 源代码副本（与 regexp/ 同步）
├── tests/                    # 测试套件
│   ├── run_tests.odin        # 测试运行器
│   ├── test_*.odin           # 功能测试文件
│   └── test_*.odin.bak       # 自动化管理的测试源文件
├── examples/                 # 使用示例
├── benchmark/                # 性能基准测试
│   ├── performance_benchmark.odin
│   ├── functional_compare.odin
│   └── results/              # 基准测试结果
├── docs/                     # 文档
│   ├── API.md               # API 文档
│   ├── PERFORMANCE.md       # 性能指南
│   ├── SyntaxReference.md   # 语法参考
│   └── Examples.md          # 示例文档
└── openspec/                 # 开放规范
    ├── AGENTS.md            # AI 助手指南
    └── project.md           # 项目规范
```

## 编码规范

### 命名约定

- **包名**: `lower_snake_case` (如: `regexp`)
- **过程名**: `lower_snake_case` (如: `new_matcher`, `parse_regexp_internal`)
- **类型名**: `UpperCamelCase` (如: `Matcher`, `Regexp`, `ErrorCode`)
- **常量**: `UPPER_SNAKE_CASE` (如: `ASCII_CHAR_TABLE_DATA`)
- **变量**: `lower_snake_case` (如: `arena`, `program`, `matcher`)

### 代码风格

- **缩进**: 使用 Tab 字符，4 个空格宽度
- **行长度**: 最大 100 字符
- **注释**: 使用 `//` 进行单行注释，`/* */` 进行多行注释
- **文件组织**: 按功能模块组织，每个文件专注单一职责

### 文档注释

```odin
// ============================================================================
// 模块功能描述
// ============================================================================
// 详细说明模块的用途、主要功能和设计决策
// ============================================================================

// Procedure_Name :: proc(param1: Type1, param2: Type2) -> ReturnType
// 功能描述：简要说明过程的作用
// 参数说明：
//   - param1: 参数1的说明
//   - param2: 参数2的说明
// 返回值：返回值的说明
// 注意事项：特殊用法或限制
```

## 构建和开发规范

### 构建命令

```bash
# 构建发布版本
odin build . -o:speed

# 运行单元测试
odin test .

# 运行集成测试
odin test run_tests.odin

# 运行性能基准测试
odin run benchmark/performance_benchmark.odin

# 代码格式化
odin fmt .

# 代码检查
odin check . -vet -vet-style
```

### Makefile 目标

- `lib`: 构建正则表达式库
- `test`: 运行所有测试
- `check`: 检查代码语法和风格
- `examples`: 构建示例程序
- `clean`: 清理构建产物
- `help`: 显示帮助信息

## 测试规范

### 测试分类

1. **单元测试**: 测试单个模块功能
2. **集成测试**: 测试模块间协作
3. **性能测试**: 验证性能指标
4. **兼容性测试**: 确保 RE2 兼容性

### 测试文件命名

- `test_<feature>.odin`: 功能测试文件
- `test_<feature>_performance.odin`: 性能测试文件
- `test_<feature>_compatibility.odin`: 兼容性测试文件

### 测试编写规范

```odin
@(test)
test_feature_name :: proc() {
    // 测试设置
    arena := regexp.new_arena()
    
    // 测试执行
    pattern := "test_pattern"
    ast, err := regexp.parse_regexp_internal(pattern, {})
    
    // 断言验证
    assert(err == .NoError)
    assert(ast != nil)
    
    // 清理（如果需要）
    // arena 会自动清理
}
```

## 性能规范

### 性能目标

- **匹配性能**: 达到 Google RE2 的 85%+
- **编译速度**: 比 RE2 快 2x+
- **内存效率**: 减少 50%+ 内存使用
- **时间复杂度**: 保证 O(n) 线性时间

### 性能优化技术

1. **状态向量优化**: 64 字节对齐的位向量
2. **ASCII 快速路径**: 95% 的 ASCII 字符优化处理
3. **Unicode 属性优化**: O(1) Unicode 属性查找
4. **内存池管理**: 消除内存碎片
5. **UTF-8 解码优化**: 快速 UTF-8 解码器

### 性能测试要求

- 所有性能更改必须通过基准测试验证
- 使用 `benchmark/performance_benchmark.odin` 进行测试
- 记录性能变化并更新 `docs/PERFORMANCE.md`

## 内存管理规范

### 内存池使用

```odin
// 创建内存池
arena := regexp.new_arena()

// 使用内存池进行分配
program, err := regexp.compile_nfa(ast, arena)

// 内存池会自动清理，无需手动释放
```

### 内存分配原则

- 优先使用内存池分配
- 避免在热路径中进行堆分配
- 使用预分配的缓冲区
- 确保内存对齐（64 字节边界）

## Unicode 支持规范

### Unicode 版本

- 支持 Unicode 15.0
- 实现常用 Unicode 属性
- 支持脚本检测和分类

### Unicode 优化

- ASCII 快速路径（95% 的情况）
- 脚本特定的范围检查
- 优化的字符类匹配

## API 设计规范

### 公共 API

```odin
// 内存管理
new_arena :: proc() -> ^Arena

// 模式编译
parse_regexp_internal :: proc(pattern: string, flags: Parse_Flags) -> (^Regexp, ErrorCode)
compile_nfa :: proc(ast: ^Regexp, arena: ^Arena) -> (^Program, ErrorCode)

// 匹配执行
new_matcher :: proc(prog: ^Program, anchored: bool, longest: bool) -> ^Matcher
match_nfa :: proc(matcher: ^Matcher, text: string) -> (bool, []int)
```

### 错误处理

```odin
ErrorCode :: enum {
    NoError,
    ParseError,
    CompileError,
    MatchError,
    // ...
}
```

## 版本控制规范

### 分支策略

- `main`: 主分支，稳定版本
- `develop`: 开发分支
- `feature/*`: 功能分支
- `hotfix/*`: 热修复分支

### 提交信息格式

```
<type>: <summary>

<body>

<footer>
```

**类型 (type)**:
- `feat`: 新功能
- `fix`: 错误修复
- `perf`: 性能优化
- `docs`: 文档更新
- `style`: 代码风格
- `refactor`: 重构
- `test`: 测试相关

**示例**:
```
feat: add Unicode script support for Cyrillic

- Implement Cyrillic script detection
- Add range-based character matching
- Update performance benchmarks

Closes #123
```

## 文档规范

### 文档结构

1. **README.md**: 项目概述和快速开始
2. **API.md**: 完整 API 参考
3. **PERFORMANCE.md**: 性能特性和优化
4. **SyntaxReference.md**: 语法参考
5. **Examples.md**: 使用示例

### 文档编写规范

- 使用 Markdown 格式
- 代码示例必须可运行
- 包含性能指标和基准测试结果
- 提供清晰的用法说明

## 兼容性规范

### RE2 兼容性

- 支持 RE2 语法子集
- 保证线性时间复杂度
- 不支持回引用和环视断言
- 遵循 RE2 的设计原则

### 平台兼容性

- Windows (MSYS2)
- Linux
- macOS

## 安全规范

### 内存安全

- 使用内存池防止缓冲区溢出
- 边界检查和验证
- 避免未初始化内存访问

### 输入验证

- 验证正则表达式语法
- 检查 UTF-8 编码有效性
- 防止恶意模式导致的性能问题

## 发布规范

### 版本号格式

使用语义化版本控制：`MAJOR.MINOR.PATCH`

- `MAJOR`: 不兼容的 API 更改
- `MINOR`: 向后兼容的功能添加
- `PATCH`: 向后兼容的错误修复

### 发布检查清单

- [ ] 所有测试通过
- [ ] 性能基准测试达标
- [ ] 文档更新完成
- [ ] 代码格式化检查通过
- [ ] 版本号更新
- [ ] 更新日志编写

## 贡献规范

### 贡献流程

1. Fork 项目
2. 创建功能分支
3. 编写代码和测试
4. 运行完整测试套件
5. 提交 Pull Request
6. 代码审查
7. 合并到主分支

### 代码审查标准

- 代码风格符合规范
- 测试覆盖率充足
- 性能影响可接受
- 文档更新完整
- 向后兼容性保证

## 工具和依赖

### 开发工具

- **Odin 编译器**: 最新稳定版
- **构建系统**: Odin 内置构建系统 + Makefile
- **代码格式化**: `odin fmt`
- **代码检查**: `odin check`

### 外部依赖

- 无外部依赖
- 仅使用 Odin 标准库
- 自包含实现

## 故障排除

### 常见问题

1. **编译错误**: 检查 Odin 版本兼容性
2. **性能下降**: 运行基准测试对比
3. **测试失败**: 检查测试环境和依赖
4. **内存问题**: 使用内存池调试工具

### 调试技巧

- 使用 `odin build -debug` 进行调试构建
- 启用详细日志输出
- 使用性能分析工具
- 检查内存池使用情况

---

本规范文档将随着项目发展持续更新。所有贡献者应遵循这些规范以确保项目质量和一致性。