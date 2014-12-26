_ = require 'lodash'

class TeacherRoster
  constructor: ->
    @teachers = {}

  add: (teacher) ->
    @teachers[teacher.id] = teacher

  find: (id) ->
    @teachers[id]

  length: ->
    _.keys(@teachers).length

module.exports = TeacherRoster
