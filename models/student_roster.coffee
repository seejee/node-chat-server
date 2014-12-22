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
    index   = @students.indexOf(student)
    @students.splice(index, 1)

  length: ->
    @students.length

  queued: ->
    _.chain(@students)
     .filter((s) -> s.status is 'waiting')
     .value()

  chatting: ->
    _.chain(@students)
     .filter((s) -> s.status is 'chatting')
     .value()

  finished: ->
    _.chain(@students)
     .filter((s) -> s.status is 'finished')
     .value()

  next: ->
    @queued()[0]

module.exports = StudentRoster
