_     = require 'lodash'
locks = require 'locks'

class StudentRoster
  constructor: ->
    @students = {}
    @rwLock = locks.createReadWriteLock()

  add: (student, callback) ->
    @rwLock.writeLock =>
      @students[student.id] = student
      @io callback, student

  find: (studentId, callback) ->
    @rwLock.writeLock =>
      s = @students[studentId]
      @io callback, s

  remove: (studentId, callback) ->
    @rwLock.writeLock =>
      delete @students[studentId]
      @io callback, studentId

  next: (callback) ->
    @rwLock.writeLock =>
      students = _.values(@students)
      s = _.find(students, (s) -> s.status is 'waiting')
      @io callback, s

  stats: (callback) ->
    @rwLock.readLock =>
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
    process.nextTick =>
      if callback?
        callback null, result
      @rwLock.unlock()

module.exports = StudentRoster
