_     = require 'lodash'
locks = require 'locks'

class TeacherRoster
  constructor: ->
    @teachers = {}
    @rwLock = locks.createReadWriteLock()

  add: (teacher, callback) ->
    @rwLock.writeLock =>
      @teachers[teacher.id] = teacher
      @io callback, teacher

  find: (id, callback) ->
    @rwLock.writeLock =>
      t = @teachers[id]
      @io callback, t

  stats: (callback) ->
    @rwLock.readLock =>
      length = _.keys(@teachers).length
      @io callback, length

  io: (callback, result) ->
    process.nextTick =>
      if callback?
        callback null, result
      @rwLock.unlock()

module.exports = TeacherRoster
