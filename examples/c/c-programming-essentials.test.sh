#!/bin/sh
set -eu

binary=$1

assert_contains() {
  case $output in
    *"$1"*) ;;
    *) printf 'Expected output to contain: %s\n' "$1" >&2; exit 1 ;;
  esac
}

output=$(printf '3\nAda Lovelace\n' | "$binary")
assert_contains 'Position 2: 9'
assert_contains 'Hello, Ada Lovelace!'

output=$(printf ' +2 \nGrace Hopper\n' | "$binary")
assert_contains 'Position 1: 4'
assert_contains 'Hello, Grace Hopper!'

for count in 0 -2 invalid 50000 999999999999999999999999999999999999; do
  output=$(printf '%s\nAda\n' "$count" | "$binary")
  assert_contains 'Error: Enter a positive integer whose square fits in an int.'
  assert_contains 'Hello, Ada!'
done

long_count=$(printf '%0128d' 0)
output=$(printf '%s\nAda\n' "$long_count" | "$binary")
assert_contains 'Error: Number count is too long.'
assert_contains 'Hello, Ada!'

output=$("$binary" </dev/null)
assert_contains 'No number count read.'
assert_contains 'No name read.'

printf 'C walkthrough input checks passed.\n'
