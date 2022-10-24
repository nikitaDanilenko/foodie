package utils

object CycleCheck {

  case class Graph[A](
      adjacency: Map[A, Seq[A]]
  )

  case class Arc[A](from: A, to: A)

  def fromArcs[A](arrows: Seq[Arc[A]]): Graph[A] =
    Graph(
      arrows
        .groupBy(_.from)
        .view
        .mapValues(_.map(_.to))
        .toMap
    )

  def onCycle[A](vertex: A, graph: Graph[A]): Boolean = {
    case class Step(
        layer: Set[A],
        visited: Set[A]
    )
    def mkStep(step: Step): Step =
      Step(
        layer = step.layer.flatMap(graph.adjacency.get).flatten,
        visited = step.visited ++ step.layer
      )
    Iterator
      .iterate(Step(Set(vertex), Set.empty))(mkStep)
      .slice(1, graph.adjacency.size)
      .exists(_.layer.contains(vertex))
  }

}
