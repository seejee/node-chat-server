_ = require 'lodash'

class ChatChannel
  constructor: (@faye, @chatLog, @chatLifetime) ->
    @subs = []

  attach: (@id) ->
    @chatLog.find @id, (err, chat) =>
      @subscribe chat.teacherChannels.send, @onTeacherMessage.bind(this)
      @subscribe chat.studentChannels.send, @onStudentMessage.bind(this)
      @subscribe chat.teacherChannels.terminate, @onTerminateChat.bind(this)
      @subscribe chat.studentChannels.joined, @onStudentJoined.bind(this)
      @subscribe chat.teacherChannels.joined, @onTeacherJoined.bind(this)

  publish: (channel, data) ->
    @faye.getClient().publish channel, data

  subscribe: (channel, callback) ->
    @faye.getClient().subscribe channel, callback

  onTeacherJoined: (payload) ->
    @chatLog.teacherEntered @id, (err, chat) =>
      if chat.studentEntered && chat.teacherEntered
        @publish chat.channels.ready, {}

  onStudentJoined: (payload) ->
    @chatLog.studentEntered @id, (err, chat) =>
      if chat.studentEntered && chat.teacherEntered
        @publish chat.channels.ready, {}

  onTeacherMessage: (payload) ->
    @chatLog.addTeacherMessage @id, payload.message, (err, chat) =>
      @publish chat.studentChannels.receive, payload

  onStudentMessage: (payload) ->
    @chatLog.addStudentMessage @id, payload.message, (err, chat) =>
      @publish chat.teacherChannels.receive, payload

  onTerminateChat: (payload) ->
    @chatLifetime.terminateChat @id, (err, chat) =>
      @publish chat.teacherChannels.terminated, {}
      @publish chat.studentChannels.terminated, {}

module.exports = ChatChannel
