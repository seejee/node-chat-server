_ = require 'lodash'

class ChatChannel
  constructor: (@bayeux, @chatLog, @teachers, @students) ->
    @subs = []

  findChat: (callback) ->
    @chatLog.find @id, callback

  attach: (@id) ->
    @findChat (err, chat) =>
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
    @findChat (err, chat) =>
      chat.teacherEntered = true

      if chat.studentEntered && chat.teacherEntered
        @publish chat.channels.ready, {}

  onStudentJoined: (payload) ->
    @findChat (err, chat) =>
      chat.studentEntered = true

      if chat.studentEntered && chat.teacherEntered
        @publish chat.channels.ready, {}

  onTeacherMessage: (payload) ->
    @findChat (err, chat) =>
      @chatLog.addTeacherMessage chat, payload.message
      @publish chat.studentChannels.receive, payload

  onStudentMessage: (payload) ->
    @findChat (err, chat) =>
      @chatLog.addStudentMessage chat, payload.message
      @publish chat.teacherChannels.receive, payload

  onTerminateChat: (payload) ->
    @findChat (err, chat) =>
      @teachers.find chat.teacherId, (err, teacher) =>
        @students.find chat.studentId, (err, student) =>
          @chatLog.finishChat chat, teacher, student, (err, chat) =>
            @publish chat.teacherChannels.terminated, {}
            @publish chat.studentChannels.terminated, {}

module.exports = ChatChannel
