local class = require 'lib.classy'

local VTerm = class('VTerm')
VTerm.ALLOWED_EVENTS = {
	'char',
	'key',
	'key_up',
	'monitor_resize',
	'monitor_touch',
	'mouse_click',
	'mouse_drag',
	'mouse_scroll',
	'mouse_up',
	'paste',
	'term_resize',
}

function VTerm:__init(modem, passthrough)
	self.protocol = 'vterm'
	self.hostname = os.getComputerLabel() or tostring(os.getComputerID())
	self.server = nil
	self.isServer = true
	self.isOnline = false

	self._native = term.native and term.native() or term
	self._redirectTarget = passthrough or term.current and term.current() or self._native
	self._modem = modem
	self._isRunning = false

	self:_setup()
end

function VTerm:host()
	self.isServer = true
	self.server = nil

	if self.serverId == nil then
		rednet.host(self.protocol, self.hostname)
	end

	self.isOnline = true

	return self
end

function VTerm:connect(serverId)
	self.isServer = false
	self.server = serverId
	self.isOnline = true

	return self
end

function VTerm:close(closeModem)
	self.isOnline = false
	self.server = nil

	if self.isServer then
		rednet.unhost(self.protocol)
	end

	if self == term.current() then
		term.redirect(self._redirectTarget)
	end

	if closeModem then
		rednet.close(modem)
	end

	return self
end

function VTerm:_setup()
	for k, v in pairs(self._native) do
		if type(k) == 'string' and type(v) == 'function' and rawget(self, k) == nil then
			self[k] = function(...)
				self:_rpc(k, { ... })
				return self._redirectTarget[k](...)
			end
		end
	end

	if not rednet.isOpen(self.modem) then
		if self._modem then
			rednet.open(self._modem)
		else
			peripheral.find('modem', rednet.open)
		end
	end
end

function VTerm:_rpc(name, params)
	if not self.isOnline then
		return
	end

	local payload = {
		type = 'term',
		data = {
			name = name,
			params = params or {}
		}
	}

	if self.isServer then
		rednet.broadcast(payload, self.protocol)
	else
		if self.server ~= nil then
			rednet.send(self.server, payload, self.protocol)
		else
			error('VTerm not connected to a server!', 2)
		end
	end
end

function VTerm:forwardEvent(eventData, filter)
	if not self.isOnline then
		return
	end

	if self.isServer then
		filter = { 'term_resize', 'monitor_resize' }
	else
		filter = filter or VTerm.ALLOWED_EVENTS
	end

	local event = eventData[1]

	local found = false
	for _, allowedType in ipairs(filter) do
		if event == allowedType then
			found = true
			break
		end
	end

	if not found then
		return
	end

	local payload = {
		type = 'event',
		data = eventData
	}

	if self.isServer then
		rednet.broadcast(payload, self.protocol)
	else
		if self.server ~= nil then
			rednet.send(self.server, payload, self.protocol)
		else
			error('VTerm not connected to a server!', 2)
		end
	end
end

function VTerm:redirect(target)
	local oldRedirectTarget = self._redirectTarget

	-- Abuse term.redirect to populate methods
	self._redirectTarget = term.redirect(term.redirect(target))

	return oldRedirectTarget
end

function VTerm:handleEvent(eventData)
	if not self.isOnline then
		return
	end

	local event, sender, message, protocol = table.unpack(eventData)

	if event == 'rednet_message' then
		if protocol == self.protocol and type(message) == 'table' then
			if message.type == 'term' and sender == self.server then
				self[message.data.name](table.unpack(message.data.params or {}))
			elseif message.type == 'event' then
				os.queueEvent(table.unpack(message.data))
			end
		end
	end
end

function VTerm:current()
	return self._redirectTarget
end

function VTerm:native()
	return self._native
end

function VTerm:handleEvents()
	self._isRunning = true
	return function()
		while self._isRunning do
			local eventData = { os.pullEvent() }
			self:handleEvent(eventData)

			self:forwardEvent(eventData)
		end
	end
end

return VTerm
