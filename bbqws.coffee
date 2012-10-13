class bbqws
	websocket: null
	
	events:
		"connect": []
		"disconnect": []

	on: (name, method) ->
		@events[name] ||= []
		@events[name].push(method)
		return method

	off: (name) ->
		delete @events[name]

	emit: (name, obj) ->
		o = {}
		o[name] = obj or null
		
		if @websocket.readyState != 1
			@_emitBuffer ||= []
			@_emitBuffer.push(JSON.stringify(o))
			return true
		else
			@websocket.send(JSON.stringify(o))
	
	connect: ->
		@websocket = new WebSocket(@url)
		
		@websocket.onopen = (event) =>
			func.call(this, event) for func in @events.connect if @events.connect?
			if @_emitBuffer and @_emitBuffer.length > 0
				@websocket.send(item) for item in @_emitBuffer
				delete @_emitBuffer
			return
		
		@websocket.onclose = (event) =>
			func.call(this, event) for func in @events.disconnect if @events.disconnect?
			return
		
		@websocket.onmessage = (event) =>
			console.log(event)
			try
				data = JSON.parse(event.data)
			catch e
				throw new Error("Invalid (unparseable) data received.")

			for key of data
				continue unless @events[key]
				func.call(this, data[key]) for func in @events[key]
			return

		return @
	
	disconnect: ->
		if @websocket.readyState is 1
			@websocket.close()
		else
			throw new Error("websocket is not connected")
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

(exports ? this).bbqws = bbqws
