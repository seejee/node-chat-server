_    = require 'lodash'
uuid = require 'node-uuid'

class ChatLog
  constructor: ->
    @chats    = {}

  new: (teacher, student, callback) ->
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
    chat.messages.push
      sender:  'teacher'
      message: message
      timestamp: Date.now()

    @io callback, chat

  addStudentMessage: (chat, message, callback) ->
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

    @io callback, chat

  find: (id, callback) ->
    chat = @chats[id]
    @io callback, chat

  stats: (callback) ->
    chats = _.values(@chats)

    data =
      total:    chats.length
      finished: _.filter(chats, (c) -> c.status is "finsihed").length

    @io callback, data

  io: (callback, result) ->
    if callback?
      callback null, result

    null

module.exports = ChatLog
