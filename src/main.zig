const CaseMode = enum {
    TitleCase,
    CamelCase,
    SnakeCase,
    KebabCase,
    ConstCase,
};

const ExcludedCases = struct {
    title_case: bool = false,
    camel_case: bool = false,
    snake_case: bool = false,
    kebab_case: bool = false,
    const_case: bool = false,

    fn isExcluded(self: ExcludedCases, case: CaseMode) bool {
        return switch (case) {
            .TitleCase => self.title_case,
            .CamelCase => self.camel_case,
            .SnakeCase => self.snake_case,
            .KebabCase => self.kebab_case,
            .ConstCase => self.const_case,
        };
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var excluded = ExcludedCases{};
    var input_text: ?[]const u8 = null;

    // Parse command line arguments
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--no-title-case")) {
            excluded.title_case = true;
        } else if (std.mem.eql(u8, arg, "--no-camel-case")) {
            excluded.camel_case = true;
        } else if (std.mem.eql(u8, arg, "--no-snake-case")) {
            excluded.snake_case = true;
        } else if (std.mem.eql(u8, arg, "--no-kebab-case")) {
            excluded.kebab_case = true;
        } else if (std.mem.eql(u8, arg, "--no-const-case")) {
            excluded.const_case = true;
        } else {
            input_text = arg;
        }
    }

    const line = if (input_text) |text| blk: {
        break :blk text;
    } else blk: {
        const stdin_reader = std.io.getStdIn().reader();
        var buffer: [1024]u8 = undefined;
        break :blk try stdin_reader.readUntilDelimiter(&buffer, '\n');
    };

    const result = try switcher(allocator, line, excluded);
    print("{s}\n", .{result});
}

fn switcher(allocator: std.mem.Allocator, line: []const u8, excluded: ExcludedCases) ![]u8 {
    const mode = identifyCase(line);
    var words = try splitLine(allocator, mode, line);
    defer words.deinit();

    var lowercaseWords = std.ArrayList([]u8).init(allocator);
    defer {
        for (lowercaseWords.items) |word| {
            allocator.free(word);
        }
        lowercaseWords.deinit();
    }

    for (words.items) |word| {
        try lowercaseWords.append(try std.ascii.allocLowerString(allocator, word));
    }

    const targetMode = nextMode(mode, excluded);
    return try convertToCase(allocator, lowercaseWords.items, targetMode);
}

fn splitLine(allocator: std.mem.Allocator, mode: CaseMode, line: []const u8) !std.ArrayList([]const u8) {
    var result = std.ArrayList([]const u8).init(allocator);

    switch (mode) {
        .SnakeCase, .ConstCase => {
            var words = std.mem.splitAny(u8, line, "_");
            while (words.next()) |word| {
                try result.append(word);
            }
        },
        .KebabCase => {
            var words = std.mem.splitAny(u8, line, "-");
            while (words.next()) |word| {
                try result.append(word);
            }
        },
        .TitleCase, .CamelCase => {
            if (line.len == 0) {
                try result.append("");
                return result;
            }

            var start: usize = 0;
            for (line, 0..) |char, i| {
                if (i > 0 and std.ascii.isUpper(char)) {
                    try result.append(line[start..i]);
                    start = i;
                }
            }
            // Add the last word
            if (start < line.len) {
                try result.append(line[start..]);
            }
        },
    }
    return result;
}
test "splitLine function" {
    const allocator = std.testing.allocator;

    // Test SnakeCase
    var snake_words = try splitLine(allocator, .SnakeCase, "hello_world_zig");
    defer snake_words.deinit();
    try std.testing.expect(snake_words.items.len == 3);
    try std.testing.expectEqualStrings("hello", snake_words.items[0]);
    try std.testing.expectEqualStrings("world", snake_words.items[1]);
    try std.testing.expectEqualStrings("zig", snake_words.items[2]);

    // Test ConstCase
    var const_words = try splitLine(allocator, .ConstCase, "HELLO_WORLD_ZIG");
    defer const_words.deinit();
    try std.testing.expect(const_words.items.len == 3);
    try std.testing.expectEqualStrings("HELLO", const_words.items[0]);
    try std.testing.expectEqualStrings("WORLD", const_words.items[1]);
    try std.testing.expectEqualStrings("ZIG", const_words.items[2]);

    // Test KebabCase
    var kebab_words = try splitLine(allocator, .KebabCase, "hello-world-zig");
    defer kebab_words.deinit();
    try std.testing.expect(kebab_words.items.len == 3);
    try std.testing.expectEqualStrings("hello", kebab_words.items[0]);
    try std.testing.expectEqualStrings("world", kebab_words.items[1]);
    try std.testing.expectEqualStrings("zig", kebab_words.items[2]);

    // Test TitleCase
    var title_words = try splitLine(allocator, .TitleCase, "HelloWorldAgain");
    defer title_words.deinit();
    try std.testing.expect(title_words.items.len == 3);
    try std.testing.expectEqualStrings("Hello", title_words.items[0]);
    try std.testing.expectEqualStrings("World", title_words.items[1]);
    try std.testing.expectEqualStrings("Again", title_words.items[2]);

    // Test CamelCase
    var camel_words = try splitLine(allocator, .CamelCase, "helloWorldAgain");
    defer camel_words.deinit();
    try std.testing.expect(camel_words.items.len == 3);
    try std.testing.expectEqualStrings("hello", camel_words.items[0]);
    try std.testing.expectEqualStrings("World", camel_words.items[1]);
    try std.testing.expectEqualStrings("Again", camel_words.items[2]);

    // Test empty input
    var empty_words = try splitLine(allocator, .SnakeCase, "");
    defer empty_words.deinit();
    try std.testing.expect(empty_words.items.len == 1);
    try std.testing.expectEqualStrings("", empty_words.items[0]);

    // Test input with no delimiters
    var no_delim_words = try splitLine(allocator, .SnakeCase, "helloworld");
    defer no_delim_words.deinit();
    try std.testing.expect(no_delim_words.items.len == 1);
    try std.testing.expectEqualStrings("helloworld", no_delim_words.items[0]);

    // Test single word TitleCase
    var single_title = try splitLine(allocator, .TitleCase, "Hello");
    defer single_title.deinit();
    try std.testing.expect(single_title.items.len == 1);
    try std.testing.expectEqualStrings("Hello", single_title.items[0]);

    // Test single word camelCase
    var single_camel = try splitLine(allocator, .CamelCase, "hello");
    defer single_camel.deinit();
    try std.testing.expect(single_camel.items.len == 1);
    try std.testing.expectEqualStrings("hello", single_camel.items[0]);
}

fn nextMode(mode: CaseMode, excluded: ExcludedCases) CaseMode {
    const sequence = [_]CaseMode{ .TitleCase, .CamelCase, .SnakeCase, .KebabCase, .ConstCase };

    // Find current mode index
    var current_index: usize = 0;
    for (sequence, 0..) |seq_mode, i| {
        if (seq_mode == mode) {
            current_index = i;
            break;
        }
    }

    // Find next non-excluded mode
    var next_index = (current_index + 1) % sequence.len;
    while (excluded.isExcluded(sequence[next_index]) and next_index != current_index) {
        next_index = (next_index + 1) % sequence.len;
    }

    // If all modes are excluded except current, return current
    if (next_index == current_index and excluded.isExcluded(sequence[next_index])) {
        return mode;
    }

    return sequence[next_index];
}

fn convertToCase(allocator: std.mem.Allocator, words: [][]u8, targetMode: CaseMode) ![]u8 {
    if (words.len == 0) return try allocator.dupe(u8, "");

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    switch (targetMode) {
        .TitleCase => {
            for (words) |word| {
                if (word.len > 0) {
                    try result.append(std.ascii.toUpper(word[0]));
                    if (word.len > 1) {
                        try result.appendSlice(word[1..]);
                    }
                }
            }
        },
        .CamelCase => {
            for (words, 0..) |word, i| {
                if (word.len > 0) {
                    if (i == 0) {
                        // First word stays lowercase
                        try result.appendSlice(word);
                    } else {
                        // Subsequent words are title cased
                        try result.append(std.ascii.toUpper(word[0]));
                        if (word.len > 1) {
                            try result.appendSlice(word[1..]);
                        }
                    }
                }
            }
        },
        .SnakeCase => {
            for (words, 0..) |word, i| {
                if (i > 0) try result.append('_');
                try result.appendSlice(word);
            }
        },
        .KebabCase => {
            for (words, 0..) |word, i| {
                if (i > 0) try result.append('-');
                try result.appendSlice(word);
            }
        },
        .ConstCase => {
            for (words, 0..) |word, i| {
                if (i > 0) try result.append('_');
                for (word) |char| {
                    try result.append(std.ascii.toUpper(char));
                }
            }
        },
    }

    return try result.toOwnedSlice();
}

fn identifyCase(word: []const u8) CaseMode {
    if (word.len == 0) return .CamelCase; // Default for empty strings

    const indexOfScalar = std.mem.indexOfScalar;
    if (indexOfScalar(u8, word, '_') != null) {
        if (std.ascii.isLower(word[0])) {
            return .SnakeCase;
        } else {
            return .ConstCase;
        }
    } else if (indexOfScalar(u8, word, '-') != null) {
        return .KebabCase;
    } else {
        // TitleCase
        // camelCase
        if (std.ascii.isLower(word[0])) {
            return .CamelCase;
        } else {
            return .TitleCase;
        }
    }
}

test "identifyCase recognises kebab-case" {
    const result = identifyCase("kebab-case");
    try testing.expectEqual(CaseMode.KebabCase, result);
}

test "identifyCase recognises snake_case" {
    const result = identifyCase("snake_case");
    try testing.expectEqual(CaseMode.SnakeCase, result);
}

test "identifyCase recognises CONST_CASE" {
    const result = identifyCase("CONST_CASE");
    try testing.expectEqual(CaseMode.ConstCase, result);
}
test "identifyCase recognises camelCase" {
    const result = identifyCase("camelCase");
    try testing.expectEqual(CaseMode.CamelCase, result);
}

test "identifyCase recognises TitleCase" {
    const result = identifyCase("TitleCase");
    try testing.expectEqual(CaseMode.TitleCase, result);
}

test "identifyCase recognises single lowercase word as camelCase" {
    const result = identifyCase("word");
    try testing.expectEqual(CaseMode.CamelCase, result);
}

test "identifyCase recognises single titlecase word as TitleCase" {
    const result = identifyCase("Word");
    try testing.expectEqual(CaseMode.TitleCase, result);
}

test "switcher function converts between case formats" {
    const allocator = std.testing.allocator;
    const no_exclusions = ExcludedCases{};

    // TitleCase -> CamelCase
    {
        const result = try switcher(allocator, "HelloWorld", no_exclusions);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("helloWorld", result);
    }

    // CamelCase -> SnakeCase
    {
        const result = try switcher(allocator, "helloWorld", no_exclusions);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("hello_world", result);
    }

    // SnakeCase -> KebabCase
    {
        const result = try switcher(allocator, "hello_world", no_exclusions);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("hello-world", result);
    }

    // KebabCase -> ConstCase
    {
        const result = try switcher(allocator, "hello-world", no_exclusions);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("HELLO_WORLD", result);
    }

    // ConstCase -> TitleCase
    {
        const result = try switcher(allocator, "HELLO_WORLD", no_exclusions);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("HelloWorld", result);
    }

    // Single words
    {
        const result = try switcher(allocator, "hello", no_exclusions);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("hello", result); // camelCase -> snake_case, but single word
    }

    // Empty string
    {
        const result = try switcher(allocator, "", no_exclusions);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("", result);
    }
}

test "nextMode with exclusions" {
    const no_exclusions = ExcludedCases{};

    // Test normal sequence without exclusions
    try testing.expectEqual(CaseMode.CamelCase, nextMode(.TitleCase, no_exclusions));
    try testing.expectEqual(CaseMode.SnakeCase, nextMode(.CamelCase, no_exclusions));
    try testing.expectEqual(CaseMode.KebabCase, nextMode(.SnakeCase, no_exclusions));
    try testing.expectEqual(CaseMode.ConstCase, nextMode(.KebabCase, no_exclusions));
    try testing.expectEqual(CaseMode.TitleCase, nextMode(.ConstCase, no_exclusions));

    // Test with camel case excluded - should skip camelCase
    const no_camel = ExcludedCases{ .camel_case = true };
    try testing.expectEqual(CaseMode.SnakeCase, nextMode(.TitleCase, no_camel));
    try testing.expectEqual(CaseMode.KebabCase, nextMode(.SnakeCase, no_camel));

    // Test with multiple exclusions
    const no_camel_kebab = ExcludedCases{ .camel_case = true, .kebab_case = true };
    try testing.expectEqual(CaseMode.SnakeCase, nextMode(.TitleCase, no_camel_kebab));
    try testing.expectEqual(CaseMode.ConstCase, nextMode(.SnakeCase, no_camel_kebab));

    // Test when current mode is excluded - should stay same
    const all_excluded = ExcludedCases{ .title_case = true, .camel_case = true, .snake_case = true, .kebab_case = true, .const_case = true };
    try testing.expectEqual(CaseMode.TitleCase, nextMode(.TitleCase, all_excluded));
}

test "switcher with exclusions" {
    const allocator = std.testing.allocator;

    // Test excluding camelCase: TitleCase -> SnakeCase instead of CamelCase
    {
        const no_camel = ExcludedCases{ .camel_case = true };
        const result = try switcher(allocator, "HelloWorld", no_camel);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("hello_world", result);
    }

    // Test excluding snake and kebab: CamelCase -> ConstCase (skips snake and kebab)
    {
        const no_snake_kebab = ExcludedCases{ .snake_case = true, .kebab_case = true };
        const result = try switcher(allocator, "helloWorld", no_snake_kebab);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("HELLO_WORLD", result);
    }

    // Test excluding everything but title and camel: should alternate between them
    {
        const only_title_camel = ExcludedCases{ .snake_case = true, .kebab_case = true, .const_case = true };

        // TitleCase -> CamelCase
        const result1 = try switcher(allocator, "HelloWorld", only_title_camel);
        defer allocator.free(result1);
        try std.testing.expectEqualStrings("helloWorld", result1);

        // CamelCase -> TitleCase (wraps around, skipping excluded ones)
        const result2 = try switcher(allocator, "helloWorld", only_title_camel);
        defer allocator.free(result2);
        try std.testing.expectEqualStrings("HelloWorld", result2);
    }
}

test "ExcludedCases isExcluded function" {
    const excluded = ExcludedCases{
        .title_case = true,
        .camel_case = false,
        .snake_case = true,
        .kebab_case = false,
        .const_case = true,
    };

    try testing.expect(excluded.isExcluded(.TitleCase));
    try testing.expect(!excluded.isExcluded(.CamelCase));
    try testing.expect(excluded.isExcluded(.SnakeCase));
    try testing.expect(!excluded.isExcluded(.KebabCase));
    try testing.expect(excluded.isExcluded(.ConstCase));
}

const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("case_switcher_lib");
