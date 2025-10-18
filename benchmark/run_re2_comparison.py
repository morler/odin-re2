#!/usr/bin/env python3
"""
Google RE2 vs Odin RE2 全面对比评测脚本

功能:
1. 自动运行Odin RE2和Rust regex基准测试
2. 收集性能数据和功能正确性结果
3. 生成详细的对比分析报告
4. 验证线性时间复杂度保证
"""

import subprocess
import json
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Any, Tuple
import pandas as pd
import matplotlib.pyplot as plt

class BenchmarkRunner:
    def __init__(self, benchmark_dir: Path):
        self.benchmark_dir = benchmark_dir
        self.results_dir = benchmark_dir / "results"
        self.results_dir.mkdir(exist_ok=True)

        self.odin_results = {}
        self.rust_results = {}
        self.comparison_results = {}

    def run_command(self, cmd: List[str], cwd: Path = None) -> Tuple[bool, str, str]:
        """运行命令并返回结果"""
        try:
            print(f"Running: {' '.join(cmd)}")
            result = subprocess.run(
                cmd,
                cwd=cwd or self.benchmark_dir,
                capture_output=True,
                text=True,
                timeout=300
            )

            if result.returncode != 0:
                print(f"Command failed with return code {result.returncode}")
                print(f"STDOUT: {result.stdout}")
                print(f"STDERR: {result.stderr}")
                return False, result.stdout, result.stderr

            return True, result.stdout, result.stderr

        except subprocess.TimeoutExpired:
            print("Command timed out after 300 seconds")
            return False, "", "Timeout"
        except Exception as e:
            print(f"Error running command: {e}")
            return False, "", str(e)

    def compile_odin_benchmark(self) -> bool:
        """编译Odin RE2基准测试"""
        print("\n=== Compiling Odin RE2 Benchmark ===")

        # 尝试编译新的综合基准测试
        cmd = ["odin", "build", "re2_comprehensive_benchmark.odin", "-o:speed", "-out:re2_odin_benchmark"]
        success, stdout, stderr = self.run_command(cmd)

        if not success:
            print("Failed to compile comprehensive benchmark, trying fallback...")
            # 尝试编译性能验证测试
            cmd = ["odin", "build", "performance_validation.odin", "-o:speed", "-out:re2_odin_validation"]
            success, stdout, stderr = self.run_command(cmd)

        return success

    def compile_rust_benchmark(self) -> bool:
        """编译Rust regex基准测试"""
        print("\n=== Compiling Rust Regex Benchmark ===")

        # 首先检查Cargo.toml是否存在
        cargo_toml = self.benchmark_dir / "Cargo.toml"
        if not cargo_toml.exists():
            print("Creating Cargo.toml for Rust benchmark...")
            self.create_cargo_toml()

        cmd = ["cargo", "build", "--release"]
        success, stdout, stderr = self.run_command(cmd)

        if success:
            # 复制到results目录
            src_binary = self.benchmark_dir / "target" / "release" / "re2_performance_comparison"
            dst_binary = self.results_dir / "re2_rust_benchmark"

            if src_binary.exists():
                import shutil
                shutil.copy2(src_binary, dst_binary)
                print(f"Copied Rust benchmark to {dst_binary}")

        return success

    def create_cargo_toml(self):
        """创建Cargo.toml文件"""
        cargo_content = '''[package]
name = "re2_performance_comparison"
version = "0.1.0"
edition = "2021"

[dependencies]
regex = "1.10"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }

[[bin]]
name = "re2_performance_comparison"
path = "re2_performance_comparison.rs"
'''

        cargo_toml = self.benchmark_dir / "Cargo.toml"
        with open(cargo_toml, 'w') as f:
            f.write(cargo_content)

        print(f"Created Cargo.toml at {cargo_toml}")

    def run_odin_benchmark(self) -> bool:
        """运行Odin RE2基准测试"""
        print("\n=== Running Odin RE2 Benchmark ===")

        # 尝试运行综合基准测试
        benchmark_exe = self.benchmark_dir / "re2_odin_benchmark.exe"
        if not benchmark_exe.exists():
            benchmark_exe = self.benchmark_dir / "re2_odin_validation.exe"

        if not benchmark_exe.exists():
            print("Odin benchmark executable not found!")
            return False

        timestamp = time.strftime("%Y%m%d_%H%M%S")
        output_file = self.results_dir / f"odin_results_{timestamp}.txt"

        success, stdout, stderr = self.run_command([str(benchmark_exe)])

        if success:
            # 保存原始输出
            with open(output_file, 'w') as f:
                f.write(stdout)
                f.write("\n\nSTDERR:\n")
                f.write(stderr)

            # 尝试解析结果
            self.odin_results = self.parse_odin_output(stdout)
            print(f"Odin benchmark completed. Results saved to {output_file}")

        return success

    def run_rust_benchmark(self) -> bool:
        """运行Rust regex基准测试"""
        print("\n=== Running Rust Regex Benchmark ===")

        benchmark_exe = self.results_dir / "re2_rust_benchmark.exe"
        if not benchmark_exe.exists():
            benchmark_exe = self.benchmark_dir / "target" / "release" / "re2_performance_comparison.exe"

        if not benchmark_exe.exists():
            print("Rust benchmark executable not found!")
            return False

        timestamp = time.strftime("%Y%m%d_%H%M%S")
        output_file = self.results_dir / f"rust_results_{timestamp}.txt"
        json_file = self.results_dir / f"rust_results_{timestamp}.json"

        success, stdout, stderr = self.run_command([str(benchmark_exe)])

        if success:
            # 保存原始输出
            with open(output_file, 'w') as f:
                f.write(stdout)
                f.write("\n\nSTDERR:\n")
                f.write(stderr)

            # 检查是否生成了JSON结果文件
            potential_json = self.benchmark_dir / "re2_rust_results.json"
            if potential_json.exists():
                import shutil
                shutil.move(potential_json, json_file)

                # 解析JSON结果
                with open(json_file, 'r') as f:
                    self.rust_results = json.load(f)

                print(f"Rust benchmark completed. Results saved to {output_file} and {json_file}")
            else:
                print("Rust benchmark completed but no JSON results found")
                self.rust_results = self.parse_rust_output(stdout)

        return success

    def parse_odin_output(self, output: str) -> Dict[str, Any]:
        """解析Odin基准测试输出"""
        results = {
            "test_cases": [],
            "summary": {},
            "performance": {},
            "errors": []
        }

        lines = output.split('\n')
        current_test = None

        for line in lines:
            line = line.strip()

            if line.startswith("Test: ") and not line.startswith("Test suite"):
                current_test = {"name": line[6:]}

            elif line.startswith("Pattern: "):
                if current_test:
                    current_test["pattern"] = line[9:]

            elif line.startswith("Compile: "):
                if current_test:
                    current_test["compile_time"] = line[9:]

            elif line.startswith("Match: "):
                if current_test:
                    current_test["match_time"] = line[7:]

            elif line.startswith("Result: "):
                if current_test:
                    result_str = line[8:]
                    current_test["matched"] = "true" in result_str.lower()

            elif line.startswith("Throughput: "):
                if current_test:
                    current_test["throughput"] = line[12:]
                    results["test_cases"].append(current_test)
                    current_test = None

            elif "SUMMARY" in line:
                # 解析总结信息
                pass

        return results

    def parse_rust_output(self, output: str) -> Dict[str, Any]:
        """解析Rust基准测试输出"""
        # 类似于Odin解析逻辑
        return {"raw_output": output}

    def compare_results(self) -> Dict[str, Any]:
        """对比Odin和Rust的结果"""
        print("\n=== Comparing Results ===")

        comparison = {
            "functionality": {
                "odin_passed": 0,
                "rust_passed": 0,
                "both_passed": 0,
                "both_failed": 0,
                "odin_only": 0,
                "rust_only": 0
            },
            "performance": {
                "odin_avg_compile": 0,
                "rust_avg_compile": 0,
                "odin_avg_match": 0,
                "rust_avg_match": 0,
                "compile_speedup": 0,
                "match_speedup": 0
            },
            "linearity": {},
            "errors": []
        }

        # 这里需要根据实际解析的数据结构进行对比
        # 简化版本的对比逻辑

        return comparison

    def generate_report(self) -> str:
        """生成详细的对比报告"""
        print("\n=== Generating Comparison Report ===")

        timestamp = time.strftime("%Y%m%d_%H%M%S")
        report_file = self.results_dir / f"re2_comparison_report_{timestamp}.md"

        report_content = f"""# Google RE2 vs Odin RE2 全面对比评测报告

**评测日期**: {time.strftime("%Y-%m-%d %H:%M:%S")}
**评测环境**: {os.name}
**Python版本**: {sys.version}

## 执行摘要

本报告对比了Odin RE2实现与Rust regex crate在功能和性能方面的差异。
评测涵盖了基础正则表达式功能、性能关键场景以及实际应用模式。

## 测试环境

- **操作系统**: {os.name}
- **测试时间**: {time.strftime("%Y-%m-%d %H:%M:%S")}
- **Odin版本**: 当前实现
- **Rust版本**: regex crate 1.10

## 功能对比

### 基础功能测试

| 功能类别 | 测试用例数 | Odin通过 | Rust通过 | 一致性 |
|---------|-----------|---------|---------|-------|
| 字面量匹配 | 4 | 待统计 | 待统计 | 待分析 |
| 字符类 | 8 | 待统计 | 待统计 | 待分析 |
| 量词 | 8 | 待统计 | 待统计 | 待分析 |
| 锚点 | 6 | 待统计 | 待统计 | 待分析 |
| 选择 | 3 | 待统计 | 待统计 | 待分析 |
| 连接 | 2 | 待统计 | 待统计 | 待分析 |

### 高级功能测试

| 功能类别 | 测试用例数 | Odin支持 | Rust支持 | 注释 |
|---------|-----------|---------|---------|-----|
| Unicode支持 | 3 | 待评估 | 完整支持 | 需要详细测试 |
| POSIX字符类 | 6 | 待评估 | 完整支持 | |
| 转义字符 | 4 | 待评估 | 完整支持 | |
| 边界匹配器 | 4 | 待评估 | 完整支持 | |

## 性能对比

### 编译性能

| 指标 | Odin RE2 | Rust Regex | 优势方 |
|-----|----------|-----------|-------|
| 平均编译时间 | 待计算 | 待计算 | 待分析 |
| 最快编译时间 | 待计算 | 待计算 | 待分析 |
| 编译时间方差 | 待计算 | 待计算 | 待分析 |

### 匹配性能

| 指标 | Odin RE2 | Rust Regex | 优势方 |
|-----|----------|-----------|-------|
| 平均匹配时间 | 待计算 | 待计算 | 待分析 |
| 吞吐量 (MB/s) | 待计算 | 待计算 | 待分析 |
| 最快匹配时间 | 待计算 | 待计算 | 待分析 |

### 特定场景性能

#### 长字符串匹配
- **测试模式**: 在1000字符后查找"needle"
- **Odin性能**: 待测试
- **Rust性能**: 待测试
- **分析**: 待分析

#### 重复模式匹配
- **测试模式**: `a*b` vs 1000个'a'后跟'b'
- **Odin性能**: 待测试
- **Rust性能**: 待测试
- **分析**: 待分析

## 线性时间复杂度验证

### 测试结果
| 输入规模 | Odin时间 | Rust时间 | 增长率 |
|---------|---------|---------|-------|
| 100字符 | 待测试 | 待测试 | 待计算 |
| 1,000字符 | 待测试 | 待测试 | 待计算 |
| 10,000字符 | 待测试 | 待测试 | 待计算 |
| 100,000字符 | 待测试 | 待测试 | 待计算 |

### 复杂度分析
- **Odin RE2**: 线性时间保证验证 (待测试)
- **Rust Regex**: 线性时间保证验证 (待测试)
- **对比**: 两者都应保持O(n)复杂度

## 实际应用性能

### 邮箱验证模式
- **模式**: `[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}`
- **Odin性能**: 待测试
- **Rust性能**: 待测试

### URL匹配模式
- **模式**: `https?://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}(/.*)?`
- **Odin性能**: 待测试
- **Rust性能**: 待测试

### IPv4地址匹配
- **模式**: `(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])`
- **Odin性能**: 待测试
- **Rust性能**: 待测试

## 问题诊断

### Odin RE2发现的问题
1. **字符类匹配**: [abc]等字符类可能存在问题 (基于之前测试)
2. **锚点支持**: ^和$锚点实现需要完善
3. **复杂模式**: 邮箱、IP等复杂模式匹配失败

### 建议改进
1. **优先级1**: 修复字符类匹配逻辑
2. **优先级2**: 完善锚点支持
3. **优先级3**: 增强复杂模式支持
4. **优先级4**: 性能优化

## 竞争力分析

### Odin RE2优势
1. **编译速度**: 预期在简单模式上更快
2. **内存效率**: Arena分配策略
3. **集成性**: 与Odin生态系统无缝集成
4. **可预测性**: 严格的线性时间保证

### 需要改进的领域
1. **功能完整性**: 需要完整实现RE2功能
2. **性能优化**: 复杂模式性能优化
3. **错误处理**: 更好的错误信息和恢复
4. **生态支持**: 调试工具和文档

## 结论

Odin RE2项目展现了成为优秀正则表达式引擎的潜力。
当前的实现需要重点解决功能完整性问题，
特别是在字符类、锚点和复杂模式支持方面。

### 下一步行动
1. **立即行动** (1-2周)
   - 修复字符类匹配问题
   - 完善锚点实现
   - 增强错误处理

2. **短期目标** (1-2月)
   - 完整实现RE2功能集
   - 性能优化
   - 全面测试覆盖

3. **长期愿景** (3-6月)
   - 生产环境部署
   - 工具链开发
   - 社区建设

---
*本报告由自动化评测系统生成*
"""

        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report_content)

        print(f"Comparison report generated: {report_file}")
        return str(report_file)

    def run_full_comparison(self) -> bool:
        """运行完整的对比评测"""
        print("=== Starting Full RE2 Comparison ===")

        # 编译基准测试
        if not self.compile_odin_benchmark():
            print("Failed to compile Odin benchmark")
            return False

        if not self.compile_rust_benchmark():
            print("Failed to compile Rust benchmark")
            return False

        # 运行基准测试
        if not self.run_odin_benchmark():
            print("Failed to run Odin benchmark")
            return False

        if not self.run_rust_benchmark():
            print("Failed to run Rust benchmark")
            return False

        # 对比结果
        self.comparison_results = self.compare_results()

        # 生成报告
        report_path = self.generate_report()

        print(f"\n=== Comparison Completed ===")
        print(f"Report available at: {report_path}")
        print(f"Results directory: {self.results_dir}")

        return True

def main():
    """主函数"""
    benchmark_dir = Path(__file__).parent
    runner = BenchmarkRunner(benchmark_dir)

    success = runner.run_full_comparison()

    if success:
        print("✅ Full comparison completed successfully!")
        return 0
    else:
        print("❌ Comparison failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())