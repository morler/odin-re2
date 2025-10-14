# 简化代码库提案

## Why

当前代码库只有一个实际问题：`regexp/regexp.odin:216`的语法错误阻止编译。773行的单文件确实需要拆分，但不需要复杂的7阶段重构计划。

## What Changes

### 核心变更
1. **修复语法错误**: 修复`regexp/regexp.odin:216`的编译错误
2. **按功能拆分文件**: 将773行文件按功能拆分为3-4个文件
3. **确保基本测试**: 激活关键测试文件，确保功能正常

### 影响范围
- `regexp/regexp.odin` (主要文件)
- 测试文件 (激活关键测试)
- 构建系统 (确保编译通过)

## Impact
- Affected specs: regexp-core
- Affected code: regexp/regexp.odin, tests/
- **无破坏性**: 保持现有API不变