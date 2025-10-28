package main

import "core:fmt"
import "core:time"

// 尝试直接导入regexp
// 需要告诉编译器在哪里找到src目录

// 假设我们使用相对路径导入
// 如果这个不行，我们会尝试其他方法

main :: proc() {
	fmt.println("🔧 测试导入配置")
	fmt.println("=" * 40)
	
	// 首先测试基础导入是否工作
	fmt.println("尝试导入regexp包...")
	
	// 这里我们将逐步测试不同的导入方法
	test_import_methods()
}

test_import_methods :: proc() {
	fmt.println("\n📋 可用的导入方法:")
	fmt.Println("1. 使用collection参数:")
	fmt.Println("   odin run test.odin -collection:regexp=src")
	fmt.Println()
	fmt.Println("2. 使用相对路径:")
	fmt.Println("   import \"../src/regexp\"")
	fmt.Println()
	fmt.Println("3. 使用source-path:")
	fmt.Println("   odin run -source-path src test.odin")
	fmt.Println()
	fmt.Println("4. 设置环境变量:")
	fmt.Println("   ODIN_ROOT=/path/to/odin")
	fmt.Println()
	
	fmt.Println("🔍 让我们测试这些方法...")
}