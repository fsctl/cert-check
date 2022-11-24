function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s } 
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s } 
function trim(s) { return rtrim(ltrim(s)); } 
function cnfmt(s) { sub(/^.*CN=/, "", s); return s } 
function sha1fmt(s) { sub(/^SHA1 Fingerprint=/, "\033[31msha1:\033[0m ", s); return s } 
/Signature Algorithm/ { hex="" } 
/Modulus/ { hex="" } 
/pub:/ { hex="" } 
/SHA1/ { print "\033[31msignature:\033[0m " hex "\n" tolower(sha1fmt($0)) "\n" } 
/Exponent/ { print "\033[31mmodulus:\033[0m " hex } 
/ASN1 OID/ { print "\033[31mecc public key:\033[0m " hex } 
/([0-9a-f][0-9a-f]:)/ { hex = hex tolower(trim($0)) } 
/Subject:.*CN=/ { print "\033[1mCertificate (" cnfmt($0) ")\033[0m" }
