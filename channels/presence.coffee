_ = require 'lodash'

class TeacherRoster
  constructor: ->
    @teachers = []

  add: (teacher) ->
    return if _.any @teachers, (t) -> t.id is teacher.id
    @teachers.push teacher

  length: ->
    @teachers.length

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

class PresenceChannel
  constructor: (@faye) ->
    @teachers = new TeacherRoster
    @students = new StudentRoster

  attach: ->
    @faye.subscribe '/presence/connect/teacher', @onNewTeacher.bind(this)
    @faye.subscribe '/presence/connect/student', @onNewStudent.bind(this)
    @faye.subscribe '/presence/claimStudent',    @onClaimStudent.bind(this)

  onNewTeacher: (payload) ->
    console.log "Teacher #{payload.userId} arrived."

    @teachers.add
      id:       payload.userId
      students: []

    @publishStatus()

  onNewStudent: (payload) ->
    console.log "Student #{payload.userId} arrived."

    @students.add
      id:        payload.userId
      teacherId: null

    @publishStatus()

  onClaimStudent: (payload) ->

  publishStatus: ->
    @faye.publish '/presence/status',
      teachers:
        total:    @teachers.length()
      students:
        total:    @students.length()
        waiting:  @students.queued().length

module.exports = PresenceChannel
