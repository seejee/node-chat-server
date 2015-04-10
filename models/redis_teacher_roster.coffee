redis = require('redis')

class RedisTeacherRoster
  constructor: ->
    @client = redis.createClient()
    @key    = 'teachers'

  add: (teacher, callback) ->
    @save teacher, callback

  save: (teacher, callback) ->
    @client.hset @key, teacher.id, JSON.stringify(teacher), (err) ->
      callback(err, teacher) if callback?

  find: (id, callback) ->
    @client.hget @key, id, (err, json) ->
      callback(err, JSON.parse(json)) if callback?

  stats: (callback) ->
    @client.hlen @key, (err, count) ->
      data =
        teachers: count

      callback(err, data) if callback?

  claimStudent: (teacherId, studentId, callback) ->
    @find teacherId, (err, teacher) =>
      teacher.students.push studentId

      @save teacher, (err) ->
        callback(err, teacher) if callback?

  removeStudent: (teacherId, studentId, callback) ->
    @find teacherId, (err, teacher) =>
      index = teacher.students.indexOf(studentId)
      teacher.students.splice index, 1

      @save teacher, (err) ->
        callback(err, teacher) if callback?

  canAcceptAnotherStudent: (teacherId, callback) ->
    @find teacherId, (err, teacher) =>
      result = teacher.students.length < 5
      callback(err, result) if callback?

module.exports = RedisTeacherRoster
