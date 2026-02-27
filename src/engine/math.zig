const std = @import("std");

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);
pub const Mat4 = [16]f32;

pub const pi: f32 = std.math.pi;

pub fn vec2Add(a: Vec2, b: Vec2) Vec2 {
    return a + b;
}

pub fn vec2Sub(a: Vec2, b: Vec2) Vec2 {
    return a - b;
}

pub fn vec2Scale(v: Vec2, s: f32) Vec2 {
    return v * @as(Vec2, @splat(s));
}

pub fn vec2Normalize(v: Vec2) Vec2 {
    const len = @sqrt(vec2Dot(v, v));
    if (len == 0) return .{ 0, 0 };
    return v / @as(Vec2, @splat(len));
}

pub fn vec2Dot(a: Vec2, b: Vec2) f32 {
    return @reduce(.Add, a * b);
}

pub fn vec2Cross(a: Vec2, b: Vec2) f32 {
    return a[0] * b[1] - a[1] * b[0];
}

pub fn vec2Length(v: Vec2) f32 {
    return @sqrt(vec2Dot(v, v));
}

pub fn vec2Distance(a: Vec2, b: Vec2) f32 {
    return vec2Length(vec2Sub(a, b));
}

pub fn vec3Add(a: Vec3, b: Vec3) Vec3 {
    return a + b;
}

pub fn vec3Sub(a: Vec3, b: Vec3) Vec3 {
    return a - b;
}

pub fn vec3Scale(v: Vec3, s: f32) Vec3 {
    return v * @as(Vec3, @splat(s));
}

pub fn vec3Normalize(v: Vec3) Vec3 {
    const len = @sqrt(vec3Dot(v, v));
    if (len == 0) return .{ 0, 0, 0 };
    return v / @as(Vec3, @splat(len));
}

pub fn vec3Dot(a: Vec3, b: Vec3) f32 {
    return @reduce(.Add, a * b);
}

pub fn vec3Cross(a: Vec3, b: Vec3) Vec3 {
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

pub fn vec3Length(v: Vec3) f32 {
    return @sqrt(vec3Dot(v, v));
}

pub fn vec3Distance(a: Vec3, b: Vec3) f32 {
    return vec3Length(vec3Sub(a, b));
}

pub fn vec3Lerp(a: Vec3, b: Vec3, t: f32) Vec3 {
    return vec3Add(vec3Scale(a, 1 - t), vec3Scale(b, t));
}

pub fn vec4Add(a: Vec4, b: Vec4) Vec4 {
    return a + b;
}

pub fn vec4Sub(a: Vec4, b: Vec4) Vec4 {
    return a - b;
}

pub fn vec4Scale(v: Vec4, s: f32) Vec4 {
    return v * @as(Vec4, @splat(s));
}

pub fn vec4Normalize(v: Vec4) Vec4 {
    const len = @sqrt(vec4Dot(v, v));
    if (len == 0) return .{ 0, 0, 0, 1 };
    return v / @as(Vec4, @splat(len));
}

pub fn vec4Dot(a: Vec4, b: Vec4) f32 {
    return @reduce(.Add, a * b);
}

pub fn vec4Length(v: Vec4) f32 {
    return @sqrt(vec4Dot(v, v));
}

pub fn quatFromEuler(euler: Vec3) Vec4 {
    const cx = @cos(euler[0] * 0.5);
    const sx = @sin(euler[0] * 0.5);
    const cy = @cos(euler[1] * 0.5);
    const sy = @sin(euler[1] * 0.5);
    const cz = @cos(euler[2] * 0.5);
    const sz = @sin(euler[2] * 0.5);

    return .{
        sx * cy * cz - cx * sy * sz,
        cx * sy * cz + sx * cy * sz,
        cx * cy * sz - sx * sy * cz,
        cx * cy * cz + sx * sy * sz,
    };
}

pub fn eulerFromQuat(q: Vec4) Vec3 {
    const sinr_cosp = 2 * (q[3] * q[0] + q[1] * q[2]);
    const cosr_cosp = 1 - 2 * (q[0] * q[0] + q[1] * q[1]);
    const roll = std.math.atan2(sinr_cosp, cosr_cosp);

    const sinp = 2 * (q[3] * q[1] - q[2] * q[0]);
    var pitch: f32 = undefined;
    if (@abs(sinp) >= 1) {
        pitch = std.math.copysign(pi / 2, sinp);
    } else {
        pitch = std.math.asin(sinp);
    }

    const siny_cosp = 2 * (q[3] * q[2] + q[0] * q[1]);
    const cosy_cosp = 1 - 2 * (q[1] * q[1] + q[2] * q[2]);
    const yaw = std.math.atan2(siny_cosp, cosy_cosp);

    return .{ pitch, yaw, roll };
}

pub fn quatMultiply(a: Vec4, b: Vec4) Vec4 {
    return .{
        a[3] * b[0] + a[0] * b[3] + a[1] * b[2] - a[2] * b[1],
        a[3] * b[1] - a[0] * b[2] + a[1] * b[3] + a[2] * b[0],
        a[3] * b[2] + a[0] * b[1] - a[1] * b[0] + a[2] * b[3],
        a[3] * b[3] - a[0] * b[0] - a[1] * b[1] - a[2] * b[2],
    };
}

pub fn quatConjugate(q: Vec4) Vec4 {
    return .{ -q[0], -q[1], -q[2], q[3] };
}

pub fn quatNormalize(q: Vec4) Vec4 {
    return vec4Normalize(q);
}

pub fn quatFromAxisAngle(axis: Vec3, angle: f32) Vec4 {
    const half_angle = angle * 0.5;
    const s = @sin(half_angle);
    const norm_axis = vec3Normalize(axis);
    return .{ norm_axis[0] * s, norm_axis[1] * s, norm_axis[2] * s, @cos(half_angle) };
}

pub fn quatSlerp(a: Vec4, b: Vec4, t: f32) Vec4 {
    var dot = vec4Dot(a, b);

    var qb = b;
    if (dot < 0) {
        qb = vec4Scale(b, -1);
        dot = -dot;
    }

    if (dot > 0.9995) {
        return vec4Normalize(vec4Add(a, vec4Scale(vec4Sub(qb, a), t)));
    }

    const theta_0 = std.math.acos(dot);
    const theta = theta_0 * t;

    const s0 = @cos(theta) - dot * @sin(theta) / @sin(theta_0);
    const s1 = @sin(theta) / @sin(theta_0);

    return vec4Add(vec4Scale(a, s0), vec4Scale(qb, s1));
}

pub fn vec3RotateByQuat(q: Vec4, v: Vec3) Vec3 {
    const qv: Vec3 = .{ q[0], q[1], q[2] };
    const uv = vec3Cross(qv, v);
    const uuv = vec3Cross(qv, uv);
    const w = q[3];
    return v + vec3Scale(uv, 2 * w) + vec3Scale(uuv, 2);
}

pub fn mat4Identity(m: *Mat4) void {
    @memset(m, 0);
    m[0] = 1;
    m[5] = 1;
    m[10] = 1;
    m[15] = 1;
}

pub fn mat4SetIdentity() Mat4 {
    var m: Mat4 = undefined;
    mat4Identity(&m);
    return m;
}

pub fn mat4Translate(m: *Mat4, v: Vec3) void {
    const t: Mat4 = .{
        1,    0,    0,    0,
        0,    1,    0,    0,
        0,    0,    1,    0,
        v[0], v[1], v[2], 1,
    };
    var result: Mat4 = undefined;
    mat4Multiply(&result, m, &t);
    m.* = result;
}

pub fn mat4RotateX(m: *Mat4, angle: f32) void {
    const c = @cos(angle);
    const s = @sin(angle);
    const r: Mat4 = .{
        1, 0,  0, 0,
        0, c,  s, 0,
        0, -s, c, 0,
        0, 0,  0, 1,
    };
    var result: Mat4 = undefined;
    mat4Multiply(&result, m, &r);
    m.* = result;
}

pub fn mat4RotateY(m: *Mat4, angle: f32) void {
    const c = @cos(angle);
    const s = @sin(angle);
    const r: Mat4 = .{
        c, 0, -s, 0,
        0, 1, 0,  0,
        s, 0, c,  0,
        0, 0, 0,  1,
    };
    var result: Mat4 = undefined;
    mat4Multiply(&result, m, &r);
    m.* = result;
}

pub fn mat4RotateZ(m: *Mat4, angle: f32) void {
    const c = @cos(angle);
    const s = @sin(angle);
    const r: Mat4 = .{
        c,  s, 0, 0,
        -s, c, 0, 0,
        0,  0, 1, 0,
        0,  0, 0, 1,
    };
    var result: Mat4 = undefined;
    mat4Multiply(&result, m, &r);
    m.* = result;
}

pub fn mat4RotateQuat(m: *Mat4, q: Vec4) void {
    const qn = quatNormalize(q);
    const xx = qn[0] * qn[0];
    const yy = qn[1] * qn[1];
    const zz = qn[2] * qn[2];
    const xy = qn[0] * qn[1];
    const xz = qn[0] * qn[2];
    const yz = qn[1] * qn[2];
    const wx = qn[3] * qn[0];
    const wy = qn[3] * qn[1];
    const wz = qn[3] * qn[2];

    const r: Mat4 = .{
        1 - 2 * (yy + zz), 2 * (xy + wz),     2 * (xz - wy),     0,
        2 * (xy - wz),     1 - 2 * (xx + zz), 2 * (yz + wx),     0,
        2 * (xz + wy),     2 * (yz - wx),     1 - 2 * (xx + yy), 0,
        0,                 0,                 0,                 1,
    };
    var result: Mat4 = undefined;
    mat4Multiply(&result, m, &r);
    m.* = result;
}

pub fn mat4Scale(m: *Mat4, v: Vec3) void {
    const s: Mat4 = .{
        v[0], 0,    0,    0,
        0,    v[1], 0,    0,
        0,    0,    v[2], 0,
        0,    0,    0,    1,
    };
    var result: Mat4 = undefined;
    mat4Multiply(&result, m, &s);
    m.* = result;
}

pub fn mat4Multiply(out: *Mat4, a: *const Mat4, b: *const Mat4) void {
    var result: Mat4 = undefined;
    for (0..4) |col| {
        for (0..4) |row| {
            var sum: f32 = 0;
            for (0..4) |k| {
                sum += a[k * 4 + row] * b[col * 4 + k];
            }
            result[col * 4 + row] = sum;
        }
    }
    out.* = result;
}

pub fn mat4MultiplyToOut(a: *const Mat4, b: *const Mat4) Mat4 {
    var result: Mat4 = undefined;
    mat4Multiply(&result, a, b);
    return result;
}

pub fn mat4Perspective(m: *Mat4, fov_rad: f32, aspect: f32, near: f32, far: f32) void {
    @memset(m, 0);
    const tan_half_fov = @tan(fov_rad * 0.5);
    const focal = 1.0 / tan_half_fov;
    m[0] = focal / aspect;
    m[5] = focal;
    m[10] = far / (far - near);
    m[14] = -(far * near) / (far - near);
    m[11] = 1;
}

pub fn mat4Ortho(m: *Mat4, left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) void {
    @memset(m, 0);
    m[0] = 2 / (right - left);
    m[5] = 2 / (top - bottom);
    m[10] = 1 / (far - near);
    m[12] = -(right + left) / (right - left);
    m[13] = -(top + bottom) / (top - bottom);
    m[14] = -near / (far - near);
    m[15] = 1;
}

pub fn mat4LookAt(m: *Mat4, eye: Vec3, target: Vec3, up: Vec3) void {
    const f = vec3Normalize(vec3Sub(target, eye));
    const r = vec3Normalize(vec3Cross(f, up));
    const u = vec3Cross(r, f);

    m[0] = r[0];
    m[1] = u[0];
    m[2] = -f[0];
    m[3] = 0;
    m[4] = r[1];
    m[5] = u[1];
    m[6] = -f[1];
    m[7] = 0;
    m[8] = r[2];
    m[9] = u[2];
    m[10] = -f[2];
    m[11] = 0;
    m[12] = -vec3Dot(r, eye);
    m[13] = -vec3Dot(u, eye);
    m[14] = vec3Dot(f, eye);
    m[15] = 1;
}

pub fn mat4Inverse(out: *Mat4, m: *const Mat4) void {
    const a00 = m[0];
    const a01 = m[1];
    const a02 = m[2];
    const a03 = m[3];
    const a10 = m[4];
    const a11 = m[5];
    const a12 = m[6];
    const a13 = m[7];
    const a20 = m[8];
    const a21 = m[9];
    const a22 = m[10];
    const a23 = m[11];
    const a30 = m[12];
    const a31 = m[13];
    const a32 = m[14];
    const a33 = m[15];

    const b00 = a00 * a11 - a01 * a10;
    const b01 = a00 * a12 - a02 * a10;
    const b02 = a00 * a13 - a03 * a10;
    const b03 = a01 * a12 - a02 * a11;
    const b04 = a01 * a13 - a03 * a11;
    const b05 = a02 * a13 - a03 * a12;
    const b06 = a20 * a31 - a21 * a30;
    const b07 = a20 * a32 - a22 * a30;
    const b08 = a20 * a33 - a23 * a30;
    const b09 = a21 * a32 - a22 * a31;
    const b10 = a21 * a33 - a23 * a31;
    const b11 = a22 * a33 - a23 * a32;

    var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
    if (@abs(det) < 0.0001) {
        mat4Identity(out);
        return;
    }
    det = 1.0 / det;

    out[0] = (a11 * b11 - a12 * b10 + a13 * b09) * det;
    out[1] = (a02 * b10 - a01 * b11 - a03 * b09) * det;
    out[2] = (a31 * b05 - a32 * b04 + a33 * b03) * det;
    out[3] = (a22 * b04 - a21 * b05 - a23 * b03) * det;
    out[4] = (a12 * b08 - a10 * b11 - a13 * b07) * det;
    out[5] = (a00 * b11 - a02 * b08 + a03 * b07) * det;
    out[6] = (a32 * b02 - a30 * b05 - a33 * b01) * det;
    out[7] = (a20 * b05 - a22 * b02 + a23 * b01) * det;
    out[8] = (a10 * b10 - a11 * b08 + a13 * b06) * det;
    out[9] = (a01 * b08 - a00 * b10 - a03 * b06) * det;
    out[10] = (a30 * b04 - a31 * b02 + a33 * b00) * det;
    out[11] = (a21 * b02 - a20 * b04 - a23 * b00) * det;
    out[12] = (a11 * b07 - a10 * b09 - a12 * b06) * det;
    out[13] = (a00 * b09 - a01 * b07 + a02 * b06) * det;
    out[14] = (a31 * b01 - a30 * b03 - a32 * b00) * det;
    out[15] = (a20 * b03 - a21 * b01 + a22 * b00) * det;
}

pub fn mat4Transpose(out: *Mat4, m: *const Mat4) void {
    out[0] = m[0];
    out[1] = m[4];
    out[2] = m[8];
    out[3] = m[12];
    out[4] = m[1];
    out[5] = m[5];
    out[6] = m[9];
    out[7] = m[13];
    out[8] = m[2];
    out[9] = m[6];
    out[10] = m[10];
    out[11] = m[14];
    out[12] = m[3];
    out[13] = m[7];
    out[14] = m[11];
    out[15] = m[15];
}

pub fn mat4GetTranslation(m: *const Mat4) Vec3 {
    return .{ m[12], m[13], m[14] };
}

pub fn mat4GetScale(m: *const Mat4) Vec3 {
    return .{
        vec3Length(.{ m[0], m[1], m[2] }),
        vec3Length(.{ m[4], m[5], m[6] }),
        vec3Length(.{ m[8], m[9], m[10] }),
    };
}

pub fn clamp(value: f32, min_val: f32, max_val: f32) f32 {
    return @max(min_val, @min(max_val, value));
}

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

pub fn degToRad(degrees: f32) f32 {
    return degrees * pi / 180.0;
}

pub fn radToDeg(radians: f32) f32 {
    return radians * 180.0 / pi;
}

test "vec3 operations" {
    const a: Vec3 = .{ 1, 2, 3 };
    const b: Vec3 = .{ 4, 5, 6 };

    const sum = vec3Add(a, b);
    try std.testing.expectApproxEqAbs(@as(f32, 5), sum[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 7), sum[1], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 9), sum[2], 0.001);

    const cross = vec3Cross(a, b);
    try std.testing.expectApproxEqAbs(@as(f32, -3), cross[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 6), cross[1], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, -3), cross[2], 0.001);
}

test "mat4 identity and multiply" {
    var m: Mat4 = undefined;
    mat4Identity(&m);

    try std.testing.expectApproxEqAbs(@as(f32, 1), m[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), m[5], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), m[10], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), m[15], 0.001);

    var a: Mat4 = undefined;
    var b: Mat4 = undefined;
    mat4Identity(&a);
    mat4Identity(&b);

    var result: Mat4 = undefined;
    mat4Multiply(&result, &a, &b);

    try std.testing.expectApproxEqAbs(@as(f32, 1), result[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), result[5], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), result[10], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), result[15], 0.001);
}

test "quaternion operations" {
    const q = quatFromEuler(.{ 0, pi / 4, 0 });
    const conj = quatConjugate(q);

    try std.testing.expectApproxEqAbs(q[0], -conj[0], 0.001);
    try std.testing.expectApproxEqAbs(q[1], -conj[1], 0.001);
    try std.testing.expectApproxEqAbs(q[2], -conj[2], 0.001);
    try std.testing.expectApproxEqAbs(q[3], conj[3], 0.001);
}

comptime {
    std.testing.refAllDecls(@This());
}
