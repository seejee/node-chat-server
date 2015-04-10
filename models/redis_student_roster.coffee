redis = require('redis')

class RedisStudentRoster
  constructor: ->
    @client      = redis.createClient()
    @key         = 'students'
    @waitingKey  = 'students:waiting'
    @chattingKey = 'students:chatting'
    @finishedKey = 'students:finished'

  add: (student, callback) ->
    @client.rpush @waitingKey, student.id
    @save student, callback

  save: (student, callback) ->
    @client.hset @key, student.id, JSON.stringify(student), (err) ->
      callback(err, student) if callback?

  find: (id, callback) ->
    @client.hget @key, id, (err, json) ->
      callback(err, JSON.parse(json)) if callback?

  remove: (id, callback) ->
    @client.lrem @waitingKey,  1, id
    @client.lrem @chattingKey, 1, id
    @client.lrem @finishedKey, 1, id
    @client.hdel @key, id, (err) ->
      callback(err, id) if callback?

  next: (callback) ->
    @client.lpop @waitingKey, (err, id) =>
      @find id, callback

  assignTo: (studentId, teacherId, callback) =>
    @find studentId, (err, student) =>
      @client.rpush @chattingKey, studentId

      student.status    = 'chatting'
      student.teacherId = teacherId

      @save student, callback

  chatFinished: (studentId, callback) ->
    @find studentId, (err, student) =>
      @client.rpush @finishedKey, studentId

      student.teacherId = null
      student.status    = 'finished'

      @save student, callback

  stats: (callback) ->
    @client.hlen @key, (err, students) =>
      @client.llen @waitingKey, (err, waiting) =>
        @client.llen @chattingKey, (err, chatting) =>
          @client.llen @finishedKey, (err, finished) =>
            data =
              total:    students
              waiting:  waiting
              chatting: chatting
              finished: finished

            callback(err, data) if callback?

module.exports = RedisStudentRoster
