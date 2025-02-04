set -euo pipefail

nargo compile
echo "Compiled"

CIRCUIT=target/circ.json

# split input into shares
co-noir split-input --circuit $CIRCUIT --input Prover1.toml --protocol REP3 --out-dir target
co-noir split-input --circuit $CIRCUIT --input Prover2.toml --protocol REP3 --out-dir target
echo "Inputs split"

# merge inputs into single input file
co-noir merge-input-shares --inputs target/Prover1.toml.0.shared --inputs target/Prover2.toml.0.shared --protocol REP3 --out target/Prover.toml.0.shared
co-noir merge-input-shares --inputs target/Prover1.toml.1.shared --inputs target/Prover2.toml.1.shared --protocol REP3 --out target/Prover.toml.1.shared
co-noir merge-input-shares --inputs target/Prover1.toml.2.shared --inputs target/Prover2.toml.2.shared --protocol REP3 --out target/Prover.toml.2.shared
echo "Inputs merged"

# run witness extension in MPC
co-noir generate-witness --input target/Prover.toml.0.shared --circuit $CIRCUIT --protocol REP3 --config configs/party0.toml --out target/witness.gz.0.shared &
co-noir generate-witness --input target/Prover.toml.1.shared --circuit $CIRCUIT --protocol REP3 --config configs/party1.toml --out target/witness.gz.1.shared &
co-noir generate-witness --input target/Prover.toml.2.shared --circuit $CIRCUIT --protocol REP3 --config configs/party2.toml --out target/witness.gz.2.shared
wait $(jobs -p)
echo "Witnesses generated"

# run proving in MPC
co-noir build-and-generate-proof --witness target/witness.gz.0.shared --circuit $CIRCUIT --crs bn254_g1.dat --protocol REP3 --hasher KECCAK --config configs/party0.toml --out target/proof.0.proof --public-input target/public_input.json &
co-noir build-and-generate-proof --witness target/witness.gz.1.shared --circuit $CIRCUIT --crs bn254_g1.dat --protocol REP3 --hasher KECCAK --config configs/party1.toml --out target/proof.1.proof &
co-noir build-and-generate-proof --witness target/witness.gz.2.shared --circuit $CIRCUIT --crs bn254_g1.dat --protocol REP3 --hasher KECCAK --config configs/party2.toml --out target/proof.2.proof
wait $(jobs -p)
echo "Proofs generated"

# Create verification key
co-noir create-vk --circuit $CIRCUIT --crs bn254_g1.dat --hasher KECCAK --vk target/verification_key
echo "Verification key created"

# verify proof
co-noir verify --proof target/proof.0.proof --vk target/verification_key --hasher KECCAK --crs bn254_g2.dat
echo "Proof verified"

# Double check with bb
bb write_vk_ultra_keccak_honk -b $CIRCUIT -o target/verification_key_bb
echo "Verification key created with bb"
bb verify_ultra_keccak_honk -p target/proof.0.proof -k target/verification_key_bb
echo "Proof verified with bb"
