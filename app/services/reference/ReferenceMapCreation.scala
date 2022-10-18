package services.reference

import services.ReferenceMapId

case class ReferenceMapCreation(
    name: String
)

object ReferenceMapCreation {

  def create(id: ReferenceMapId, referenceMapCreation: ReferenceMapCreation): ReferenceMap =
    ReferenceMap(
      id = id,
      name = referenceMapCreation.name
    )

}
