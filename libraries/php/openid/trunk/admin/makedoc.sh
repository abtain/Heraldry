#!/bin/sh
set -v
phpdoc -p -t doc -d Auth,admin/tutorials,Services -ti "JanRain OpenID Library" \
    --ignore \*~,BigMath.php,Discover.php,CryptUtil.php,DiffieHellman.php,HMACSHA1.php,KVForm.php,Parse.php,TrustRoot.php,HTTPFetcher.php,ParanoidHTTPFetcher.php,PlainHTTPFetcher.php,ParseHTML.php,URINorm.php,XRI.php,XRIRes.php,Misc.php \
    -dn "OpenID" -o "HTML:frames:phphtmllib"
