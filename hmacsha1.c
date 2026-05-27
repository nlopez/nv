/*
 *  hmacsha1.c
 *  Notation
 *
 *  HMAC-SHA1 wrapper using CommonCrypto.
 */

#include "hmacsha1.h"
#include <CommonCrypto/CommonHMAC.h>

void hmac_sha1(const void *key, size_t keylen, const void *in, size_t inlen, void *resbuf) {
    CCHmac(kCCHmacAlgSHA1, key, keylen, in, inlen, resbuf);
}
