const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Open file
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    // Read to buffer
    const stat = try file.stat(); // Get file stats (mostly size)
    const content = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(content);

    // ArrayList to store numbers
    var numbers1 = std.ArrayList(i32).init(allocator);
    var numbers2 = std.ArrayList(i32).init(allocator);
    defer numbers1.deinit();
    defer numbers2.deinit();

    // Split lines
    var lines = std.mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            std.debug.print("Empty line", .{}); // Skip empty liens
            continue;
        }

        // Split line in 2 parts
        var parts = std.mem.splitSequence(u8, line, "   ");
        const part1 = parts.next() orelse continue;
        const part2 = parts.next() orelse continue;

        // Parse both numbers
        const num1 = try std.fmt.parseInt(i32, part1, 10);
        const num2 = try std.fmt.parseInt(i32, part2, 10);

        try numbers1.append(num1);
        try numbers2.append(num2);
    }
    std.debug.print("Size: {d}\n", .{numbers1.items.len});

    //PART 1

    // Sort both lists
    std.mem.sort(i32, numbers1.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, numbers2.items, {}, comptime std.sort.asc(i32));

    var total: u32 = 0;
    for (numbers1.items, numbers2.items) |num1, num2| {
        total += @abs(num1 - num2);
        // std.debug.print("{d} {d}\n", .{ num1, num2 });
    }
    std.debug.print("Total: {d}\n", .{total});

    // PART 2
    // Find numbers from the left list in the right list
    // Multiply number of occurrences by the value itself
    // Example: 3 is found 3 times in the second list, we add 3*3 to the similarity score
    var similarity: i32 = 0;
    for (numbers1.items) |target| {
        similarity += countOccurrences(numbers2.items, target) * target;
    }
    std.debug.print("Similarity: {d}\n", .{similarity});
}

fn countOccurrences(list: []const i32, target: i32) i32 {
    var times: i32 = 0;
    for (list) |val| {
        if (val == target) times += 1;
    }
    return times;
}
