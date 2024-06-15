#!/bin/bash

# WALLET_WITH_FUNDS=~/.config/solana/mango-devnet.json
# PROGRAM_ID=LehFymqUgQkZyUD2JedHgbTEcHNseyuLnWotwG7zPBB

anchor build -- --features enable-gpl
./idl-fixup.sh
RUST_BACKTRACE=full anchor test --skip-build
