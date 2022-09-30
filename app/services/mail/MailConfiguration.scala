package services.mail

case class MailConfiguration(
    host: String,
    tls: String,
    from: String,
    port: Int,
    user: Option[String],
    password: Option[String]
)
