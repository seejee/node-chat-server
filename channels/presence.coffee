_    = require 'lodash'
uuid = require 'node-uuid'

class TeacherRoster
  constructor: ->
    @teachers = []

  add: (teacher) ->
    return if _.any @teachers, (t) -> t.id is teacher.id
    @teachers.push teacher

  find: (id) ->
    _.find @teachers, (t) -> t.id is id

  length: ->
    @teachers.length

class StudentRoster
  constructor: ->
    @students = []

  add: (student) ->
    return if _.any @students, (s) -> s.id is student.id
    @students.push student

  length: ->
    @students.length

  queued: ->
    _.chain(@students)
     .filter((s) -> s.teacherId is null)
     .value()

  claimNext: (teacher) ->
    student = @queued()[0]

    if student?
      student.teacherId = teacher.id
      teacher.students.push student.id
      student

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

class PresenceChannel
  constructor: (@faye) ->
    @teachers = new TeacherRoster
    @students = new StudentRoster
    @chatLog  = new ChatLog

  attach: ->
    @faye.subscribe '/presence/teacher/connect', @onNewTeacher.bind(this)
    @faye.subscribe '/presence/student/connect', @onNewStudent.bind(this)
    @faye.subscribe '/presence/claim_student',   @onClaimStudent.bind(this)

  onNewTeacher: (payload) ->
    console.log "Teacher #{payload.userId} arrived."

    @teachers.add
      id:       payload.userId
      students: []

    @publishStatus()

  onNewStudent: (payload) ->
    console.log "Student #{payload.userId} arrived."

    @students.add
      id:        payload.userId
      teacherId: null

    @publishStatus()

  onClaimStudent: (payload) ->
    teacher = @teachers.find(payload.teacherId)
    student = @students.claimNext teacher
    chat    = @chatLog.new teacher, student

    if student?
      @publishNewChat chat, teacher, student

  publishNewChat: (chat, teacher, student) ->
    teacherChannel = "/presence/new_chat/teacher/#{teacher.id}"
    studentChannel = "/presence/new_chat/student/#{student.id}"
    chatChannel    = "/chat/#{chat.id}"

    @faye.publish teacherChannel,
      chatChannel: chatChannel

    @faye.publish studentChannel,
      chatChannel: chatChannel

  publishStatus: ->
    @faye.publish '/presence/status',
      teachers:
        total:    @teachers.length()
      students:
        total:    @students.length()
        waiting:  @students.queued().length

module.exports = PresenceChannel
