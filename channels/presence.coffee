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
    @faye.subscribe '/presence/connect', (data) =>
      if data.role is 'teacher'
        console.log "Teacher #{data.userId} arrived."
        @teachers.add data.userId
      else
        console.log "Student #{data.userId} arrived."
        @studentQueue.enqueue data.userId

      @faye.publish '/presence/status',
        teachers: @teachers.length()
        students: @studentQueue.length()

module.exports = PresenceChannel
