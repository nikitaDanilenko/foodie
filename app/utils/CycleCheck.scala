package utils

import cats.data.State
import cats.syntax.traverse._

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

    def dfs(v: A, target: A): State[Set[A], Boolean] = {
      for {
        _ <- State.modify[Set[A]](_ + v)
        successors = graph.adjacency.getOrElse(v, Seq.empty).toSet
        result <-
          if (successors.contains(target)) State.pure[Set[A], Boolean](true)
          else
            for {
              visited <- State.get[Set[A]]
              subSearches <-
                (successors -- visited).toList
                  .traverse(dfs(_, target))
            } yield subSearches.exists(identity)
      } yield result
    }

    dfs(vertex, vertex)
      .run(Set.empty[A])
      .value
      ._2
  }

}
