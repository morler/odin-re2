# Development Guide

本文档为 Odin RE2 项目的开发者提供详细的开发指南。

## 开发环境

### 系统要求

- **操作系统**: Windows (MSYS2), Linux, macOS
- **Odin 编译器**: v2024.09 或更高版本
- **Git**: v2.30 或更高版本
- **Make**: GNU Make 4.0 或更高版本

### 环境设置

#### Windows (MSYS2)

```bash
# 安装 MSYS2
# 从 https://www.msys2.org/ 下载并安装

# 安装必要的包
pacman -S mingw-w64-x86_64-toolchain
pacman -S mingw-w64-x86_64-odin
pacman -S git
pacman -S make

# 设置环境变量
echo 'export PATH="/mingw64/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential git

# 安装 Odin 编译器
# 从 https://odin-lang.org/ 下载最新版本

# 添加到 PATH
echo 'export PATH="/path/to/odin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### macOS

```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装工具
brew install git make

# 安装 Odin 编译器
# 从 https://odin-lang.org/ 下载最新版本

# 添加到 PATH
echo 'export PATH="/path/to/odin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## 项目架构

### 核心组件

```
regexp/
├── regexp.odin          # 主 API 接口
├── parser.odin           # 正则表达式解析器
├── matcher.odin          # NFA 匹配引擎
├── inst.odin             # 指令集定义
├── ast.odin              # 抽象语法树
├── unicode.odin          # Unicode 支持
├── utf8_optimized.odin   # UTF-8 优化
├── memory.odin           # 内存池管理
├── errors.odin           # 错误处理
└── sparse_set.odin       # 稀疏集合数据结构
```

### 数据流

```
Pattern String → Parser → AST → Compiler → NFA Program → Matcher → Match Result
```

### 关键数据结构

#### Regexp (AST 节点)

```odin
Regexp :: struct {
    op: Op,
    flags: Flags,
    sub: []^Regexp,  // 子表达式
    rune: []rune,    // 字面量
    cap: int,        // 捕获组编号
    name: string,    // 命名捕获组
}
```

#### Program (NFA 程序)

```odin
Program :: struct {
    inst: []Inst,    // 指令序列
    start: int,      // 起始指令
    num_cap: int,    // 捕获组数量
    arena: ^Arena,   // 内存池
}
```

#### Matcher (匹配器)

```odin
Matcher :: struct {
    prog: ^Program,
    arena: ^Arena,
    state_vector: State_Vector,
    input: string,
    pos: int,
}
```

## 开发工作流

### 1. 获取代码

```bash
git clone https://github.com/your-repo/odin-re2.git
cd odin-re2
```

### 2. 创建开发分支

```bash
git checkout -b feature/your-feature-name
```

### 3. 开发和测试

#### 构建项目

```bash
# 开发构建
odin build .

# 发布构建
odin build . -o:speed

# 调试构建
odin build . -debug
```

#### 运行测试

```bash
# 单元测试
odin test .

# 集成测试
odin test run_tests.odin

# 性能测试
odin run benchmark/performance_benchmark.odin

# 特定测试
odin run tests/test_unicode_properties.odin
```

#### 代码检查

```bash
# 格式化代码
odin fmt .

# 静态分析
odin check . -vet -vet-style

# 查看生成的汇编
odin build . -o:speed -emit-asm
```

### 4. 提交更改

```bash
git add .
git commit -m "feat: add your feature description"
git push origin feature/your-feature-name
```

## 调试技巧

### 调试构建

```bash
# 启用调试信息
odin build . -debug -o:debug

# 运行调试版本
./debug.exe
```

### 日志输出

```odin
import "core:fmt"

// 在关键位置添加调试输出
fmt.printf("DEBUG: Processing character %c at position %d\n", ch, pos)

// 使用条件编译
when ODIN_DEBUG {
    fmt.printf("DEBUG: State vector size: %d\n", state_vector.size)
}
```

### 性能分析

```bash
# 启用性能分析
odin build . -o:speed -profile

# 运行并生成分析报告
./odin-re2.exe > profile.txt
```

### 内存调试

```odin
// 内存池使用情况
arena := regexp.new_arena()
// ... 使用内存池
stats := regexp.get_arena_stats(arena)
fmt.printf("Memory used: %d bytes\n", stats.used)
```

## 性能优化

### 性能分析工具

```bash
# 基准测试
odin run benchmark/performance_benchmark.odin

# 性能对比
odin run benchmark/simple_comparison.odin

# 内存分析
odin run tests/test_memory_management.odin
```

### 优化策略

#### 1. 热路径优化

```odin
// 内联关键函数
@(inline)
is_ascii_fast :: proc(ch: rune) -> bool {
    return ch < 128
}

// 使用位操作
@(inline)
set_state_bit :: proc(vector: ^State_Vector, state: int) {
    block := state / 64
    bit := state % 64
    vector.bits[block] |= 1 << bit
}
```

#### 2. 内存优化

```odin
// 预分配缓冲区
BUFFER_SIZE :: 1024
buffer: [BUFFER_SIZE]byte

// 使用内存池
arena := regexp.new_arena()
program := regexp.compile_nfa(ast, arena)
// arena 自动清理
```

#### 3. 缓存优化

```odin
// 64 字节对齐
State_Vector :: struct #align(64) {
    bits: []u64,
    count: u32,
    size: u32,
}

// 数据局部性
Matcher :: struct {
    // 经常访问的数据放在一起
    prog: ^Program,
    pos: int,
    input: string,
    // 不常访问的数据放后面
    stats: Matcher_Stats,
}
```

## 测试策略

### 测试分类

#### 1. 单元测试

```odin
@(test)
test_parser_basic :: proc() {
    pattern := "a+b"
    ast, err := regexp.parse_regexp_internal(pattern, {})
    assert(err == .NoError)
    assert(ast != nil)
    assert(ast.op == .OpConcat)
}
```

#### 2. 集成测试

```odin
@(test)
test_full_match :: proc() {
    arena := regexp.new_arena()
    pattern := "hello\\s+world"
    
    ast, err := regexp.parse_regexp_internal(pattern, {})
    assert(err == .NoError)
    
    prog, err := regexp.compile_nfa(ast, arena)
    assert(err == .NoError)
    
    matcher := regexp.new_matcher(prog, false, true)
    matched, caps := regexp.match_nfa(matcher, "hello   world")
    assert(matched)
    assert(caps[0] == 0)
    assert(caps[1] == len("hello   world"))
}
```

#### 3. 性能测试

```odin
@(test)
test_performance_simple :: proc() {
    arena := regexp.new_arena()
    pattern := "[a-z]+"
    text := "abcdefghijklmnopqrstuvwxyz" * 1000
    
    start := time.now()
    
    for i in 0..<1000 {
        matcher := regexp.new_matcher(program, false, true)
        matched, _ := regexp.match_nfa(matcher, text)
        assert(matched)
    }
    
    duration := time.since(start)
    fmt.printf("Performance: %v\n", duration)
}
```

#### 4. 边界测试

```odin
@(test)
test_edge_cases :: proc() {
    // 空字符串
    test_empty_string()
    
    // 极长字符串
    test_very_long_string()
    
    // 无效 UTF-8
    test_invalid_utf8()
    
    // 复杂嵌套
    test_complex_nesting()
}
```

### 测试数据管理

```odin
// 测试数据结构
Test_Case :: struct {
    pattern: string,
    input:   string,
    expect:  bool,
    captures: []int,
}

// 测试用例数组
TEST_CASES :: []Test_Case {
    {"a", "a", true, []int{0, 1}},
    {"a", "b", false, nil},
    {"a+", "aaa", true, []int{0, 3}},
    // ... 更多测试用例
}
```

## 文档编写

### 代码文档

```odin
// ============================================================================
// UNICODE SUPPORT MODULE
// ============================================================================
// 提供 Unicode 字符属性和脚本检测功能
// 支持 Unicode 15.0 标准
// ============================================================================

// get_unicode_category :: proc(ch: rune) -> Unicode_Category
// 获取字符的 Unicode 类别
// 参数:
//   - ch: 要检查的字符
// 返回值: 字符的 Unicode 类别
// 注意: 对于 ASCII 字符使用快速路径优化
get_unicode_category :: proc(ch: rune) -> Unicode_Category {
    // ASCII 快速路径 (95% 的情况)
    if ch < 128 {
        return get_ascii_category(ch)
    }
    
    // Unicode 处理路径
    return lookup_unicode_category(ch)
}
```

### API 文档

```markdown
## API Reference

### regexp.parse_regexp_internal

```odin
parse_regexp_internal :: proc(pattern: string, flags: Parse_Flags) -> (^Regexp, ErrorCode)
```

解析正则表达式模式为抽象语法树。

**参数:**
- `pattern`: 正则表达式字符串
- `flags`: 解析标志

**返回值:**
- `^Regexp`: 解析后的 AST，失败时为 nil
- `ErrorCode`: 错误代码

**示例:**
```odin
ast, err := regexp.parse_regexp_internal("a+b", {})
if err != .NoError {
    // 处理错误
}
```
```

## 发布流程

### 版本准备

1. **更新版本号**
```odin
// 在 version.odin 中
VERSION :: "0.3.0"
```

2. **更新 CHANGELOG**
```markdown
## [0.3.0] - 2024-10-22

### 新增
- 状态向量优化
- ASCII 快速路径
```

3. **运行完整测试**
```bash
make test
make check
make benchmark
```

### 发布构建

```bash
# 清理构建目录
make clean

# 构建发布版本
odin build . -o:speed -out:odin-re2-v0.3.0

# 运行最终测试
./odin-re2-v0.3.0 --test-all
```

### 创建发布

```bash
# 创建 Git 标签
git tag -a v0.3.0 -m "Release version 0.3.0"
git push origin v0.3.0

# 创建 GitHub Release
gh release create v0.3.0 \
    --title "Odin RE2 v0.3.0" \
    --notes "See CHANGELOG.md for details" \
    odin-re2-v0.3.0.exe
```

## 故障排除

### 常见问题

#### 1. 编译错误

```bash
# 检查 Odin 版本
odin version

# 清理并重新构建
make clean
odin build . -o:speed
```

#### 2. 测试失败

```bash
# 运行特定测试
odin run tests/test_failing_test.odin

# 启用详细输出
odin test . -verbose
```

#### 3. 性能问题

```bash
# 运行性能分析
odin build . -o:speed -profile
./odin-re2.exe > profile.txt

# 比较基准测试
odin run benchmark/performance_benchmark.odin
```

### 调试技巧

1. **使用断言**
```odin
assert(condition, "Error message")
```

2. **添加日志**
```odin
when ODIN_DEBUG {
    fmt.printf("Debug: %v\n", variable)
}
```

3. **内存检查**
```odin
// 检查内存池状态
stats := regexp.get_arena_stats(arena)
fmt.printf("Used: %d, Capacity: %d\n", stats.used, stats.capacity)
```

## 社区资源

### 获取帮助

- **GitHub Issues**: 报告错误和请求功能
- **GitHub Discussions**: 一般讨论和问题
- **文档**: [docs/](../docs/) 目录下的详细文档
- **示例**: [examples/](../examples/) 目录下的使用示例

### 贡献指南

- [CONTRIBUTING.md](../CONTRIBUTING.md): 贡献流程和规范
- [PROJECT_STANDARDS.md](../PROJECT_STANDARDS.md): 项目规范
- [SECURITY.md](../SECURITY.md): 安全政策

---

欢迎为 Odin RE2 项目做出贡献！如有问题，请随时联系开发团队。