package controllers.home

import play.api.mvc.{ AbstractController, Action, AnyContent, ControllerComponents }

import javax.inject.Inject

class HomeController @Inject() (cc: ControllerComponents) extends AbstractController(cc) {

  def home: Action[AnyContent] =
    Action {
      Ok("Foodie is running")
    }

}
