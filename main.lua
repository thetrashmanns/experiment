
function love.load()
	require("pdf")
	bint = require('bint')(256)
	loveframes = require("ui.loveframes")
	PDF417 = dofile("pdf417.lua")
end

function love.update(dt)
	loveframes.update(dt)
end

function love.draw()
	loveframes.draw()
end

function love.keypressed(key, scancode, isrepeat)
	loveframes.keypressed(scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	loveframes.keyreleased(scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
	loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end
