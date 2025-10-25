# Odin Language Syntax Reference

> Extracted from official examples at `examples/demo/demo.odin`

## 1. Basics

### Comments
```odin
// Single-line comment
/* Multi-line comment */
/*
  Nested comments are supported
  /* like this */
*/
```

### Variables & Constants
```odin
// Variables
x: int = 123           // explicit type
y := 456               // type inference
a, b := 1, "hello"     // multiple assignment

// Constants
PI :: 3.14159          // untyped constant
X : int : 42           // typed constant
```

### Literals
```odin
// Numbers
_ = 1_000_000          // underscores for readability
_ = 0b1010             // binary
_ = 0o755              // octal
_ = 0xDEADBEEF         // hexadecimal
_ = 1.0e9              // float
_ = 2i                 // imaginary

// Strings
s1 := "escape: \n \t"
s2 := `raw string: C:\path`
c := 'A'               // rune (unicode codepoint)
```

## 2. Control Flow

### For Loop
```odin
// C-style
for i := 0; i < 10; i += 1 {
    fmt.println(i)
}

// While-style
for i < 10 {
    i += 1
}

// Infinite
for {
    break
}

// Range-based
for i in 0..<10 {}              // half-open range
for i in 0..=9 {}               // closed range
for val, idx in array {}        // with index
for key, val in map {}          // map iteration
```

### If Statement
```odin
if x > 0 {
    // ...
} else if x == 0 {
    // ...
} else {
    // ...
}

// With init statement
if y := compute(); y < 0 {
    fmt.println(y)
}
```

### Switch Statement
```odin
switch x {
case 0:
    // no fallthrough by default
case 1, 2, 3:
    // multiple cases
    fallthrough        // explicit fallthrough
case 10..<20:
    // range matching
case:
    // default case
}

// Type switch
switch v in union_val {
case int:  fmt.println("int")
case bool: fmt.println("bool")
}
```

### When Statement (Compile-time If)
```odin
when ODIN_OS == .Windows {
    // Windows-specific code
} else when ODIN_OS == .Linux {
    // Linux-specific code
}
```

### Defer Statement
```odin
{
    file := os.open("file.txt")
    defer os.close(file)
    // file will be closed at scope exit
}

// Defers execute in reverse order
defer fmt.println("3")
defer fmt.println("2")
defer fmt.println("1")
// prints: 1, 2, 3
```

## 3. Procedures

### Basic Procedures
```odin
add :: proc(a, b: int) -> int {
    return a + b
}

// Named return values
div :: proc(a, b: int) -> (result: int, ok: bool) {
    if b == 0 {
        return 0, false
    }
    result = a / b
    ok = true
    return  // naked return
}
```

### Variadic Procedures
```odin
sum :: proc(nums: ..int) -> int {
    result := 0
    for n in nums {
        result += n
    }
    return result
}

sum(1, 2, 3, 4, 5)
odds := []int{1, 3, 5}
sum(..odds)            // expand slice
```

### Procedure Overloading
```odin
add_int :: proc(a, b: int) -> int { return a + b }
add_f32 :: proc(a, b: f32) -> f32 { return a + b }

add :: proc{add_int, add_f32}

add(1, 2)              // calls add_int
add(1.0, 2.0)          // calls add_f32
```

### Parametric Polymorphism
```odin
print_value :: proc(value: $T) {
    fmt.printf("%T %v\n", value, value)
}

swap :: proc(a, b: ^$T) {
    a^, b^ = b^, a^
}

// Constrained polymorphism
add :: proc(a, b: $T) -> T where intrinsics.type_is_numeric(T) {
    return a + b
}
```

## 4. Data Types

### Struct
```odin
Vector2 :: struct {
    x, y: f32,
}

v := Vector2{1, 2}
v = Vector2{x=1, y=2}    // named fields

// Tags
Person :: struct {
    name: string `json:"person_name"`,
    age:  int,
}

// Packed struct
Packet :: struct #packed {
    header: u32,
    data:   [16]u8,
}
```

### Union (Tagged Union)
```odin
Value :: union {int, f64, string}

val: Value = 42

// Type assertion
if i, ok := val.(int); ok {
    fmt.println("int:", i)
}

// Type switch
switch v in val {
case int:    fmt.println("int:", v)
case f64:    fmt.println("f64:", v)
case string: fmt.println("str:", v)
}
```

### Enum
```odin
Color :: enum {
    Red,
    Green,
    Blue,
}

c := Color.Red
c = .Green             // implicit enum selector

// Backed by specific type
Status :: enum u8 {
    OK    = 0,
    Error = 1,
}
```

### Bit Set
```odin
Day :: enum {Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday}
Days :: bit_set[Day]

weekend := Days{.Sunday, .Saturday}

if .Saturday in weekend {
    fmt.println("It's weekend!")
}

weekend += {.Friday}   // add element
weekend -= {.Sunday}   // remove element
```

### Arrays & Slices
```odin
// Fixed array
arr := [3]int{1, 2, 3}
arr = [3]int{0=1, 2=3}      // indexed initialization

// Slice
s := []int{1, 2, 3}
s = arr[:]
s = arr[1:3]

// Dynamic array
d := [dynamic]int{1, 2, 3}
defer delete(d)
append(&d, 4, 5, 6)
```

### Map
```odin
m := make(map[string]int)
defer delete(m)

m["key"] = 42

// Access
val := m["key"]
val, ok := m["key"]
exists := "key" in m

// Delete
delete_key(&m, "key")
```

### Matrix
```odin
// 2 rows, 3 columns
m := matrix[2, 3]f32{
    1, 2, 3,
    4, 5, 6,
}

elem := m[0, 1]        // row 0, col 1

// Matrix multiplication
a := matrix[2, 3]f32{...}
b := matrix[3, 2]f32{...}
c := a * b             // result: matrix[2, 2]f32

// Vector multiplication
v := [3]f32{1, 2, 3}
result := m * v
```

### Bit Field
```odin
Flags :: bit_field u16 {
    read:    bool | 1,
    write:   bool | 1,
    execute: bool | 1,
    value:   u8   | 5,
}

f: Flags
f.read = true
f.value = 31
```

## 5. Pointers & Memory

### Pointers
```odin
x := 42
ptr := &x              // address-of
val := ptr^            // dereference

// new/free
p := new(int)
defer free(p)
p^ = 123

// Struct pointer auto-dereference
v := Vector2{1, 2}
p := &v
p.x = 10               // same as p^.x = 10
```

### Memory Allocation
```odin
// Allocators
context.allocator = context.temp_allocator

// make/delete
arr := make([]int, 10)
defer delete(arr)

m := make(map[string]int)
defer delete(m)
```

## 6. Advanced Features

### Using Statement
```odin
Entity :: struct {
    using pos: Vector2,
    health: int,
}

e := Entity{pos={10, 20}, health=100}
fmt.println(e.x, e.y)  // accessing pos.x, pos.y directly

// Using in procedure
foo :: proc(using entity: ^Entity) {
    fmt.println(x, y, health)
}
```

### Implicit Context
```odin
// Context is implicitly passed to all Odin procedures
context.allocator = my_custom_allocator()
context.user_index = 123

some_proc()  // receives modified context
```

### SOA (Structure of Arrays)
```odin
Vector3 :: struct {x, y, z: f32}

// AOS (Array of Structures)
aos: [100]Vector3

// SOA (Structure of Arrays)
soa: #soa[100]Vector3

// Same syntax for access
aos[0].x = 1
soa[0].x = 1

// Direct field access
soa.x[0] = 1

// SOA slices
s: #soa[]Vector3 = soa[:]
```

### Reflection
```odin
Foo :: struct {
    x: int    `tag1`,
    y: string `json:"y_field"`,
}

id := typeid_of(Foo)
names := reflect.struct_field_names(id)
types := reflect.struct_field_types(id)
tags  := reflect.struct_field_tags(id)
```

### Or-Operators
```odin
// or_else
val := m["key"] or_else 0
i := union_val.(int) or_else 42

// or_return (early return on error)
value := call() or_return

// or_break / or_continue
for {
    val := call() or_break
}
```

### Unroll For
```odin
#unroll for i in 0..<4 {
    fmt.println(i)  // loop is unrolled at compile-time
}
```

### Attributes
```odin
@(require) import "core:fmt"
@(private="file") secret_proc :: proc() {}
@(deprecated="Use new_proc instead")
old_proc :: proc() {}
```

## 7. Special Types

### Quaternions
```odin
q := 1 + 2i + 3j + 4k
r := quaternion(real=1, imag=2, jmag=3, kmag=4)

fmt.println(real(q), imag(q), jmag(q), kmag(q))
fmt.println(conj(q), abs(q))
```

### Distinct Types
```odin
Meters :: distinct f32
Seconds :: distinct f32

m: Meters = 10
s: Seconds = 5
// m + s  // compile error: type mismatch
```

### Any Type
```odin
val: any = 42
val = "string"
val = true

if i, ok := val.(int); ok {
    fmt.println("int:", i)
}
```

## 8. Foreign System

```odin
when ODIN_OS == .Windows {
    foreign import kernel32 "system:kernel32.lib"

    foreign kernel32 {
        ExitProcess :: proc "stdcall" (exit_code: u32) ---
    }
}
```

## 9. Directives

```odin
#+build windows         // conditional compilation
#+vet                   // enable vet checks
#+feature dynamic-literals

#assert(size_of(int) == 8)
#panic("compile error")

#procedure              // current procedure name
#file                   // current file path
#line                   // current line number
```

## 10. Common Idioms

### Error Handling
```odin
Error :: enum {None, FileNotFound, PermissionDenied}

open_file :: proc(path: string) -> (handle: Handle, err: Error) {
    // ...
    return handle, .None
}

// Usage
handle := open_file("file.txt") or_return
defer close(handle)
```

### Resource Management
```odin
{
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)

    strings.write_string(&builder, "Hello")
}
```

### Slice Patterns
```odin
// Copy
dst := make([]int, len(src))
copy(dst, src)

// Append
arr := [dynamic]int{}
append(&arr, 1, 2, 3)
```

## Build Tags

```odin
#+build windows
#+build linux, darwin
#+build !js
```

---

**Reference**: Official examples at https://github.com/odin-lang/Odin/tree/master/examples
