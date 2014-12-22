uuid = require 'node-uuid'

class ChatLog
  constructor: ->
    @chats    = {}

  new: (teacherId, studentId) ->
    id   = uuid.v4()

    chat =
      id:        id
      teacherId: teacherId
      studentId: studentId
      messages:  []
      teacherChannels:
        send:    "/chat/#{id}/teacher/send"
        receive: "/chat/#{id}/teacher/receive"
      studentChannels:
        send:    "/chat/#{id}/student/send"
        receive: "/chat/#{id}/student/receive"

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

  find: (id) ->
    @chats[id]

module.exports = ChatLog
