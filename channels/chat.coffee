_ = require 'lodash'

class ChatChannel
  constructor: (@bayeux, @chatLog, @teachers, @students) ->
    @subs = []

  findChat: ->
    @chatLog.find @id

  attach: (@id) ->
    chat = @findChat()
    @subscribe chat.teacherChannels.send, @onTeacherMessage.bind(this)
    @subscribe chat.studentChannels.send, @onStudentMessage.bind(this)
    @subscribe chat.teacherChannels.terminate, @onTerminateChat.bind(this)
    @subscribe chat.studentChannels.joined, @onStudentJoined.bind(this)
    @subscribe chat.teacherChannels.joined, @onTeacherJoined.bind(this)

  publish: (channel, data) ->
    @bayeux.getClient().publish channel, data

  subscribe: (channel, callback) ->
    @bayeux.getClient().subscribe channel, callback

  onTeacherJoined: (payload) ->
    chat = @findChat()
    chat.teacherEntered = true

    if chat.studentEntered && chat.teacherEntered
      @publish chat.channels.ready, {}

  onStudentJoined: (payload) ->
    chat = @findChat()
    chat.studentEntered = true

    if chat.studentEntered && chat.teacherEntered
      @publish chat.channels.ready, {}

  onTeacherMessage: (payload) ->
    chat = @findChat()
    @chatLog.addTeacherMessage chat, payload.message

    @publish chat.studentChannels.receive, payload

  onStudentMessage: (payload) ->
    chat = @findChat()
    @chatLog.addStudentMessage chat, payload.message

    @publish chat.teacherChannels.receive, payload

  onTerminateChat: (payload) ->
    chat = @findChat()
    teacher = @teachers.find chat.teacherId
    student = @students.find chat.studentId

    @chatLog.finishChat chat, teacher, student

    @publish chat.teacherChannels.terminated, {}
    @publish chat.studentChannels.terminated, {}

module.exports = ChatChannel
