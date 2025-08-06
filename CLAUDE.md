# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Case Switcher is a Zig-based command-line utility that converts text between different case formats. It can identify the current case format of input text and cycle through various case styles:

- TitleCase
- camelCase  
- snake_case
- kebab-case
- CONST_CASE

The project uses a dual-module architecture with both a library (`root.zig`) and executable (`main.zig`) component.

## CLI Arguments

The tool supports excluding specific case formats from the rotation using `--no-*` flags:

- `--no-title-case`: Excludes TitleCase from rotation
- `--no-camel-case`: Excludes camelCase from rotation  
- `--no-snake-case`: Excludes snake_case from rotation
- `--no-kebab-case`: Excludes kebab-case from rotation
- `--no-const-case`: Excludes CONST_CASE from rotation

Multiple exclusions can be combined. Input can be provided as a command line argument or via stdin.

## Build Commands

All build operations use Zig's built-in build system:

```bash
# Build and install (default)
zig build

# Run the application 
zig build run

# Run with arguments
zig build run -- "some_input_text"

# Run with case exclusions
zig build run -- --no-camel-case "HelloWorld"
zig build run -- --no-snake-case --no-kebab-case "helloWorld"

# Run all unit tests
zig build test

# Build in release mode
zig build --release=fast    # Optimize for speed
zig build --release=safe    # Optimize with safety checks  
zig build --release=small   # Optimize for size
```

## Project Structure

- `src/main.zig` - Main executable entry point with case conversion logic
- `src/root.zig` - Library module (currently contains minimal example code)
- `build.zig` - Build configuration that creates both library and executable
- `build.zig.zon` - Package manifest and dependency management

## Key Architecture Components

### Case Detection (`identifyCase` function in main.zig:216)
Analyzes input text to determine the current case format by checking for:
- Underscore delimiters (snake_case vs CONST_CASE based on first character case)
- Hyphen delimiters (kebab-case)
- Case of first character (camelCase vs TitleCase)

### Word Splitting (`splitLine` function in main.zig:43)
Splits input based on detected case format:
- Snake/Const case: splits on underscores
- Kebab case: splits on hyphens  
- Title/Camel case: splits on uppercase letters

### Case Cycling (`nextMode` function in main.zig:148)
Defines the transformation sequence: TitleCase → CamelCase → SnakeCase → KebabCase → ConstCase → TitleCase

## Testing

The project includes comprehensive unit tests for all core functions:
- Case identification tests for all supported formats
- Word splitting tests with edge cases
- Memory management using arena allocator in tests

Run tests with `zig build test` to execute both library and executable tests.

## Release Process

The project uses GitHub Actions for automated cross-platform builds and releases:

### Creating a Release

To create a new release:

```bash
# Tag the current commit with a version
git tag v1.0.0

# Push the tag to trigger the release workflow  
git push origin v1.0.0
```

### Release Artifacts

The release workflow automatically builds binaries for:
- Linux x86_64 (`case-switcher-linux-x86_64.tar.gz`)
- Windows x86_64 (`case-switcher-windows-x86_64.exe.zip`)
- macOS x86_64 (`case-switcher-macos-x86_64.tar.gz`)
- macOS ARM64 (`case-switcher-macos-aarch64.tar.gz`)

All releases include auto-generated release notes and are published to the GitHub releases page.

## Development Notes

- Uses arena allocator for memory management in main function
- Input is read from stdin with 1024 byte buffer limit
- All string processing preserves UTF-8 compatibility through Zig's standard library
- Tests use `std.testing.allocator` for proper memory leak detection