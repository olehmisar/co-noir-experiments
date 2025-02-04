fn main(a: Field, b: Field) -> pub Field {
    let input = [a, b];
    std::hash::poseidon2::Poseidon2::hash(input, input.len())
}
