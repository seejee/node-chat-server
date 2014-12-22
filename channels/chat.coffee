class ChatChannel
  constructor: (@faye, @chatLog) ->

  findChat: ->
    @chatLog.find @id

  attach: (@id) ->
    chat = @findChat()
    @faye.subscribe chat.teacherChannels.send, @onTeacherMessage.bind(this)
    @faye.subscribe chat.studentChannels.send, @onStudentMessage.bind(this)
    @faye.subscribe chat.teacherChannels.terminate, @onTerminateChat.bind(this)

  onTeacherMessage: (payload) ->
    chat = @findChat()
    @chatLog.addTeacherMessage chat, payload.message

    @faye.publish chat.studentChannels.receive, payload

  onStudentMessage: (payload) ->
    chat = @findChat()
    @chatLog.addStudentMessage chat, payload.message

    @faye.publish chat.teacherChannels.receive, payload

  onTerminateChat: (payload) ->
    chat = @findChat()
    @chatLog.finishChat chat

    @faye.publish chat.studentChannels.terminate, {}

module.exports = ChatChannel
