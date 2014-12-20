class PresenceChannel
  constructor: (@faye) ->

  attach: ->
    @faye.subscribe '/presence/connect', (payload) =>
      console.log JSON.stringify(payload, null, 2)

      @faye.publish '/presence/status',
        connected: true

module.exports = PresenceChannel
