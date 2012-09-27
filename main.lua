
--testing named colors
application:setBackgroundColor("yellow")

local text = TextField.new(nil, "Some text")
text:setTextColor("white")
--positioning
text:setPosition("center", "center")
stage:addChild(text)

local shape = Shape.new()
shape:setFillStyle(Shape.SOLID, "red")
--drawing primitive shape
--shape:drawRect(100, 100)
shape:drawCircle(100, 100, 100)
--positioning
shape:setY("center")
shape:setX("center")
stage:addChild(shape)

--controlling z-index
text:bringToFront()

--touch works also on desktop players
shape:addEventListener(Event.TOUCHES_BEGIN, function(e)
	print("touched at ", e.touch.x, e.touch.y)
end)