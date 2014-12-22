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
    @faye.subscribe '/presence/teacher/connect',    @onNewTeacher.bind(this)
    @faye.subscribe '/presence/student/connect',    @onNewStudent.bind(this)
    @faye.subscribe '/presence/claim_student',      @onClaimStudent.bind(this)
    @faye.subscribe '/presence/student/disconnect', @onStudentDisconnect.bind(this)

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
      status:    'waiting'
      teacherId: null

    @publishStatus()

  onStudentDisconnect: (payload) ->
    console.log "Student #{payload.userId} left."

    @students.remove payload.userId

    @publishStatus()

  onClaimStudent: (payload) ->
    teacher = @teachers.find(payload.teacherId)

    if teacher.students.length < 5
      student = @students.next()

      if student?
        chat    = @chatLog.new teacher, student
        channel = new ChatChannel @faye, @chatLog, @teachers, @students
        channel.attach chat.id

        @publishNewChat chat, teacher, student

  publishNewChat: (chat, teacher, student) ->
    teacherChannel = "/presence/new_chat/teacher/#{teacher.id}"
    studentChannel = "/presence/new_chat/student/#{student.id}"

    @faye.publish teacherChannel,
      sendChannel:      chat.teacherChannels.send
      receiveChannel:   chat.teacherChannels.receive
      terminateChannel: chat.teacherChannels.terminate
      joinedChannel:    chat.teacherChannels.joined

    @faye.publish studentChannel,
      sendChannel:      chat.studentChannels.send
      receiveChannel:   chat.studentChannels.receive
      terminateChannel: chat.studentChannels.terminate
      joinedChannel:    chat.studentChannels.joined

  publishStatus: ->
    data =
      teachers:
        total:    @teachers.length()
      students:
        total:     @students.length()
        chatting:  @students.chatting().length
        waiting:   @students.queued().length
        finished:  @students.finished().length

    @faye.publish '/presence/status', data

module.exports = PresenceChannel
