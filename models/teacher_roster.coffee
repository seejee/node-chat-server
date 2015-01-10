_ = require 'lodash'

class TeacherRoster
  constructor: ->
    @teachers = {}

  add: (teacher, callback) ->
    @teachers[teacher.id] = teacher
    @io callback, teacher

  find: (id, callback) ->
    t = @teachers[id]
    @io callback, t

  stats: (callback) ->
    data =
      teachers: _.keys(@teachers).length

    @io callback, data

  claimStudent: (teacherId, studentId, callback) ->
    @find teacherId, (err, teacher) =>
      teacher.students.push studentId
      @io callback, teacher

  removeStudent: (teacherId, studentId, callback) ->
    @find teacherId, (err, teacher) =>
      index = teacher.students.indexOf(studentId)
      teacher.students.splice index, 1
      @io callback, teacher

  canAcceptAnotherStudent: (teacherId, callback) ->
    @find teacherId, (err, teacher) =>
      result = teacher.students.length < 5
      @io callback, result

  io: (callback, result) ->
    if callback?
      setImmediate ->
        callback null, result

module.exports = TeacherRoster
