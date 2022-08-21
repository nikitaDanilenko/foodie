package utils.jwt

import java.security.{ Key, KeyPairGenerator }
import java.util.Base64

object KeyGen {

  def toBase64(key: Key): String =
    new String(Base64.getEncoder.encode(key.getEncoded))

  // Simplified key pair generator, intended as a reference only!
  def main(args: Array[String]): Unit = {
    val keyGenerator = KeyPairGenerator.getInstance("RSA")
    val pair         = keyGenerator.generateKeyPair()
    println(toBase64(pair.getPrivate))
    println(toBase64(pair.getPublic))
  }

}
