var TeacherRoster = require('./models/teacher_roster');
var StudentRoster = require('./models/student_roster');
var ChatLog       = require('./models/chat_log');
var ChatLifetime  = require('./models/chat_lifetime');

var PresenceChannel = require('./channels/presence');
var ChatChannel = require('./channels/chat');

var app = require('express.oi')();
app.http().io();

var teachers = new TeacherRoster();
var students = new StudentRoster();
var chatLog  = new ChatLog();
var chatLifetime = new ChatLifetime(teachers, students, chatLog);

new PresenceChannel({
  io: app.io,
  teachers: teachers,
  students: students,
  chatLog:  chatLog,
  chatLifetime: chatLifetime
}).attach();

new ChatChannel({
  io: app.io,
  chatLog:  chatLog,
  chatLifetime: chatLifetime
}).attach();

module.exports = {
  app: app,
};
