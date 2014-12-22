_ = require 'lodash'

class StudentRoster
  constructor: ->
    @students = []

  add: (student) ->
    return if _.any @students, (s) -> s.id is student.id
    @students.push student

  find: (studentId) ->
    _.find @students, (s) -> s.id is studentId

  remove: (studentId) ->
    student = @find studentId
    index   = @students.indexOf(studentId)
    @students.splice(index, 1)

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
