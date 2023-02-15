-- Set up path for IGL
package.path = package.path .. ';/usr/lib/imevul/peripherals/?.lua'
local VTerm = require 'vterm'

return { VTerm = VTerm }