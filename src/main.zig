const std = @import("std");
const gdc_spring_2025 = @import("gdc_spring_2025");

const hash_table = gdc_spring_2025.ecs.query.hash_table;

pub fn main() !void {
    gdc_spring_2025.ecs.App.run();
}
