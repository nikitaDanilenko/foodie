package controllers.user

import pureconfig.generic.ProductHint
import pureconfig.generic.auto._
import pureconfig.{ CamelCase, ConfigFieldMapping, ConfigSource }
import services.mail.EmailParameters

case class UserConfiguration(
    restrictedDurationInSeconds: Int,
    subject: String,
    greeting: String,
    registrationMessage: String,
    recoveryMessage: String,
    deletionMessage: String,
    closing: String,
    frontend: String
)

object UserConfiguration {
  implicit def hint[A]: ProductHint[A] = ProductHint[A](ConfigFieldMapping(CamelCase, CamelCase))

  val default: UserConfiguration = ConfigSource.default
    .at("registrationConfiguration")
    .loadOrThrow[UserConfiguration]

  def registrationEmail(
      userConfiguration: UserConfiguration,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters =
    emailWith(
      userConfiguration = userConfiguration,
      addressWithMessage = emailComponents(userConfiguration)(Operation.Registration),
      userIdentifier = userIdentifier,
      jwt = jwt
    )

  def recoveryEmail(
      userConfiguration: UserConfiguration,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters =
    emailWith(
      userConfiguration,
      emailComponents(userConfiguration)(Operation.Recovery),
      userIdentifier = userIdentifier,
      jwt = jwt
    )

  def deletionEmail(
      userConfiguration: UserConfiguration,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters =
    emailWith(
      userConfiguration,
      emailComponents(userConfiguration)(Operation.Deletion),
      userIdentifier = userIdentifier,
      jwt = jwt
    )

  private sealed trait Operation

  private object Operation {
    case object Registration extends Operation
    case object Recovery     extends Operation
    case object Deletion     extends Operation
  }

  private case class AddressWithMessage(
      suffix: String,
      message: String
  )

  private def emailComponents(userConfiguration: UserConfiguration): Map[Operation, AddressWithMessage] =
    Map(
      Operation.Registration -> AddressWithMessage("finish-registration", userConfiguration.registrationMessage),
      Operation.Recovery     -> AddressWithMessage("account-recovery", userConfiguration.recoveryMessage),
      Operation.Registration -> AddressWithMessage("account-deletion", userConfiguration.deletionMessage)
    )

  private def emailWith(
      userConfiguration: UserConfiguration,
      addressWithMessage: AddressWithMessage,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters = {
    val message =
      s"""${userConfiguration.greeting} ${userIdentifier.nickname},
           |
           |${addressWithMessage.message}
           |
           |${userConfiguration.frontend}/#/${addressWithMessage.suffix}/$jwt
           |
           |${userConfiguration.closing}""".stripMargin

    EmailParameters(
      to = Seq(userIdentifier.email),
      cc = Seq.empty,
      subject = userConfiguration.subject,
      message = message
    )

  }

}
