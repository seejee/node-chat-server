class PresenceChannel
  constructor: (o) ->
    @io           = o.io
    @teachers     = o.teachers
    @students     = o.students
    @chatLog      = o.chatLog
    @chatLifetime = o.chatLifetime

  attach: (callback) ->
    @io.route 'presence',
      'teacher:connect':    @onNewTeacher.bind(this)
      'student:connect':    @onNewStudent.bind(this)
      'claim_student':      @onClaimStudent.bind(this)
      'student:disconnect': @onStudentDisconnect.bind(this)

  onNewTeacher: (req) ->
    payload = req.data
    console.log "Teacher #{payload.userId} arrived."

    @teachers.add
      id:       payload.userId
      students: []

  onNewStudent: (req) ->
    payload = req.data
    console.log "Student #{payload.userId} arrived."

    student =
      id:        payload.userId
      status:    'waiting'
      teacherId: null

    @students.add student, (err) =>
      @publishStatus()

  onStudentDisconnect: (req) ->
    payload = req.data
    console.log "Student #{payload.userId} left."

    @students.remove payload.userId, (err) =>
      @publishStatus()

  onClaimStudent: (req) ->
    payload = req.data
    @chatLifetime.createChatForNextStudent payload.teacherId, (err, chat) =>
      @publishNewChat chat if chat

  publishNewChat: (chat) ->
    teacherChannel = "presence:new_chat:teacher:#{chat.teacherId}"
    studentChannel = "presence:new_chat:student:#{chat.studentId}"

    @publish teacherChannel,
      id:                chat.id
      sendChannel:       chat.teacherChannels.send
      receiveChannel:    chat.teacherChannels.receive
      terminateChannel:  chat.teacherChannels.terminate
      terminatedChannel: chat.teacherChannels.terminated
      joinedChannel:     chat.teacherChannels.joined
      readyChannel:      chat.channels.ready

    @publish studentChannel,
      id:                chat.id
      sendChannel:       chat.studentChannels.send
      receiveChannel:    chat.studentChannels.receive
      terminatedChannel: chat.studentChannels.terminated
      joinedChannel:     chat.studentChannels.joined

  publishStatus: ->
    @teachers.stats (err, teacherCount) =>
      @students.stats (err, studentStats) =>
        @chatLog.stats (err, chatStats) =>
          data =
            teachers:
              total:    teacherCount
            students:   studentStats
            chats:      chatStats

          @publish 'presence:status', data

  publish: (channel, data) ->
    @io.emit channel, data

module.exports = PresenceChannel
