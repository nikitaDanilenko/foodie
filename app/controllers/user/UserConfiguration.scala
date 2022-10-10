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
    .at("userConfiguration")
    .loadOrThrow[UserConfiguration]

  def registrationEmail(
      userConfiguration: UserConfiguration,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters =
    emailWith(
      userConfiguration = userConfiguration,
      operation = Operation.Registration,
      userIdentifier = userIdentifier,
      jwt = jwt
    )

  def recoveryEmail(
      userConfiguration: UserConfiguration,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters =
    emailWith(
      userConfiguration = userConfiguration,
      operation = Operation.Recovery,
      userIdentifier = userIdentifier,
      jwt = jwt
    )

  def deletionEmail(
      userConfiguration: UserConfiguration,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters =
    emailWith(
      userConfiguration = userConfiguration,
      operation = Operation.Deletion,
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
      Operation.Registration -> AddressWithMessage("confirm-registration", userConfiguration.registrationMessage),
      Operation.Recovery     -> AddressWithMessage("recover-account", userConfiguration.recoveryMessage),
      Operation.Deletion     -> AddressWithMessage("delete-account", userConfiguration.deletionMessage)
    )

  private def emailWith(
      userConfiguration: UserConfiguration,
      operation: Operation,
      userIdentifier: UserIdentifier,
      jwt: String
  ): EmailParameters = {
    val addressWithMessage = emailComponents(userConfiguration)(operation)
    val message =
      s"""${userConfiguration.greeting} ${userIdentifier.nickname},
           |
           |${addressWithMessage.message}
           |
           |${userConfiguration.frontend}/#/${addressWithMessage.suffix}/nickname/${userIdentifier.nickname}/email/${userIdentifier.email}/token/$jwt
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
