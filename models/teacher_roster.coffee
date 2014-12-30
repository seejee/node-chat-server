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
    length = _.keys(@teachers).length
    @io callback, length

  io: (callback, result) ->
    if callback?
      callback null, result

    null

module.exports = TeacherRoster
