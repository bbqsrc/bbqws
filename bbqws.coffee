class bbqws
	_emitBuffer = []

	websocket: null
	session: null
	
	events:
		authentication: [(data) -> (@session ||= {}).id = data.id]
		connect: []
		disconnect: []

	on: (name, method) ->
		@events[name] ||= []
		@events[name].push(method)
		return method

	off: (name) ->
		delete @events[name]

	emit: (name, obj) ->
		o = {}
		o[name] = obj or null
		
		if @websocket?.readyState != 1
			_emitBuffer.push(JSON.stringify(o))
			return true
		else
			@websocket.send(JSON.stringify(o))
	
	connect: ->
		@websocket = new WebSocket(@url, "bbqws")
		
		@websocket.onmessage = (event) =>
			console.log(event) if @_debug
			try
				data = JSON.parse(event.data)
			catch e
				throw new Error("Invalid (unparseable) data received.")

			for key of data
				continue unless @events[key]
				func.call(this, data[key]) for func in @events[key]
			return

		@websocket.onclose = (event) =>
			# TODO: handle case where server connection dies unexpectedly
			console.log(event, @websocket.readyState) if @_debug
			func.call(this, event) for func in @events.disconnect if @events.disconnect?
			delete @session
			return
		
		@websocket.onopen = (event) =>
			console.log(event, @websocket.readyState) if @_debug
			func.call(this, event) for func in @events.connect if @events.connect?
			if _emitBuffer.length > 0
				@websocket.send(item) for item in _emitBuffer
				_emitBuffer.length = 0
			return
		
		return @
	
	disconnect: ->
		if @websocket.readyState is 1
			@websocket.close()
		else if @websocket.readyState isnt 2 # Chrome race condition
			throw new Error("websocket is not connected (readyState: #{@websocket.readyState})")
		return @
		
	subscribe: (channel) ->
		@websocket.send(JSON.stringify({subscribe: channel}))
		return

	unsubscribe: (channel) ->
		@websocket.send(JSON.stringify({unsubscribe: channel}))
		return

	constructor: (host, isSecure) ->
		if not /^(ws:\/\/|wss:\/\/)/.test(host)
			host = (if isSecure then "wss://" else "ws://") + host
		@url = host
	
	_debug: false

(exports ? this).bbqws = bbqws
