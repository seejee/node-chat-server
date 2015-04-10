TIMEOUT = 1000

class ChatLifetime
  constructor: (@teachers, @students, @chatLog, @mutex) ->

  createChatForNextStudent: (teacherId, callback) ->
    @mutex 'lock:chat:queue', (done) =>
      @teachers.canAcceptAnotherStudent teacherId, (err, canAccept) =>
        if canAccept
          @students.next (err, student) =>
            if student?
              @students.assignTo student.id, teacherId, =>
                @teachers.claimStudent teacherId, student.id, =>
                  @chatLog.new teacherId, student.id, (err, chat) =>
                    console.log "Assigned student #{student.id} to teacher #{teacherId}..."
                    done()
                    callback null, chat
            else
              done()
              callback null, null
        else
          done()
          callback null, null


  terminateChat: (chatId, callback) ->
    @mutex 'lock:chat:finish', (done) =>
      @chatLog.finishChat chatId, (err, chat) =>
        @students.chatFinished chat.studentId, (err) =>
          @teachers.removeStudent chat.teacherId, chat.studentId, (err) =>
            done()
            callback null, chat

module.exports = ChatLifetime
