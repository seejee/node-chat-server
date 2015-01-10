locks = require "locks"

class ChatLifetime
  constructor: (@teachers, @students, @chatLog) ->
    @mutex = locks.createMutex()

  createChatForNextStudent: (teacherId, callback) ->
    @mutex.lock =>
      @teachers.canAcceptAnotherStudent teacherId, (err, canAccept) =>
        if canAccept
          @students.next (err, student) =>
            if student?
              @students.assignTo student.id, teacherId, =>
                @teachers.claimStudent teacherId, student.id, =>
                  @chatLog.new teacherId, student.id, (err, chat) =>
                    callback null, chat
                    @mutex.unlock()
            else
              callback null, null
              @mutex.unlock()
        else
          callback null, null
          @mutex.unlock()


  terminateChat: (chatId, callback) ->
    @mutex.lock =>
      @chatLog.finishChat chatId, (err, chat) =>
        @students.chatFinished chat.studentId, (err) =>
          @teachers.removeStudent chat.teacherId, chat.studentId, (err) =>
            callback null, chat
            @mutex.unlock()

module.exports = ChatLifetime
