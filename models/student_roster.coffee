_ = require 'lodash'

class StudentRoster
  constructor: ->
    @students = []

  add: (student) ->
    return if _.any @students, (s) -> s.id is student.id
    @students.push student

  length: ->
    @students.length

  queued: ->
    _.chain(@students)
     .filter((s) -> s.teacherId is null)
     .value()

  claimNext: (teacher) ->
    student = @queued()[0]

    if student?
      student.teacherId = teacher.id
      teacher.students.push student.id
      student

module.exports = StudentRoster
