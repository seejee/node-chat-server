_ = require 'lodash'
Q = require 'q'

class ChatChannel
  constructor: (@faye, @chatLog, @chatLifetime) ->
    @subs = []

  attach: (@id, callback) ->
    @chatLog.find @id, (err, chat) =>
      subs = [
        @subscribe(chat.teacherChannels.send, @onTeacherMessage.bind(this))
        @subscribe(chat.studentChannels.send, @onStudentMessage.bind(this))
        @subscribe(chat.teacherChannels.terminate, @onTerminateChat.bind(this))
        @subscribe(chat.studentChannels.joined, @onStudentJoined.bind(this))
        @subscribe(chat.teacherChannels.joined, @onTeacherJoined.bind(this))
      ]

      Q.all(subs).done(callback)

  publish: (channel, data) ->
    @faye.publish channel, data

  subscribe: (channel, callback) ->
    @faye.subscribe channel, callback

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
