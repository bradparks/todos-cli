module.exports = (tour) ->

  tour.color('cyan')

  tour.prepare (cb) ->
    cb()

  tour.step 1
    .begin 'Foo!'
    .expect 'command', (data, cb) ->
      cb(data.command is 'pwd')
    .reject 'bar'
    .wait '125'
    .end 'Baz!'

  tour.end 'Qux!'

  return tour
