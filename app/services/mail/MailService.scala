package services.mail

import play.api.libs.mailer.{ Email, MailerClient }
import pureconfig.generic.ProductHint
import pureconfig.generic.auto._
import pureconfig.{ CamelCase, ConfigFieldMapping, ConfigSource }

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }
import scala.util.Try

class MailService @Inject() (
    mailerClient: MailerClient
)(implicit
    executionContext: ExecutionContext
) {

  implicit def hint[A]: ProductHint[A] = ProductHint[A](ConfigFieldMapping(CamelCase, CamelCase))

  private val mailConfig = ConfigSource.default
    .at("play.mailer")
    .loadOrThrow[MailConfiguration]

  def sendEmail(emailParameters: EmailParameters): Future[Unit] = {
    val email = Email(
      subject = emailParameters.subject,
      from = mailConfig.from,
      to = emailParameters.to,
      cc = emailParameters.cc,
      bodyText = Some(emailParameters.message)
    )
    Future {
      Try(mailerClient.send(email))
    }.flatMap(_.fold(Future.failed, _ => Future.unit))
  }

}
