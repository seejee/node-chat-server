_ = require 'lodash'

class StudentRoster
  constructor: ->
    @students = {}

  add: (student, callback) ->
    @students[student.id] = student
    @io callback, student

  find: (studentId, callback) ->
    s = @students[studentId]
    @io callback, s

  remove: (studentId, callback) ->
    delete @students[studentId]
    @io callback, studentId

  next: (callback) ->
    students = _.values(@students)
    s = _.find(students, (s) -> s.status is 'waiting')
    @io callback, s

  assignTo: (studentId, teacherId, callback) ->
    @find studentId, (err, student) =>
      student.status    = 'chatting'
      student.teacherId = teacherId
      @io callback, student

  chatFinished: (studentId, callback) ->
    @find studentId, (err, student) =>
      student.teacherId = null
      student.status    = 'finished'
      @io callback, student

  stats: (callback) ->
    students = _.values(@students)

    data =
      total:    students.length
      waiting:  @_queued(students).length,
      chatting: @_chatting(students).length,
      finished: @_finished(students).length,

    @io callback, data

  _queued: (students) ->
    _.chain(students)
     .filter((s) -> s.status is 'waiting')
     .value()

  _chatting: (students) ->
    _.chain(students)
     .filter((s) -> s.status is 'chatting')
     .value()

  _finished: (students) ->
    _.chain(students)
     .filter((s) -> s.status is 'finished')
     .value()

  io: (callback, result) ->
    if callback?
      setImmediate ->
        callback null, result

module.exports = StudentRoster
