
--some initial settings
application:setBackgroundColor("yellow")
			:setOrientation("portrait")
			:setLogicalDimensions(320, 480)
			:setScaleMode("letterbox")
			:setFps(60)
			:setKeepAwake(true)

local text = TextField.new(nil, "Some text")
	--positioning
	:setPosition("center", "center")
	--named colors
	:setTextColor("white")

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
	
local bitmap = Bitmap.new("crate.png", true)
	:setPosition("center", "top")

stage:addChild(text)
	 :addChild(shape)
	 :addChild(bitmap)

--controlling z-index
text:bringToFront()
