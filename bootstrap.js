var TeacherRoster = require('./models/teacher_roster');
var StudentRoster = require('./models/student_roster');
var ChatLog       = require('./models/chat_log');
var ChatLifetime  = require('./models/chat_lifetime');

var PresenceChannel = require('./channels/presence');
var ChatChannel = require('./channels/chat');

var redis   = require('redis');
redis.createClient().flushdb()

var express = require('express.oi')();
var app     = express.http().io();

var socketioRedis = require('socket.io-redis');
app.io.adapter(socketioRedis({ host: 'localhost', port: 6379 }));

var teachers = new TeacherRoster();
var students = new StudentRoster();
var chatLog  = new ChatLog();
var chatLifetime = new ChatLifetime(teachers, students, chatLog);

new PresenceChannel({
  io: express.io,
  teachers: teachers,
  students: students,
  chatLog:  chatLog,
  chatLifetime: chatLifetime
}).attach();

new ChatChannel({
  io: express.io,
  chatLog:  chatLog,
  chatLifetime: chatLifetime
}).attach();

module.exports = app;
