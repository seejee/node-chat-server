_     = require 'lodash'
uuid  = require 'node-uuid'
locks = require 'locks'

class ChatLog
  constructor: ->
    @chats    = {}
    @rwLock = locks.createReadWriteLock()

  new: (teacher, student, callback) ->
    @rwLock.writeLock =>
      id   = uuid.v1()

      chat =
        id:        id
        teacherId: teacher.id
        studentId: student.id
        status:    'active'
        messages:  []
        channels:
          ready:     "/chat/#{id}/ready"
        teacherChannels:
          send:      "/chat/#{id}/teacher/send"
          receive:   "/chat/#{id}/teacher/receive"
          joined:    "/chat/#{id}/teacher/joined"
          terminate: "/chat/#{id}/teacher/terminate"
          terminated: "/chat/#{id}/teacher/terminated"
        studentChannels:
          send:    "/chat/#{id}/student/send"
          receive: "/chat/#{id}/student/receive"
          joined:    "/chat/#{id}/student/joined"
          terminated: "/chat/#{id}/student/terminated"

      student.status    = 'chatting'
      student.teacherId = teacher.id

      teacher.students.push student.id

      @chats[chat.id] = chat

      @io callback, chat

  addTeacherMessage: (chat, message, callback) ->
    @rwLock.writeLock =>
      chat.messages.push
        sender:  'teacher'
        message: message
        timestamp: Date.now()

      @io callback, chat

  addStudentMessage: (chat, message, callback) ->
    @rwLock.writeLock =>
      chat.messages.push
        sender:  'student'
        message: message
        timestamp: Date.now()

      @io callback, chat

  finishChat: (chat, teacher, student, callback) ->
    chat.status       = 'finished'

    student.teacherId = null
    student.status    = 'finished'

    index = teacher.students.indexOf(student.id)
    teacher.students.splice index, 1

    callback null, chat

  find: (id, callback) ->
    @rwLock.writeLock =>
      chat = @chats[id]
      @io callback, chat

  stats: (callback) ->
    @rwLock.readLock =>
      chats = _.values(@chats)

      data =
        total:    chats.length
        finished: _.filter(chats, (c) -> c.status is "finsihed").length

      @io callback, data

  io: (callback, result) ->
    process.nextTick =>
      if callback?
        callback null, result
      @rwLock.unlock()

module.exports = ChatLog
