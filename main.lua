require "box2d"

--some initial settings
application:setBackgroundColor("yellow")
			:setFps(60)
			:setKeepAwake(true)
			:enableFiltering()

local font = TTFont.new("tahoma.ttf", 70)
local text = TextField.new(font, "Some text")
	--positioning
	--:setPosition("center", "center")
	:setPosition(250,250)
	--named colors
	:setTextColor("white")
	:setAnchorPoint(0.5, 0.5)
	:setRotation(45)
	:setShadow(3, 3, "gray")
	
local test = Shape.new()
	:setFillStyle(Shape.SOLID, "white", 0.5)
	:drawRoundRectangle(90, 90, 10)
	:setPosition(100, 100)
	:setAnchorPoint(0.5)
	:setRotation(45)

--[[local bitmap = Bitmap.new("crate.png")
	:setPosition("center","top")
	:setAnchorPoint(0.5)]]
	
local bitmap = Shape.new()
	:setFillStyle(Shape.SOLID, "red")
	:drawRectangle(100,100)
	:setAnchorPoint(0.5)
	:setAbsolutePosition("right", "bottom")
	--:setPosition("center","bottom")

local shape = Shape.new()
	--named colors
	:setFillStyle(Shape.SOLID, "red")
	--drawing primitive shape
	--:drawRect(100, 100)
	:drawCircle(100, 100, 100)
	--positioning
	:setY("center")
	:setX("center")
	--touch works also on desktop players
	:addEventListener(Event.TOUCHES_BEGIN, function(e)
		--recursive print for table
		print_r(e.touch)
	end)

-- box2d examples
local world = b2.World.new(0, 10, true)

--place image on screen
local crate = Bitmap.new("crate.png", true)
	:setPosition("center", "center")

--create rectangle based on image
world:createRectangle(crate, {type = "dynamic"})

--world:createRoundRectangle(test, 90, 90, 10, {type = "dynamic", draggable = true})
--[[world:createTerrain(test, {
	0,0,90,0,90,90,0,90,0,0
}, {type = "dynamic", draggable = true})]]

--place image on screen
local ball = Bitmap.new("ball.png", true)
	:setPosition("left", "center")

--create circle based on image
world:createCircle(ball, {type = "dynamic", draggable = true})

--we can move physical object by moving our sprite
ball:setPosition(400, 100)

--local collisions
world:addBeginContact(ball, crate, function()
	print("contact started")
end)
	:addEndContact(ball, crate, function()
	print("contact ended")
end)

--create terrain so objects won't fall of the screen
world:createTerrain(nil, {0,0, 
	application:getContentWidth(),0, 
	application:getContentWidth(), application:getContentHeight(), 
	0, application:getContentHeight(), 
	0,0})

stage:addChild(text)
	 :addChild(shape)
	 :addChild(bitmap)
	 :addChild(test)
	 :addChild(crate)
	 :addChild(ball)
	 --debugging world
	 :addChild(world:getDebug())
	 --updating world
	 :addEventListener(Event.ENTER_FRAME, function()
		world:update()
	 end)

--controlling z-index
text:bringToFront()

GTween.new(text, 2, {rotation=360})

