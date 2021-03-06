package models

import javax.inject.Inject
import services.Db

object Robots {

  private def createData(user: Users.Data, name: String): Data = {
    Data(name = name, user_id = user.id)
  }

  case class Data(name: String,
                  code: String = "",
                  id: Long = -1,
                  user_id: Long,
                  bio: Option[String] = None,
                  rating: Int = 1000,
                  openSource: Boolean = true,
                  automatch: Boolean = false)

  class Repo @Inject()(val db: Db, val usersRepo: Users.Repo) {

    import db.ctx._

    val schema: db.ctx.Quoted[db.ctx.EntityQuery[Data]] = quote(
      querySchema[Data]("robots"))

    def find(user: Users.Data, robot: String): Option[Data] =
      run(schema.filter(r =>
        r.user_id == lift(user.id) && r.name == lift(robot))).headOption

    def findAllForUser(user: Users.Data): List[Data] =
      run(schema.filter(_.user_id == lift(user.id)))

    def findAll(): List[(Data, Users.Data)] = {
      val userSchema = usersRepo.schema.asInstanceOf[Quoted[EntityQuery[Users.Data]]]
      run(schema.join(userSchema).on(_.user_id == _.id))
    }

    def create(user: Users.Data, name: String): Data = {
      val data = createData(user, name)
      data.copy(id = run(schema.insert(lift(data)).returningGenerated(_.id)))
    }

    def update(robot: Data, code: String): Result[RunActionResult] = {
      run(schema.filter(_.id == lift(robot.id)).update(_.code -> lift(code)))
    }
  }
}
