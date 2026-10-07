package utils

import io.scalaland.chimney.Transformer

/** A type that is distinct from its underlying representation, so that identifiers over the same representation cannot
  * be mixed up.
  *
  * On Scala 2 the distinction is a nominal tag, and `Type` remains a subtype of `Underlying`. The Scala 3 version of
  * this class is an `opaque type Type = Underlying`, which makes `Tag` and `Tagged` unnecessary, but leaves every use
  * site unchanged.
  */
abstract class IdType[Underlying] {

  /** Path-dependent, and hence distinct for every object extending this class. */
  sealed trait Tag

  type Type = Underlying with IdType.Tagged[Tag]

  def apply(underlying: Underlying): Type = underlying.asInstanceOf[Type]

  def value(id: Type): Underlying = id

  implicit val fromUnderlying: Transformer[Underlying, Type] = apply

  implicit val toUnderlying: Transformer[Type, Underlying] = value

}

object IdType {

  /** Marker for the tag. Nominal on purpose: implicit search does not reach into structural refinements, and would
    * therefore not find the transformers above.
    */
  trait Tagged[A] extends Any

}
