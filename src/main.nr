global N: u32 = 10;

fn main(a: [Field; N], b: [Field; N]) -> pub Field {
    nodash::poseidon2(a.concat(b))
}
