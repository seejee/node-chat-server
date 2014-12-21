class TeacherRoster
  constructor: ->
    @teachers = []

  add: (teacher) ->
    return if @teachers.indexOf(teacher) != -1
    @teachers.push teacher

  length: ->
    @teachers.length

class StudentQueue
  constructor: ->
    @students = []

  enqueue: (student) ->
    return if @students.indexOf(student) != -1
    @students.push student

  length: ->
    @students.length

class PresenceChannel
  constructor: (@faye) ->
    @teachers     = new TeacherRoster
    @studentQueue = new StudentQueue

  attach: ->
    @faye.subscribe '/presence/connect', @handleNewUser.bind(this)

  handleNewUser: (payload) ->
    if payload.role is 'teacher'
      console.log "Teacher #{payload.userId} arrived."
      @teachers.add payload.userId
    else
      console.log "Student #{payload.userId} arrived."
      @studentQueue.enqueue payload.userId

    @publishStatus()

  publishStatus: ->
    @faye.publish '/presence/status',
      teachers: @teachers.length()
      students: @studentQueue.length()

module.exports = PresenceChannel
