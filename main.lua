
local world = b2.World.new(0, 10, true)

local ball = Bitmap.new("ball.png", true)
	:setPosition("left", "center")

world:createCircle(ball, {type = "dynamic", draggable = true})
	 :createTerrain(nil, {0,0, 
		application:getContentWidth(),0, 
		application:getContentWidth(), application:getContentHeight(), 
		0, application:getContentHeight(), 
	0,0})

ball:setPosition(400, 100)

--we create a layer
local layer = Sprite.new()
--and move it a bit away
layer:setPosition(-100, 0)

layer:addChild(ball)

local upperLayer = Sprite.new()
upperLayer:setPosition(-100, 0)
upperLayer:addChild(layer)
stage:addChild(upperLayer)
	 :addChild(world:getDebug())
	 :addEventListener(Event.ENTER_FRAME, function()
		world:update()
		
	 end)
print(ball:getPosition())
print(layer:localToGlobal(ball:getPosition()))