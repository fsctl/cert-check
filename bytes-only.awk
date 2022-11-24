function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s } 
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s } 
function trim(s) { return rtrim(ltrim(s)); } 
function cnfmt(s) { sub(/^.*CN=/, "", s); return s } 
function sha1fmt(s) { sub(/^SHA1 Fingerprint=/, "", s); return s } 
/Signature Algorithm/ { hex="" } 
/Modulus/ { hex="" } 
/pub:/ { hex="" } 
/SHA1/ { printf "%s,%s\n",hex,tolower(sha1fmt($0)) } 
/Exponent/ { printf "%s,",hex } 
/ASN1 OID/ { printf "%s,",hex } 
/([0-9a-f][0-9a-f]:)/ { hex = hex tolower(trim($0)) } 
/Subject:.*CN=/ { printf "%s,",cnfmt($0) }
