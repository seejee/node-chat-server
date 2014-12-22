_ = require 'lodash'

class ChatChannel
  constructor: (@faye, @chatLog, @teachers, @students) ->
    @subs = []

  findChat: ->
    @chatLog.find @id

  attach: (@id) ->
    chat = @findChat()
    @faye.subscribe chat.teacherChannels.send, @onTeacherMessage.bind(this)
    @faye.subscribe chat.studentChannels.send, @onStudentMessage.bind(this)
    @faye.subscribe chat.teacherChannels.terminate, @onTerminateChat.bind(this)
    @faye.subscribe chat.studentChannels.joined, @onStudentJoined.bind(this)

  detach: (chat) ->
    @faye.unsubscribe chat.teacherChannels.send
    @faye.unsubscribe chat.studentChannels.send
    @faye.unsubscribe chat.teacherChannels.terminate
    @faye.unsubscribe chat.studentChannels.joined

  onStudentJoined: (payload) ->
    chat = @findChat()
    @faye.publish chat.teacherChannels.joined, payload

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
    teacher = @teachers.find chat.teacherId
    student = @students.find chat.studentId

    @chatLog.finishChat chat, teacher, student
    @detach(chat)

    @faye.publish chat.studentChannels.terminate, {}

module.exports = ChatChannel
