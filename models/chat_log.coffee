_    = require 'lodash'
uuid = require 'node-uuid'

class ChatLog
  constructor: ->
    @chats    = {}

  new: (teacher, student) ->
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

    chat

  addTeacherMessage: (chat, message) ->
    chat.messages.push
      sender:  'teacher'
      message: message
      timestamp: Date.now()

  addStudentMessage: (chat, message) ->
    chat.messages.push
      sender:  'student'
      message: message
      timestamp: Date.now()

  finishChat: (chat, teacher, student) ->
    chat.status       = 'finished'

    student.teacherId = null
    student.status    = 'finished'

    index = teacher.students.indexOf(student.id)
    teacher.students.splice index, 1

  find: (id) ->
    @chats[id]

  stats: ->
    chats = _.values(@chats)

    total:    chats.length
    finished: _.filter(chats, (c) -> c.status is "finsihed").length

module.exports = ChatLog
