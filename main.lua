
function love.load()
	love.window.setMode(1366, 768)
	require("pdf")
	bint = require('bint')(256)
	loveframes = require("ui.loveframes")
	dofile("utils.lua")
	require("pdf417")
	UI = dofile("ui_load.lua")
	UI:init()
end

function love.update(dt)
    loveframes.update(dt)
end
                 
function love.draw()
    loveframes.draw()
end
 
function love.mousepressed(x, y, button)
    loveframes.mousepressed(x, y, button)
end
 
function love.mousereleased(x, y, button)
    loveframes.mousereleased(x, y, button)
end
 
function love.keypressed(key, scancode, isrepeat)
    loveframes.keypressed(key, isrepeat)
end
 
function love.keyreleased(key)
    loveframes.keyreleased(key)
end

function love.textinput(text)
    loveframes.textinput(text)
end
