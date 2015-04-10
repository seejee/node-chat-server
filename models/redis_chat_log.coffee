redis = require 'redis'
uuid  = require 'node-uuid'

TIMEOUT = 1000

class RedisChatLog
  constructor: (@mutex) ->
    @client      = redis.createClient()
    @key         = 'chats'
    @finishedKey = 'chats:finished'

  add: (chat, callback) ->
    @save chat, callback

  save: (chat, callback) ->
    @client.hset @key, chat.id, JSON.stringify(chat), (err) ->
      callback(err, chat) if callback?

  find: (id, callback) ->
    @client.hget @key, id, (err, json) ->
      callback(err, JSON.parse(json)) if callback?

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

    @save chat, callback

  studentEntered: (chatId, callback) ->
    @mutex.lock chatId, TIMEOUT, (err, lock) =>
      @find chatId, (err, chat) =>
        chat.studentEntered = true
        @save chat, (err, chat) =>
          callback(err, chat)
          @mutex.unlock chatId, lock.value

  teacherEntered: (chatId, callback) ->
    @mutex.lock chatId, TIMEOUT, (err, lock) =>
      @find chatId, (err, chat) =>
        chat.teacherEntered = true
        @save chat, (err, chat) =>
          callback(err, chat)
          @mutex.unlock chatId, lock.value

  addTeacherMessage: (chatId, message, callback) ->
    @mutex.lock chatId, TIMEOUT, (err, lock) =>
      @find chatId, (err, chat) =>
        chat.messages.push
          sender:  'teacher'
          message: message
          timestamp: Date.now()

        @save chat, (err, chat) =>
          callback(err, chat)
          @mutex.unlock chatId, lock.value

  addStudentMessage: (chatId, message, callback) ->
    @mutex.lock chatId, TIMEOUT, (err, lock) =>
      @find chatId, (err, chat) =>
        chat.messages.push
          sender:  'student'
          message: message
          timestamp: Date.now()

        @save chat, (err, chat) =>
          callback(err, chat)
          @mutex.unlock chatId, lock.value

  finishChat: (chatId, callback) ->
    @mutex.lock chatId, TIMEOUT, (err, lock) =>
      @find chatId, (err, chat) =>
        @client.rpush @finishedKey, chatId

        chat.status = 'finished'

        @save chat, (err, chat) =>
          callback(err, chat)
          @mutex.unlock chatId, lock.value

  stats: (callback) ->
    @client.hlen @key, (err, chats) =>
      @client.llen @finishedKey, (err, finished) =>
        data =
          total:    chats
          finished: finished

        callback(err, data) if callback?

module.exports = RedisChatLog
