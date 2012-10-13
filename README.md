# bbqws

A minimalist websocket wrapper.

## Usage

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
