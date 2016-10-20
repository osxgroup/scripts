#!/bin/bash

# reads the postfix virtual_users file
# each account (the right column) is checkced with 'id <username>
# report is printed


FILE=/Library/Server/Mail/Config/postfix/virtual_users

grep -B1000 -m1 -i mailman "$FILE" | grep -vE '#|^$' | while read -r line
do
  VIR="$(echo "$line" | awk '{print $1}')"
  USR="$(echo "$line" | awk '{print $2}')"
  id "$USR" &>/dev/null && STATUS=OK || STATUS="Does not exist"
  printf '%-18s %-40s %-24s\n' "$STATUS" "$VIR" "$USR"
done | sort

exit 0

# TO DO
# switch to delete non-existent
 
