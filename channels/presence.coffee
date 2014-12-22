TeacherRoster = require '../models/teacher_roster'
StudentRoster = require '../models/student_roster'
ChatLog       = require '../models/chat_log'

ChatChannel = require './chat'

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
    chat    = @chatLog.new teacher.id, student.id

    if student?
      channel = new ChatChannel @faye, @chatLog
      channel.attach chat.id

      #TODO: clean up channel when it's done

      @publishNewChat chat, teacher, student

  publishNewChat: (chat, teacher, student) ->
    teacherChannel = "/presence/new_chat/teacher/#{teacher.id}"
    studentChannel = "/presence/new_chat/student/#{student.id}"

    @faye.publish teacherChannel,
      sendChannel:    chat.teacherChannels.send
      receiveChannel: chat.teacherChannels.receive

    @faye.publish studentChannel,
      sendChannel:    chat.studentChannels.send
      receiveChannel: chat.studentChannels.receive

  publishStatus: ->
    @faye.publish '/presence/status',
      teachers:
        total:    @teachers.length()
      students:
        total:    @students.length()
        waiting:  @students.queued().length

module.exports = PresenceChannel
