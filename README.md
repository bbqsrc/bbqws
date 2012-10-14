# bbqws

A minimalist websocket wrapper.

## Client usage

### CoffeeScript

```coffeescript
ws = new bbqws("localhost:8888")

ws.on "connect", ->
	console.log "Connected!"

ws.on "example", (data) ->
	# Do something with response

ws.connect()

ws.emit "example", data: "all kinds of data"
ws.emit "example", [1, 2, 3]
ws.emit "example", true
ws.emit "example"
```

### JavaScript

```javascript
var ws = new bbqws("localhost:8888");

ws.on("connect", function() {
	console.log("Connected!");
});

ws.on("example", function(data) {
	// Do something with response
});

ws.connect();

ws.emit("example", {data: "all kinds of data"});
ws.emit("example", [1, 2, 3]);
ws.emit("example", true);
ws.emit("example");
```

## Server usage

This is a very basic implementation, implemented using Tornado's WebSocket handler.

```python
import tornado.web
import tornado.ioloop
import tornado.options

from bbqws import BbqwsSocket

class ExampleHandler(BbqwsSocket):
    on_example(self, message):
	    self.emit("response", {"msg": "hurray!"})

application = tornado.web.Application([
    (r"/", ExampleHandler),
])

tornado.options.parse_command_line()
application.listen(8888)
tornado.ioloop.IOLoop.instance().start()
```
