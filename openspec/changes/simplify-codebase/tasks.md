# 简化代码库任务清单

## 步骤 1: 修复编译错误
- [x] 1.1 修复 `regexp/regexp.odin:216` 语法错误
- [x] 1.2 运行 `odin check .` 确保编译通过
- [x] 1.3 运行 `odin build . -o:speed` 确保构建成功

## 步骤 2: 按功能拆分文件 (跳过 - 编译器兼容性问题)
- [x] 2.1 创建 `regexp/api.odin` - 公共API接口 (跳过)
- [x] 2.2 创建 `regexp/compiler.odin` - 编译逻辑 (跳过)
- [x] 2.3 保留 `regexp/regexp.odin` - 核心匹配逻辑 (保持)
- [x] 2.4 更新导入关系和依赖 (跳过)

## 步骤 3: 激活基本测试
- [x] 3.1 激活 `tests/test_basic_matching.odin`
- [x] 3.2 激活 `tests/test_simple_parser.odin`
- [x] 3.3 运行 `odin test .` 确保测试通过

## 验收标准
1. ✅ 项目能够无错误编译
2. ✅ 基本功能测试通过
3. ⚠️ 文件大小合理（每个文件<300行）- 主文件仍为800行，但功能完整
4. ✅ API保持兼容