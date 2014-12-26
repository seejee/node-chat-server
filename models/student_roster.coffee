_ = require 'lodash'

class StudentRoster
  constructor: ->
    @students = {}

  add: (student) ->
    @students[student.id] = student

  find: (studentId) ->
    @students[studentId]

  remove: (studentId) ->
    delete @students[studentId]

  length: ->
    _.keys(@students).length

  stats: ->
    students = _.values(@students)

    {
      total:    students.length
      waiting:  @queued(students).length,
      chatting: @chatting(students).length,
      finished: @finished(students).length,
    }

  queued: (students) ->
    _.chain(students)
     .filter((s) -> s.status is 'waiting')
     .value()

  chatting: (students) ->
    _.chain(students)
     .filter((s) -> s.status is 'chatting')
     .value()

  finished: (students) ->
    _.chain(students)
     .filter((s) -> s.status is 'finished')
     .value()

  next: ->
    students = _.values(@students)
    _.find(students, (s) -> s.status is 'waiting')

module.exports = StudentRoster
