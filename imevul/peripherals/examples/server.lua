local VTerm = require 'vterm'

local vterm = VTerm:init():host()
term.redirect(vterm)

function main()
	local i = 0
	local sendTimer = os.startTimer(0.5)

	while true do
		local eventData = { os.pullEvent() }
		local event, id = table.unpack(eventData)
		if event == 'timer' and id == sendTimer then
			print(tostring(i) .. ': ' .. textutils.formatTime(os.time('local'), true))
			i = i + 1
			sendTimer = os.startTimer(0.5)
		elseif event == 'key' then
			print('Key "' .. id .. '" was pressed')
		end
	end
end

parallel.waitForAny(main, vterm:handleEvents())
vterm:close(true)