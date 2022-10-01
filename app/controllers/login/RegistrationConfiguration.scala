package controllers.login

import pureconfig.generic.ProductHint
import pureconfig.generic.auto._
import pureconfig.{ CamelCase, ConfigFieldMapping, ConfigSource }
import services.mail.EmailParameters

case class RegistrationConfiguration(
    restrictedDurationInSeconds: Int,
    subject: String,
    greeting: String,
    body: String,
    closing: String,
    frontend: String
)

object RegistrationConfiguration {
  implicit def hint[A]: ProductHint[A] = ProductHint[A](ConfigFieldMapping(CamelCase, CamelCase))

  val default: RegistrationConfiguration = ConfigSource.default
    .at("registrationConfiguration")
    .loadOrThrow[RegistrationConfiguration]

  def email(
      registrationConfiguration: RegistrationConfiguration,
      registrationRequest: RegistrationRequest,
      jwt: String
  ): EmailParameters = {
    val message =
      s"""${registrationConfiguration.greeting} ${registrationRequest.nickname},
         |
         |${registrationConfiguration.body}
         |
         |${registrationConfiguration.frontend}/#/finish-registration/$jwt
         |
         |${registrationConfiguration.closing}""".stripMargin

    EmailParameters(
      to = Seq(registrationRequest.email),
      cc = Seq.empty,
      subject = registrationConfiguration.subject,
      message = message
    )

  }

}
