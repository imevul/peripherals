local VTerm = require 'vterm'

local vterm = VTerm():connect(0)

vterm:redirect(term.native())
vterm:handleEvents()()
