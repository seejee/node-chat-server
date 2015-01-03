class ChatLifetime
  constructor: (@teachers, @students, @chatLog) ->

  createChatForNextStudent: (teacherId, callback) ->
    @teachers.canAcceptAnotherStudent teacherId, (err, canAccept) =>
      if canAccept
        @students.next (err, student) =>
          if student?
            @students.assignTo student.id, teacherId, =>
              @teachers.claimStudent teacherId, student.id, =>
                @chatLog.new teacherId, student.id, (err, chat) =>
                  callback null, chat

  terminateChat: (chat, callback) ->
    @students.chatFinished chat.studentId, (err) =>
      @teachers.removeStudent chat.teacherId, chat.studentId, (err) =>
        @chatLog.finishChat chat, (err, chat) =>
          callback null, chat

module.exports = ChatLifetime
