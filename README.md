# Case Switcher

A fast command-line utility written in Zig that converts text between different case formats. It automatically detects the current case format and cycles through various case styles.

## Features

- **Automatic case detection** - Identifies current case format of input text
- **Multiple case formats** - Supports TitleCase, camelCase, snake_case, kebab-case, and CONST_CASE
- **Flexible exclusions** - Exclude specific case formats from the rotation
- **Fast performance** - Written in Zig for optimal speed
- **Cross-platform** - Works on Linux, Windows, and macOS

## Installation

### Homebrew (macOS)

```bash
# Add the tap
brew tap Velrok/case-switcher https://github.com/Velrok/case-switcher

# Install the tool
brew install case-switcher
```

### Download Pre-built Binaries

Download the latest release for your platform from the [releases page](../../releases):

- **Linux x86_64**: `case-switcher-linux-x86_64.tar.gz`
- **Windows x86_64**: `case-switcher-windows-x86_64.exe.zip`
- **macOS x86_64**: `case-switcher-macos-x86_64.tar.gz`
- **macOS ARM64**: `case-switcher-macos-aarch64.tar.gz`

### Build from Source

Requires [Zig](https://ziglang.org/download/) master.

```bash
git clone https://github.com/your-username/case-switcher.git
cd case-switcher
zig build --release=fast
```

The binary will be available in `zig-out/bin/case-switcher`.

## Usage

### Basic Usage

Convert text by providing it as an argument:

```bash
case-switcher "hello_world"
# Output: HelloWorld

case-switcher "HelloWorld" 
# Output: helloWorld

case-switcher "helloWorld"
# Output: hello_world
```

Or pipe text via stdin:

```bash
echo "some-text" | case-switcher
# Output: SomeText
```

### Case Format Cycle

The tool cycles through case formats in this order:
1. **TitleCase** (HelloWorld)
2. **camelCase** (helloWorld)
3. **snake_case** (hello_world)
4. **kebab-case** (hello-world)
5. **CONST_CASE** (HELLO_WORLD)

### Excluding Case Formats

Use `--no-*` flags to exclude specific case formats from the rotation:

```bash
# Exclude camelCase from rotation
case-switcher --no-camel-case "HelloWorld"
# Cycles: TitleCase → snake_case → kebab-case → CONST_CASE

# Exclude multiple formats
case-switcher --no-snake-case --no-kebab-case "helloWorld"
# Cycles: camelCase → CONST_CASE → TitleCase

# Available exclusion flags:
# --no-title-case
# --no-camel-case  
# --no-snake-case
# --no-kebab-case
# --no-const-case
```

## Examples

```bash
# Convert variable names
case-switcher "userName"           # → user_name
case-switcher "user_name"          # → user-name
case-switcher "user-name"          # → USER_NAME
case-switcher "USER_NAME"          # → UserName

# Skip certain formats
case-switcher --no-kebab-case "myVariable"  # → my_variable (skips kebab-case)

# Process multiple inputs
echo -e "firstName\nlastName" | while read line; do
  case-switcher "$line"
done
```

## Development

### Running Tests

```bash
zig build test
```

### Building

```bash
# Debug build
zig build

# Release build (optimized for speed)
zig build --release=fast

# Release build (optimized for size)
zig build --release=small
```

### Running from Source

```bash
# Run with arguments
zig build run -- "some_input_text"

# Run with case exclusions
zig build run -- --no-camel-case "HelloWorld"
```
