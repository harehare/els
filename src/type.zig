pub fn Tuple(comptime T: type) type {
    return struct { v1: T, v2: T };
}

pub const TupleOfUsize = Tuple(usize);
