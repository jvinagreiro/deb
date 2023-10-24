#!/bin/sh
#
# Tries to obtain a MAC address for the interface given as the first argument.
# If NOR is available first look for a norstore variable with a nane
# consisting of the interface name, followed by "_MAC". Otherwise
# look for a file with the same name in /etc/MAC. If all this fails
# create a mostly random MAC and store it in a file in /etc/MAC.

iface=$1

if [ -z "$iface" ]
then
    echo ""
    return 1
fi

# If we have NOR it may contain the MAC. The key is the interface name, followed
# by '_MAC'. If it exists just return it, no further checks needed.

if [ -c /dev/mtd7 ]
then
    mac=$(nor_store -g "${iface}_MAC" 2>/dev/null)
    if [ -n "$mac" ]
    then
        echo "$mac"
        return 0
    fi
fi

# There could be a non-empty, readable file with the MAC address. Read it
# and check its content.

mac=""
mac_file="/etc/MAC/${iface}_MAC"

if [ -n "$mac_file" -a -r "$mac_file" ]; then
    mac=$(cat "$mac_file" | tr -d '\t \n');

    # Sanity checks: MAC must have the form "ab:cd:ef:gh:ij:kl" and
    # may neither be 00:00:00:00:00:00 nor ff:ff:ff:ff:ff:ff. Finally,
    # the LSB of the first octet may not be 1 and the next one must be 1.

    mac=$(echo -n "$mac" | grep -i '^\([0-9a-f]\{2\}:\)\{5\}[0-9a-f]\{2\}$')

    if [    "$mac" = "00:00:00:00:00:00" \
        -o "$mac" = "ff:ff:ff:ff:ff:ff" ]
    then
        mac=""
    fi

    # As these MACs aren't official but locally make sure they have the
    # corresponding bit set in the first byte.

    mac=$(echo -n "${mac}" | grep -i '^[0-9a-f][26ae]');
fi

# If there's no useful file with a MAC address or it doesn't contain a
# valid one use a MAC that's random in the last three octets. The first
# three are always the same (with the second and third being set to
# "ebee") to make it simpler to recognize.

if [ -z "$mac" ]
then
    mac="42:eb:ee"$(  dd bs=3 count=1 if=/dev/urandom 2>/dev/null \
                    | hexdump -v -e '/1 ":%02x"')
    echo -n "$mac" > $mac_file
fi

echo $mac


# Local variables:
# tab-width: 4
# indent-tabs-mode: nil
# End:
