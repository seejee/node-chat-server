_ = require 'lodash'

class ChatChannel
  constructor: (o) ->
    @io           = o.io
    @chatLog      = o.chatLog
    @chatLifetime = o.chatLifetime

  attach: () ->
    @io.route "chat:teacher:send",      @onTeacherMessage.bind(this)
    @io.route "chat:teacher:joined",    @onTeacherJoined.bind(this)
    @io.route "chat:teacher:terminate", @onTerminateChat.bind(this)
    @io.route "chat:student:send",      @onStudentMessage.bind(this)
    @io.route "chat:student:joined",    @onStudentJoined.bind(this)

  publish: (channel, data) ->
    @io.emit channel, data

  onTeacherJoined: (req) ->
    payload = req.data
    @chatLog.teacherEntered payload.chatId, (err, chat) =>
      if chat.studentEntered && chat.teacherEntered
        @publish chat.channels.ready, {}

  onStudentJoined: (req) ->
    payload = req.data
    @chatLog.studentEntered payload.chatId, (err, chat) =>
      if chat.studentEntered && chat.teacherEntered
        @publish chat.channels.ready, {}

  onTeacherMessage: (req) ->
    payload = req.data
    @chatLog.addTeacherMessage payload.chatId, payload.message, (err, chat) =>
      @publish chat.studentChannels.receive, payload

  onStudentMessage: (req) ->
    payload = req.data
    @chatLog.addStudentMessage payload.chatId, payload.message, (err, chat) =>
      @publish chat.teacherChannels.receive, payload

  onTerminateChat: (req) ->
    payload = req.data
    @chatLifetime.terminateChat payload.chatId, (err, chat) =>
      @publish chat.teacherChannels.terminated, {}
      @publish chat.studentChannels.terminated, {}

module.exports = ChatChannel
