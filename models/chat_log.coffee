_    = require 'lodash'
uuid = require 'node-uuid'

class ChatLog
  constructor: ->
    @chats    = {}

  new: (teacherId, studentId, callback) ->
    id   = uuid.v4()

    chat =
      id:        id
      teacherId: teacherId
      studentId: studentId
      status:    'active'
      messages:  []
      channels:
        ready:     "chat:#{id}:ready"
      teacherChannels:
        send:      "chat:teacher:send"
        receive:   "chat:#{id}:teacher:receive"
        joined:    "chat:teacher:joined"
        terminate: "chat:teacher:terminate"
        terminated: "chat:#{id}:teacher:terminated"
      studentChannels:
        send:       "chat:student:send"
        receive:    "chat:#{id}:student:receive"
        joined:     "chat:student:joined"
        terminated: "chat:#{id}:student:terminated"

    @chats[chat.id] = chat

    @io callback, chat

  studentEntered: (chatId, callback) ->
    @find chatId, (err, chat) =>
      chat.studentEntered = true
      @io callback, chat

  teacherEntered: (chatId, callback) ->
    @find chatId, (err, chat) =>
      chat.teacherEntered = true
      @io callback, chat

  addTeacherMessage: (chatId, message, callback) ->
    @find chatId, (err, chat) =>
      chat.messages.push
        sender:  'teacher'
        message: message
        timestamp: Date.now()

      @io callback, chat

  addStudentMessage: (chatId, message, callback) ->
    @find chatId, (err, chat) =>
      chat.messages.push
        sender:  'student'
        message: message
        timestamp: Date.now()

      @io callback, chat

  finishChat: (chatId, callback) ->
    @find chatId, (err, chat) =>
      chat.status = 'finished'
      @io callback, chat

  find: (id, callback) ->
    chat = @chats[id]
    @io callback, chat

  stats: (callback) ->
    chats = _.values(@chats)

    data =
      total:    chats.length
      finished: _.filter(chats, (c) -> c.status is "finished").length

    @io callback, data

  io: (callback, result) ->
    if callback?
      setImmediate ->
        callback null, result

module.exports = ChatLog
