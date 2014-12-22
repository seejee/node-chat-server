_ = require 'lodash'

class TeacherRoster
  constructor: ->
    @teachers = []

  add: (teacher) ->
    return if _.any @teachers, (t) -> t.id is teacher.id
    @teachers.push teacher

  find: (id) ->
    _.find @teachers, (t) -> t.id is id

  length: ->
    @teachers.length

module.exports = TeacherRoster
