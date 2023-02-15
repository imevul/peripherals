local currentDir = '/' .. fs.getDir(table.pack(...)[2]) or ""
package.path = package.path .. ';' .. currentDir .. '/?.lua'
local VTerm = require 'vterm'

return { VTerm = VTerm }