TeacherRoster = require '../models/teacher_roster'
StudentRoster = require '../models/student_roster'
ChatLog       = require '../models/chat_log'
ChatLifetime  = require '../models/chat_lifetime'

ChatChannel = require './chat'

class PresenceChannel
  constructor: (@faye) ->
    @teachers = new TeacherRoster
    @students = new StudentRoster
    @chatLog  = new ChatLog
    @chatLifetime = new ChatLifetime @teachers, @students, @chatLog

  attach: ->
    client = @faye.getClient()
    client.subscribe '/presence/teacher/connect',    @onNewTeacher.bind(this)
    client.subscribe '/presence/student/connect',    @onNewStudent.bind(this)
    client.subscribe '/presence/claim_student',      @onClaimStudent.bind(this)
    client.subscribe '/presence/student/disconnect', @onStudentDisconnect.bind(this)

  onNewTeacher: (payload) ->
    console.log "Teacher #{payload.userId} arrived."

    @teachers.add
      id:       payload.userId
      students: []

  onNewStudent: (payload) ->
    console.log "Student #{payload.userId} arrived."

    student =
      id:        payload.userId
      status:    'waiting'
      teacherId: null

    @students.add student, (err) =>
      @publishStatus()

  onStudentDisconnect: (payload) ->
    console.log "Student #{payload.userId} left."

    @students.remove payload.userId, (err) =>
      @publishStatus()

  onClaimStudent: (payload) ->
    @chatLifetime.createChatForNextStudent payload.teacherId, (err, chat) =>
      if chat
        channel = new ChatChannel @faye, @chatLog, @chatLifetime
        channel.attach chat.id

        @publishNewChat chat

  publishNewChat: (chat) ->
    teacherChannel = "/presence/new_chat/teacher/#{chat.teacherId}"
    studentChannel = "/presence/new_chat/student/#{chat.studentId}"

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
    @teachers.stats (err, teacherCount) =>
      @students.stats (err, studentStats) =>
        @chatLog.stats (err, chatStats) =>
          data =
            teachers:
              total:    teacherCount
            students:   studentStats
            chats:      chatStats

          @publish '/presence/status', data

  publish: (channel, data) ->
    @faye.getClient().publish channel, data

module.exports = PresenceChannel
