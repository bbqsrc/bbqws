from __future__ import unicode_literals, print_function
import tornado.websocket
import json
import uuid
import logging
log = logging.getLogger(__name__)


class SessionStore(dict):
    def add(self, socket):
        if self.get(socket) is not None:
            raise Exception("... how did you manage that?")
        self[socket] = uuid.uuid4().hex
        return self[socket]
    
    def remove(self, socket):
        if self.get(socket) is not None:
            del self[socket]
            return True
        return False


class BbqwsSocket(tornado.websocket.WebSocketHandler):
    def __init__(self, application, request, **kwargs):
        tornado.websocket.WebSocketHandler.__init__(self, application, request, **kwargs)
        self.sessions = kwargs.get('session_store') or SessionStore()

    def open(self):
        log.info("New connection")
        # Generate session ID
        self.emit('authentication', {"id": self.sessions.add(self)})
        self.on_connect()

    def emit(self, name, obj=None):
        log.debug("<< '%s'" % json.dumps({name: obj}))
        self.write_message({name: obj})

    def select_subprotocol(self, subprotocols):
        return "bbqws"

    def on_message(self, message):
        log.debug(">> '%s'" % message)
        try:
            parsed = json.loads(message)
        except:
            self.on_error({
                "error": "invalid_json",
                "message": "the JSON was invalid."
            })
            return

        for key in parsed.keys():
            method = getattr(self, "on_%s" % key, None)
            if method is None:
                self.on_error({
                    "error": "key_unfound",
                    "message": "The key '%s' not found." % key
                })
            else:
                method(parsed)

    def on_close(self):
        log.info("Closed connection")
        # remove session from list
        self.sessions.remove(self)
        self.on_disconnect()

    def on_connect(self):
        pass

    def on_disconnect(self):
        pass

    def on_error(self, message):
        self.emit("error", message)


class TestBbqws(BbqwsSocket):
    def on_example(self, message):
        self.emit("test", message)

if __name__ == "__main__":
    import tornado.web
    import tornado.ioloop
    import tornado.options
    application = tornado.web.Application([
        (r"/", TestBbqws),
    ])
    tornado.options.parse_command_line()
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
    
