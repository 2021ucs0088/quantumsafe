Here’s a cleaned-up, ready-to-copy version with proper markdown formatting so it looks nice on GitHub:

markdown
Copy
Edit
# Post-Quantum Cryptography (PQC) Web Security Setup

This project sets up a quantum-safe cryptographic environment using:

- OpenSSL 3.2 (custom build)  
- liboqs (Open Quantum Safe library)  
- oqs-provider (OpenSSL provider for PQC algorithms)  

---

## 🛠️ System Requirements

- Ubuntu 20.04 or later  
- `bash` shell  
- Basic development tools (git, build-essential, cmake, ninja, etc.)  

---

## ⚙️ Step-by-step Installation and Setup

1. **Clone or download this repository**  
   If you haven’t cloned yet, do:

   ```bash
   git clone https://github.com/2021ucs0088/quantumsafe.git
   cd quantumsafe
Make the setup script executable

bash
Copy
Edit
chmod +x setup_quantumsafe.sh
Run the setup script

bash
Copy
Edit
./setup_quantumsafe.sh
This will:

Install necessary dependencies via apt

Build and install OpenSSL 3.2 locally inside ~/quantumsafe/build

Build and install liboqs with Kyber and other PQC algorithms

Build and install the oqs-provider OpenSSL module

Configure OpenSSL to load the oqsprovider

✅ Testing PQC Algorithms
After successful setup, you can test post-quantum key generation and signatures:

bash
Copy
Edit
# Change directory to build folder where openssl binary is
cd ~/quantumsafe/build

# Generate Kyber768 key pair
./bin/openssl genpkey -algorithm KYBER768 -provider-path ./lib/ossl-modules -provider oqsprovider -out kyber_key.pem

# Generate Dilithium3 key pair
./bin/openssl genpkey -algorithm DILITHIUM3 -provider-path ./lib/ossl-modules -provider oqsprovider -out dilithium_key.pem

# Sign a message using Dilithium
echo "hello pqc" > message.txt
./bin/openssl dgst -sha256 -sign dilithium_key.pem -provider-path ./lib/ossl-modules -provider oqsprovider -out message.sig message.txt

# Verify the signature
./bin/openssl pkey -in dilithium_key.pem -pubout -provider-path ./lib/ossl-modules -provider oqsprovider -out dilithium_pub.pem
./bin/openssl dgst -sha256 -verify dilithium_pub.pem -signature message.sig message.txt
🧑‍💻 Author
2021ucs0088 (Bhanu Prakash)
GitHub: https://github.com/2021ucs0088









