local VTerm = require 'vterm'

local vterm = VTerm:init():connect(0)

vterm:redirect(term.native())
vterm:handleEvents()()
vterm:close(true)
