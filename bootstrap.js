var TeacherRoster = require('./models/redis_teacher_roster');
var StudentRoster = require('./models/redis_student_roster');
var ChatLog       = require('./models/redis_chat_log');
var ChatLifetime  = require('./models/chat_lifetime');

var PresenceChannel = require('./channels/presence');
var ChatChannel = require('./channels/chat');

var Redlock = require('multiredlock');
var redis   = require('redis');
redis.createClient().flushdb()

var redlock = new Redlock([{host:'localhost', port:6379}]);
redlock.setRetry(10, 100);

var express = require('express.oi')();
var app     = express.http().io();

var socketioRedis = require('socket.io-redis');
app.io.adapter(socketioRedis({ host: 'localhost', port: 6379 }));

var teachers = new TeacherRoster();
var students = new StudentRoster();
var chatLog  = new ChatLog(redlock);
var chatLifetime = new ChatLifetime(teachers, students, chatLog, redlock);

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
