#!/usr/bin/env bash
set -euo pipefail

BIN=./verify-lib
PASS=0
FAIL=0

expect_ok() {
    local desc="$1"; shift
    if "$BIN" "$@" >/dev/null 2>&1; then
        ((PASS++))
    else
        echo "FAIL (expected ok): $desc"
        ((FAIL++))
    fi
}

expect_fail() {
    local desc="$1"; shift
    if "$BIN" "$@" >/dev/null 2>&1; then
        echo "FAIL (expected fail): $desc"
        ((FAIL++))
    else
        ((PASS++))
    fi
}

PREFIX=$(mktemp -d)
LIB="${PREFIX}/lib"
trap 'rm -rf "$PREFIX"' EXIT

install -d -m 755 -o root -g root "$LIB"

# ── Valid file ──────────────────────────────────────────
echo '# valid library' > "${LIB}/good.sh"
chown root:root "${LIB}/good.sh"
chmod 644 "${LIB}/good.sh"
expect_ok "valid file" "${LIB}/good.sh" "${LIB}/"

# ── Output is resolved path ────────────────────────────
out=$("$BIN" "${LIB}/good.sh" "${LIB}/")
real=$(realpath "${LIB}/good.sh")
if [[ "$out" == "$real" ]]; then
    ((PASS++))
else
    echo "FAIL: output '$out' != expected '$real'"
    ((FAIL++))
fi

# ── Group-writable ─────────────────────────────────────
cp "${LIB}/good.sh" "${LIB}/gwrite.sh"
chmod 664 "${LIB}/gwrite.sh"
expect_fail "group-writable" "${LIB}/gwrite.sh" "${LIB}/"

# ── World-writable ─────────────────────────────────────
cp "${LIB}/good.sh" "${LIB}/wwrite.sh"
chmod 646 "${LIB}/wwrite.sh"
expect_fail "world-writable" "${LIB}/wwrite.sh" "${LIB}/"

# ── Symlink escaping prefix ────────────────────────────
ln -sf /etc/hostname "${LIB}/escape.sh"
expect_fail "symlink escape" "${LIB}/escape.sh" "${LIB}/"

# ── Nonexistent file ──────────────────────────────────
expect_fail "nonexistent" "${LIB}/nonexistent.sh" "${LIB}/"

# ── Wrong prefix ──────────────────────────────────────
expect_fail "wrong prefix" "${LIB}/good.sh" "/somewhere/else/"

# ── Not a regular file (directory) ────────────────────
mkdir -p "${LIB}/subdir"
expect_fail "directory" "${LIB}/subdir" "${LIB}/"

# ── Non-root owner ───────────────────────────────────
# Only testable if a non-root user exists
if id nobody &>/dev/null; then
    cp "${LIB}/good.sh" "${LIB}/badowner.sh"
    chown nobody:root "${LIB}/badowner.sh"
    chmod 644 "${LIB}/badowner.sh"
    expect_fail "non-root owner" "${LIB}/badowner.sh" "${LIB}/"
fi

# ── Non-root group ───────────────────────────────────
if getent group nobody &>/dev/null; then
    cp "${LIB}/good.sh" "${LIB}/badgroup.sh"
    chown root:nobody "${LIB}/badgroup.sh"
    chmod 644 "${LIB}/badgroup.sh"
    expect_fail "non-root group" "${LIB}/badgroup.sh" "${LIB}/"
fi

# ── Default prefix (no second arg) ───────────────────
# Should require /usr/lib/ prefix — our file is elsewhere
expect_fail "default prefix rejects" "${LIB}/good.sh"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
