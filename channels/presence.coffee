TeacherRoster = require '../models/teacher_roster'
StudentRoster = require '../models/student_roster'
ChatLog       = require '../models/chat_log'

class PresenceChannel
  constructor: (@faye) ->
    @teachers = new TeacherRoster
    @students = new StudentRoster
    @chatLog  = new ChatLog

  attach: ->
    @faye.subscribe '/presence/teacher/connect', @onNewTeacher.bind(this)
    @faye.subscribe '/presence/student/connect', @onNewStudent.bind(this)
    @faye.subscribe '/presence/claim_student',   @onClaimStudent.bind(this)

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
    teacher = @teachers.find(payload.teacherId)
    student = @students.claimNext teacher
    chat    = @chatLog.new teacher, student

    if student?
      @publishNewChat chat, teacher, student

  publishNewChat: (chat, teacher, student) ->
    teacherChannel = "/presence/new_chat/teacher/#{teacher.id}"
    studentChannel = "/presence/new_chat/student/#{student.id}"
    chatChannel    = "/chat/#{chat.id}"

    @faye.publish teacherChannel,
      chatChannel: chatChannel

    @faye.publish studentChannel,
      chatChannel: chatChannel

  publishStatus: ->
    @faye.publish '/presence/status',
      teachers:
        total:    @teachers.length()
      students:
        total:    @students.length()
        waiting:  @students.queued().length

module.exports = PresenceChannel
