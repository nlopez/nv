/*
 *  hmacsha1.h
 *  Notation
 *
 *  HMAC-SHA1 using CommonCrypto.
 */

#include <stdint.h>
#include <sys/types.h>

extern void hmac_sha1(const void *key, size_t keylen, const void *in, size_t inlen, void *resbuf);
