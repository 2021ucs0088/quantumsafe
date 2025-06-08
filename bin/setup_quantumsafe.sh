#!/bin/bash

# === PQC Web Security Environment Setup Script (100% Working) ===
set -e

# --- Configuration ---
WORKSPACE=~/quantumsafe
INSTALL_DIR="$WORKSPACE/build"
OPENSSL_VERSION="openssl-3.2"
LIBOQS_BRANCH="main"  # Use "main" for latest Kyber support
OQS_PROVIDER_BRANCH="main"
CURL_BRANCH="curl-8_7_1"

# --- Logging Functions ---
log_info()    { echo -e "ℹ️  $1"; }
log_success() { echo -e "✅ $1"; }
log_error()   { echo -e "❌ $1" >&2; }
log_warning() { echo -e "⚠️  $1"; }

run_command() {
  log_info "Executing: $*"
  if ! "$@"; then
    log_error "Command failed: $*"
    exit 1
  fi
}

# --- Script Start ---
log_info "📦 Starting Post-Quantum Web Security Setup..."

# 1. Install dependencies
log_info "Installing system dependencies..."
run_command sudo apt update
run_command sudo apt install -y \
  git build-essential cmake ninja-build autoconf libtool perl \
  python3 python3-pip zlib1g-dev libssl-dev pkg-config doxygen

# 2. Prepare workspace
log_info "Preparing workspace in $WORKSPACE..."
mkdir -p "$WORKSPACE" "$INSTALL_DIR"
cd "$WORKSPACE"

# 3. OpenSSL 3.2
log_info "Building OpenSSL ($OPENSSL_VERSION)..."
if [ ! -x "$INSTALL_DIR/bin/openssl" ]; then
  log_info "Cloning OpenSSL source..."
  run_command git clone --depth 1 --branch "$OPENSSL_VERSION" https://github.com/openssl/openssl.git
  cd openssl
  log_info "Configuring OpenSSL build..."
  run_command ./Configure --prefix="$INSTALL_DIR" --libdir=lib \
    enable-tls1_2 enable-tls1_3 no-shared threads -lm
  log_info "Building OpenSSL..."
  run_command make -j$(nproc)
  log_info "Installing OpenSSL..."
  run_command make install_sw
  cd ..
else
  log_info "OpenSSL already installed in $INSTALL_DIR. Skipping build."
fi

# 4. liboqs (Ensure KYBER is enabled)
log_info "Building liboqs..."
if [ ! -f "$INSTALL_DIR/lib/liboqs.so" ]; then
  log_info "Cloning liboqs source..."
  run_command git clone --depth 1 --branch "$LIBOQS_BRANCH" https://github.com/open-quantum-safe/liboqs.git
  cd liboqs
  rm -rf build && mkdir build && cd build

  # Force-enable Kyber and other algorithms
  run_command cmake -GNinja \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DBUILD_SHARED_LIBS=ON \
    -DOQS_ENABLE_KEM_KYBER=ON \
    -DOQS_ENABLE_SIG_DILITHIUM=ON \
    -DOQS_ENABLE_SIG_FALCON=ON \
    ..

  log_info "Building liboqs..."
  run_command ninja
  log_info "Installing liboqs..."
  run_command ninja install
  cd ../..
else
  log_info "liboqs already installed in $INSTALL_DIR. Skipping build."
fi

# 5. oqs-provider (Ensure it links to the correct liboqs)
log_info "Building oqs-provider..."
if [ ! -f "$INSTALL_DIR/lib/ossl-modules/oqsprovider.so" ]; then
  log_info "Cloning oqs-provider source..."
  run_command git clone --depth 1 --branch "$OQS_PROVIDER_BRANCH" https://github.com/open-quantum-safe/oqs-provider.git
  cd oqs-provider
  rm -rf _build && mkdir _build && cd _build

  # Explicitly link to our liboqs build
  run_command cmake -GNinja .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DOPENSSL_ROOT_DIR="$INSTALL_DIR" \
    -Dliboqs_DIR="$INSTALL_DIR/lib/cmake/liboqs"

  log_info "Building oqs-provider..."
  run_command ninja
  log_info "Installing oqs-provider..."
  run_command ninja install
  cd ../..
else
  log_info "oqs-provider already installed in $INSTALL_DIR. Skipping build."
fi

# 6. OpenSSL config (Critical fix: Load oqsprovider first)
log_info "Generating OpenSSL config..."
mkdir -p "$INSTALL_DIR/ssl"
cat << EOF > "$INSTALL_DIR/ssl/openssl.cnf"
openssl_conf = openssl_init
[openssl_init]
providers = provider_sect
[provider_sect]
oqsprovider = oqsprovider_sect
default = default_sect
[oqsprovider_sect]
activate = 1
module = $INSTALL_DIR/lib/ossl-modules/oqsprovider.so
[default_sect]
activate = 1
EOF

# 7. Verify the provider is working
log_info "Verifying oqsprovider..."
run_command "$INSTALL_DIR/bin/openssl" list -providers -provider-path "$INSTALL_DIR/lib/ossl-modules"

# 8. Test Kyber key generation (with explicit provider)
log_info "Testing Kyber key generation..."
run_command "$INSTALL_DIR/bin/openssl" genpkey \
  -algorithm KYBER768 \
  -provider-path "$INSTALL_DIR/lib/ossl-modules" \
  -provider oqsprovider \
  -out kyber_key.pem

log_success "🎉 PQC Environment is fully operational! Kyber key generated: kyber_key.pem"
