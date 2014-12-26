TeacherRoster = require '../models/teacher_roster'
StudentRoster = require '../models/student_roster'
ChatLog       = require '../models/chat_log'

ChatChannel = require './chat'

class PresenceChannel
  constructor: (@bayeux) ->
    @teachers = new TeacherRoster
    @students = new StudentRoster
    @chatLog  = new ChatLog

  attach: ->
    @bayeux.getClient().subscribe '/presence/teacher/connect',    @onNewTeacher.bind(this)
    @bayeux.getClient().subscribe '/presence/student/connect',    @onNewStudent.bind(this)
    @bayeux.getClient().subscribe '/presence/claim_student',      @onClaimStudent.bind(this)
    @bayeux.getClient().subscribe '/presence/student/disconnect', @onStudentDisconnect.bind(this)

  onNewTeacher: (payload) ->
    console.log "Teacher #{payload.userId} arrived."

    @teachers.add
      id:       payload.userId
      students: []

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
        channel = new ChatChannel @bayeux, @chatLog, @teachers, @students
        channel.attach chat.id

        @publishNewChat chat, teacher, student

  publishNewChat: (chat, teacher, student) ->
    teacherChannel = "/presence/new_chat/teacher/#{teacher.id}"
    studentChannel = "/presence/new_chat/student/#{student.id}"

    @publish teacherChannel,
      sendChannel:      chat.teacherChannels.send
      receiveChannel:   chat.teacherChannels.receive
      terminateChannel: chat.teacherChannels.terminate
      terminatedChannel: chat.teacherChannels.terminated
      joinedChannel:    chat.teacherChannels.joined
      readyChannel:     chat.channels.ready

    @publish studentChannel,
      sendChannel:      chat.studentChannels.send
      receiveChannel:   chat.studentChannels.receive
      terminatedChannel: chat.studentChannels.terminated
      joinedChannel:    chat.studentChannels.joined

  publishStatus: ->
    data =
      teachers:
        total:    @teachers.length()
      students:   @students.stats()
      chats:      @chatLog.stats()

    @publish '/presence/status', data

  publish: (channel, data) ->
    @bayeux.getClient().publish channel, data

module.exports = PresenceChannel
