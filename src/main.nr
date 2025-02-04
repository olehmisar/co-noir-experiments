global N: u32 = 1000;

fn main(a: [Field; 10], b: [Field; 10]) -> pub Field {
    let mut result = 0;
    for _ in 0..N {
        result += nodash::poseidon2(a.concat(b).concat([result]));
    }
    result
}
