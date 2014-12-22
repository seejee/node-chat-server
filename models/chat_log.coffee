uuid = require 'node-uuid'

class ChatLog
  constructor: ->
    @chats = {}

  new: (teacherId, studentId) ->
    chat =
      id:        uuid.v4()
      teacherId: teacherId
      studentId: studentId
      messages:  []

    @chats[chat.id] = chat

    chat

  find: (id) ->
    @chats[id]

module.exports = ChatLog
