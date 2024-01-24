#!/bin/sh
/usr/bin/expect <<END_EXPECT
    spawn easyrsa --vars=./vars build-ca
    expect "Enter New CA Key Passphrase:"
    send "$PASSPHRASE\r"
    expect "Re-Enter New CA Key Passphrase:"
    send "$PASSPHRASE\r"
    expect eof
END_EXPECT