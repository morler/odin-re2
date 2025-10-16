# 精简开发计划提案

## Why

当前的`audit-code-quality`提案过于复杂，包含7个阶段39个任务，属于过度工程化。项目实际状态良好：
- ✅ 编译无错误
- ✅ 基本测试通过
- ⚠️ 仅存在少量内存泄漏（4KB测试内存）
- ⚠️ 主文件较大（801行）但功能完整

需要将复杂的7阶段重构计划精简为专注于实际问题的3个步骤。

## What Changes

### 核心变更
1. **简化任务范围**: 从39个任务减少到6个核心任务
2. **专注实际问题**: 内存泄漏修复 + 代码组织优化
3. **保持功能稳定**: 避免大规模重构破坏现有功能
4. **渐进式改进**: 分步骤实施，每步都可独立验证

### 影响范围
- `regexp/regexp.odin` - 优化代码组织，保持API兼容
- `regexp/memory.odin` - 修复内存泄漏问题
- 测试文件 - 完善测试覆盖率

## Impact

- Affected specs: regexp-core, memory-management
- Affected code: regexp/regexp.odin, regexp/memory.odin, tests/
- **无破坏性**: 保持现有API完全兼容
- **低风险**: 仅修复和优化，不重写核心算法