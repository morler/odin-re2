# Odin Syntax Reference

A concise, precise reference for the Odin programming language.

## 1. Lexical Elements

### Comments
```odin
// Single line comment
/* Multi-line comment
   /* Nested comments supported */
*/
```

### Identifiers
- Case-sensitive
- Start with letter or underscore
- Followed by letters, digits, underscores

### Literals

**Integer**
```odin
123                 // Decimal
0b1010             // Binary
0o12               // Octal
0x0A               // Hexadecimal
1_000_000          // Underscores for readability
```

**Float**
```odin
1.0
1.0e9
.5                 // 0.5
```

**String**
```odin
"Hello"            // Regular string
'A'                // Rune (character)
`Raw string`       // Raw string (no escapes)
```

**Special Values**
```odin
true, false        // Boolean
nil                // Null pointer/reference
---                // Undefined (uninitialized memory)
```

## 2. Declarations

### Variables
```odin
x: int                    // Zero-initialized
y: int = 123             // Explicit initialization
z := 456                 // Type inference
a, b := 1, 2             // Multiple declarations
```

### Constants
```odin
X :: 123                 // Untyped constant
Y : int : 456            // Typed constant
```

## 3. Basic Types

### Integers
```odin
int, uint                // Platform-dependent (native size)
i8, i16, i32, i64, i128  // Signed integers
u8, u16, u32, u64, u128  // Unsigned integers
uintptr                  // Pointer-sized unsigned integer
```

### Floats
```odin
f16, f32, f64            // Floating-point
```

### Complex & Quaternions
```odin
complex32, complex64, complex128
quaternion64, quaternion128, quaternion256
```

### Other
```odin
bool                     // Boolean
rune                     // Unicode code point (i32)
string                   // UTF-8 string
cstring                  // C-style null-terminated string
rawptr                   // Raw pointer
typeid                   // Type identifier
any                      // Any type (type + pointer)
```

### Zero Values
- Numeric types: `0`
- Boolean: `false`
- String: `""`
- Pointers, typeid, any: `nil`

## 4. Type Conversion

```odin
i: int = 123
f := f64(i)              // Type conversion
u := u32(f)

// Cast operator
f2 := cast(f64)i

// Transmute (bit-level cast, same size)
bits := transmute(u32)f32(123.0)

// Auto-cast (use sparingly)
x: f32 = 123
y: int = auto_cast x
```

## 5. Operators

### Arithmetic
```odin
+    -    *    /        // Basic arithmetic
%                       // Modulo (truncated)
%%                      // Remainder (floored)
```

### Comparison
```odin
==   !=   <    >    <=   >=
```

### Logical
```odin
&&   ||   !             // Short-circuiting AND, OR, NOT
```

### Bitwise
```odin
&    |    ~    &~       // AND, OR, XOR, AND-NOT
<<   >>                 // Left/right shift
```

### Other
```odin
in       not_in         // Set membership
..=      ..<            // Inclusive/half-open range
&        ^              // Address-of, dereference
```

### Precedence (highest to lowest)
```
7: *  /  %  %%  &  &~  <<  >>
6: +  -  |  ~  in  not_in
5: ==  !=  <  >  <=  >=
4: &&
3: ||
2: ..=  ..<
1: or_else  ?  if  when
```

## 6. Control Flow

### if Statement
```odin
if x > 0 {
    // ...
}

// With initialization
if x := foo(); x > 0 {
    // ...
} else if x == 0 {
    // ...
} else {
    // ...
}

// Ternary
result := x if condition else y
result := condition ? x : y
```

### for Loop
```odin
// C-style
for i := 0; i < 10; i += 1 {
    // ...
}

// While-style
for condition {
    // ...
}

// Infinite
for {
    // ...
}

// Range-based
for value in array {
    // ...
}

for value, index in array {
    // ...
}

// By reference
for &value in array {
    value = new_value
}

// Reverse iteration
#reverse for x in array {
    // ...
}
```

### switch Statement
```odin
switch value {
case 1:
    // ...
case 2, 3:
    // Multiple values
    fallthrough  // Explicit fallthrough
case 4:
    // ...
case:
    // Default case
}

// Without condition (switch true)
switch {
case x < 0:
    // ...
case x == 0:
    // ...
case:
    // ...
}

// Ranges
switch x {
case 0..<10:
    // ...
case 10..=20:
    // ...
}

// Partial switch (for enums/unions)
#partial switch value {
case .A:
    // Only handle specific cases
}
```

### defer Statement
```odin
defer statement          // Execute at scope exit
defer {
    // Multiple statements
}

// Executed in reverse order
defer fmt.println("1")
defer fmt.println("2")   // Prints: 2, 1
```

### when Statement (Compile-time if)
```odin
when ODIN_OS == .Windows {
    // Windows-specific code
} else when ODIN_OS == .Linux {
    // Linux-specific code
} else {
    // Other platforms
}
```

### Branch Control
```odin
break                    // Exit loop/switch
break label              // Exit labeled construct
continue                 // Next loop iteration
fallthrough              // Fall through to next case
```

## 7. Procedures

### Definition
```odin
// Basic procedure
add :: proc(x, y: int) -> int {
    return x + y
}

// Multiple return values
swap :: proc(x, y: int) -> (int, int) {
    return y, x
}

// Named return values
divide :: proc(x, y: int) -> (result: int, remainder: int) {
    result = x / y
    remainder = x % y
    return  // Naked return
}

// Default parameter values
greet :: proc(name: string, greeting := "Hello") -> string {
    return greeting + ", " + name
}

// Variadic parameters
sum :: proc(nums: ..int) -> int {
    result := 0
    for n in nums {
        result += n
    }
    return result
}
```

### Named Arguments
```odin
create_window(title="App", width=800, height=600, x=0, y=0)
```

### Calling Conventions
```odin
proc "odin" ()           // Default (with context)
proc "contextless" ()    // No context
proc "c" ()              // C calling convention
proc "stdcall" ()        // Windows stdcall
```

### Procedure Overloading
```odin
foo_int :: proc(x: int) { }
foo_str :: proc(x: string) { }

foo :: proc{foo_int, foo_str}  // Explicit overload set
```

### Generics (Parametric Polymorphism)
```odin
// Type parameter
my_new :: proc($T: typeid) -> ^T {
    return (^T)(alloc(size_of(T), align_of(T)))
}

// Value parameter
create_array :: proc($N: int, $T: typeid) -> [N]T {
    return [N]T{}
}

// Type specialization
make_slice :: proc($T: typeid/[]$E, len: int) -> T {
    return make(T, len)
}

// where clause
check :: proc(x: $T) where T == int || T == f32 {
    // ...
}
```

## 8. Arrays & Slices

### Fixed Arrays
```odin
arr: [5]int              // Zero-initialized
arr := [5]int{1, 2, 3, 4, 5}
arr := [?]int{1, 2, 3}   // Infer length

// Designated initialization
arr := [?]int{
    0 = 100,
    2..=4 = 50,
}

// Array programming
a := [3]f32{1, 2, 3}
b := [3]f32{4, 5, 6}
c := a + b               // {5, 7, 9}
```

### Slices
```odin
s: []int                 // Slice type
s = arr[1:4]             // Elements 1-3
s = arr[1:]              // From 1 to end
s = arr[:4]              // From 0 to 3
s = arr[:]               // Entire array

// Slice literal
s := []int{1, 2, 3}

// Length
n := len(s)
```

### Dynamic Arrays
```odin
d: [dynamic]int
append(&d, 1, 2, 3)
append(&d, ..arr[:])     // Append slice

pop(&d)                  // Remove last
ordered_remove(&d, 0)    // Remove at index
unordered_remove(&d, 0)  // Fast remove

clear(&d)                // Set length to 0
resize(&d, 10)           // Set length
reserve(&d, 100)         // Reserve capacity
shrink(&d)               // Shrink to length

len(d)                   // Length
cap(d)                   // Capacity
```

### Enumerated Arrays
```odin
Direction :: enum{North, East, South, West}

vectors := [Direction][2]int{
    .North = {0, -1},
    .East  = {1, 0},
    .South = {0, 1},
    .West  = {-1, 0},
}

v := vectors[.North]     // {0, -1}
```

## 9. Maps

```odin
m: map[string]int
m = make(map[string]int)
defer delete(m)

// Map literal
m := map[string]int{
    "A" = 1,
    "B" = 2,
}

// Insert/update
m["C"] = 3

// Retrieve
value := m["A"]

// Check existence
value, ok := m["A"]
if key in m {
    // ...
}

// Delete
delete_key(&m, "A")

// Map operations
len(m)                   // Size
clear(&m)                // Clear all
reserve(&m, 100)         // Reserve capacity
```

## 10. Structs

### Definition
```odin
Vector3 :: struct {
    x, y, z: f32,
}

// Instantiation
v := Vector3{1, 2, 3}
v := Vector3{x=1, y=2, z=3}
v := Vector3{}           // Zero value

// Field access
v.x = 10

// Pointer access (auto-dereference)
p := &v
p.y = 20
```

### Directives
```odin
struct #align(4) {...}   // Custom alignment
struct #packed {...}     // No padding
struct #raw_union {...}  // C-style union
```

### using
```odin
Entity :: struct {
    using position: Vector3,  // Bring fields into scope
    velocity: Vector3,
}

e := Entity{}
e.x = 10                 // Access position.x directly
```

## 11. Unions

```odin
Value :: union {
    bool,
    int,
    f32,
    string,
}

v: Value = 123

// Type assertion
i := v.(int)             // Panics if wrong type
i, ok := v.(int)         // Safe check

// Type switch
switch x in v {
case int:
    // x is int here
case f32:
    // x is f32 here
case:
    // nil or other
}

// Tags
union #no_nil {...}      // No nil value
union #shared_nil {...}  // Normalize nil values
union #align(4) {...}    // Custom alignment
```

## 12. Enumerations

```odin
Direction :: enum {
    North,
    East,
    South,
    West,
}

// With explicit values
Status :: enum {
    OK,
    Error = 100,
    Fatal = 200,
}

// Custom backing type
Byte_Enum :: enum u8 {A, B, C}

// Usage
d: Direction = .North    // Implicit selector
d = Direction.East       // Explicit

// Iteration
for dir in Direction {
    // ...
}

// Conversion
n := int(Direction.East) // 1
```

## 13. Bit Sets

```odin
Direction_Set :: bit_set[Direction]
Char_Set :: bit_set['A'..='Z']

s: Direction_Set = {.North, .West}

// Operations
a | b                    // Union
a & b                    // Intersection
a - b                    // Difference
a ~ b                    // Symmetric difference
elem in a                // Membership
card(a)                  // Cardinality

// Custom backing type
My_Set :: bit_set[0..=7; u8]
```

## 14. Pointers

### Single Pointer
```odin
p: ^int                  // Pointer to int
i := 123
p = &i                   // Address-of
value := p^              // Dereference
p^ = 456                 // Write through pointer
```

### Multi-Pointer (C-style)
```odin
mp: [^]int               // Multi-pointer
mp = raw_data(arr[:])

// Indexing/slicing
value := mp[0]           // Type: int
slice := mp[:10]         // Type: []int
ptr := mp[5:]            // Type: [^]int
```

## 15. Memory Management

### Allocation
```odin
// Using context.allocator
ptr := new(int)
arr := make([]int, 10)
dyn := make([dynamic]int, 0, 10)
m := make(map[string]int)

// Clone
copy := new_clone(value)

// Free
free(ptr)
delete(arr)
delete(dyn)
delete(m)
free_all()               // Free all from allocator
```

### Context System
```odin
// Current context
c := context

// Modify context
context.allocator = my_allocator()
context.temp_allocator = temp_alloc()

// Reset
defer free_all(context.temp_allocator)
```

## 16. Packages

### Declaration
```odin
package main
```

### Import
```odin
import "core:fmt"
import "core:os"
import foo "core:fmt"    // Alias

using import "core:fmt"  // Bring into scope
```

### Export Control
```odin
@(private)
my_var: int              // Package-private

@(private="file")
secret: int              // File-private
```

## 17. Advanced Features

### or_else
```odin
i := m["key"] or_else default_value
i = v.(int) or_else 0
```

### or_return
```odin
foo :: proc() -> Error {
    value := may_fail() or_return
    return .None
}
```

### or_continue / or_break
```odin
for job in jobs {
    result := process(&job) or_continue
    finalize(&job) or_break
}
```

### Attributes
```odin
@(export)                // Export symbol
@(static)                // Static variable
@(thread_local)          // Thread-local
@(link_section=".foo")   // Custom section
@(require_results)       // Must handle return value
@(test)                  // Test procedure
```

### Directives
```odin
#assert(condition)       // Compile-time assert
#panic(message)          // Compile-time panic
#config(KEY, default)    // Config value
#defined(symbol)         // Check if defined

#file                    // Current file path
#directory               // Current directory
#line                    // Current line number
#procedure               // Current procedure name

#load("file.txt")        // Load file content
#exists("path")          // Check file existence
```

### Conditional Compilation
```odin
when ODIN_OS == .Windows {
    // Windows code
}

when ODIN_ARCH == .amd64 {
    // AMD64 code
}

when ODIN_DEBUG {
    // Debug build
}
```

### SOA (Structure of Arrays)
```odin
Vector3 :: struct{x, y, z: f32}

// SOA array
soa_arr: #soa[100]Vector3
soa_arr[0].x = 1

// SOA slice
soa_slice: #soa[]Vector3

// SOA dynamic
soa_dyn: #soa[dynamic]Vector3
append_soa(&soa_dyn, Vector3{1, 2, 3})

// soa_zip/unzip
x := []int{1, 2, 3}
y := []f32{4.0, 5.0, 6.0}
zipped := soa_zip(a=x, b=y)
a, b := soa_unzip(zipped)
```

### Matrix Type
```odin
m: matrix[2, 3]f32       // 2 rows, 3 columns
m = matrix[2, 3]f32{
    1, 2, 3,
    4, 5, 6,
}

// Indexing
elem := m[1, 2]          // Row 1, column 2

// Operations
c := a * b               // Matrix multiplication
d := a + b               // Element-wise addition
t := transpose(m)
```

## 18. Built-in Procedures

```odin
len(x)                   // Length of array/slice/string/map
cap(x)                   // Capacity of dynamic array/map
size_of(T)               // Size of type
align_of(T)              // Alignment of type
offset_of(T, field)      // Field offset
type_of(x)               // Type of expression
typeid_of(T)             // Type ID

min(a, b)                // Minimum
max(a, b)                // Maximum
abs(x)                   // Absolute value
clamp(x, min, max)       // Clamp value

swizzle(v, x, y, z)      // Vector swizzle
transpose(m)             // Matrix transpose
```

## 19. Common Patterns

### Error Handling
```odin
Error :: enum {
    None,
    File_Not_Found,
    Invalid_Input,
}

read_file :: proc(path: string) -> ([]byte, Error) {
    if !exists(path) {
        return nil, .File_Not_Found
    }
    // ...
    return data, .None
}

// Usage
data, err := read_file("file.txt")
if err != .None {
    // Handle error
}
```

### Maybe Type
```odin
Maybe :: union($T: typeid) {T, nil}

m: Maybe(int)
m = 123

value, ok := m.?         // Type assertion
value = m.? or_else 0    // With default
```

### Bit Fields
```odin
Flags :: bit_field u16 {
    read:  bool | 1,
    write: bool | 1,
    exec:  bool | 1,
    _:     u16  | 13,    // Padding
}

f: Flags
f.read = true
```

---

**Note**: This reference covers core syntax. Consult the official documentation for advanced features, standard library, and platform-specific details.
