--[[
	INTERNAL HELPING FUNCTIONS
]]--

--function for adding methods
local function addMethod(object, funcName, func)
	object[funcName] = func
end

--function for overriding methods
local function overRideMethod(object, func, index, callback)
	if object ~= nil and object[func] ~= nil and object["__OV"..func] == nil then
		object["__OV"..func] = object[func]
		object[func] = function(...)
			if arg[index] then
				arg[index] = callback(arg[index])
			end
			return object["__OV"..func](unpack(arg))
		end
	end
end

--for chaining all setters
function changeAllSetFunctions(class)
	local newMethods = {}
	for k,v in pairs(class) do
		if type(v) == "function" and (k:sub(1, 3) == "set" or k:sub(1, 3) == "add" or k:sub(1, 6) == "remove" or k:sub(1, 5) == "clear") then
			newMethods["_CH"..k] = v
			newMethods[k] = function(self, ...)
				class["_CH"..k](self, ...)
				return self
			end
		end
	end
	for k,v in pairs(newMethods) do
		class[k] = v
	end
end

local function getAbsolutes()
	local ltx = application:getLogicalTranslateX()
	local lty = application:getLogicalTranslateY()
	local lsx = application:getLogicalScaleX()
	local lsy = application:getLogicalScaleY()
	local dw = application:getDeviceWidth()
	local dh = application:getDeviceHeight()
	local orientation = application:getOrientation()
	
	if orientation == Application.LANDSCAPE_LEFT or orientation == Application.LANDSCAPE_RIGHT then
		dw,dh = dh,dw
	end
	
	-- top left
	local startx = -ltx / lsx
	local starty = -lty / lsy

	-- bottom right
	local endx = (dw - ltx) / lsx
	local endy = (dh - lty) / lsy
	
	return startx, starty, endx, endy
end

--[[
	GLOBAL ADDITIONAL FUNCTIONS
]]--

--recursive print of tables
function print_r (t, indent, done)
  done = done or {}
  indent = indent or ''
  local nextIndent -- Storage for next indentation value
  for key, value in pairs (t) do
    if type (value) == "table" and not done [value] then
      nextIndent = nextIndent or
          (indent .. string.rep(' ',string.len(tostring (key))+2))
          -- Shortcut conditional allocation
      done [value] = true
      print (indent .. "[" .. tostring (key) .. "] => Table {");
      print  (nextIndent .. "{");
      print_r (value, nextIndent .. string.rep(' ',2), done)
      print  (nextIndent .. "}");
    else
      print  (indent .. "[" .. tostring (key) .. "] => " .. tostring (value).."")
    end
  end
end

function math.round(num, factor) 
	if factor then
		-- Round a number to the nearest factor
		return factor*math.round(num/factor)
	else
		-- Round a number to the nearest integer
		return math.floor(num+.5)
	end
end

--[[
	EVENTDISPATCHER EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(EventDispatcher)

EventDispatcher.__dispatchEvent =  EventDispatcher.dispatchEvent
function EventDispatcher:dispatchEvent(...)
	self:__dispatchEvent(...)
	return self
end

--[[
	SPRITE EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(Sprite)

--[[ anchor points ]]--

function Sprite:_testAnchor()
	if not self._anchorX then
		self._anchorX = 0
		self._anchorY = 0
		self._offX = 0
		self._offY = 0
	end
end

function Sprite:getAnchorPoint()
	self:_testAnchor()
	return self._anchorX, self._anchorY
end

function Sprite:setAnchorPoint(x, y)
	self:_testAnchor()
	y = y or x
	self._anchorX = x
	self._anchorY = y
	
	local angle = self:getRotation()
	self:_setRotation(0)
	local curX = self:get("x")
	local curY = self:get("y")
	
	self._offX = -self:getWidth() * self._anchorX
	self._offY = -self:getHeight() * self._anchorY
	
	self:_setRotation(angle)
	
	local cosine = math.cos(math.rad(angle))
	local sine = math.sin(math.rad(angle))
	
	local dx = -self._offX - (-self._offX * cosine + self._offY * sine)
	local dy = -self._offY - (-self._offY * cosine - self._offX * sine)
	
	self._offX = self._offX + dx
	self._offY = self._offY + dy
	
	local newX = curX + self._offX
	local newY = curY + self._offY
	
	--baseline fix
	if self._baseX then
		newX = newX - self._baseX
	end
	if self._baseY then
		newY = newY - self._baseY
	end
	
	self:_set("x", newX)
	self:_set("y", newY)
	
	return self
end

Sprite._setRotation = Sprite.setRotation

function Sprite:setRotation(angle)

	self:_setRotation(angle)
	
	self:setAnchorPoint(self:getAnchorPoint())
	
	return self
end

Sprite._get = Sprite.get

function Sprite:get(param)
	self:_testAnchor()
	if param == "x" then
		local x = self:_get("x")
		--baseline fix
		if self._baseX then
			x = x - self._baseX
		end
		return x - self._offX
	elseif param == "y" then
		local y = self:_get("y")
		--baseline fix
		if self._baseY then
			y = y + self._baseY
		end
		return y - self._offY
	else
		return self:_get(param)
	end
end

function Sprite:getX()
	return self:get("x")
end

function Sprite:getY()
	return self:get("y")
end

function Sprite:getPosition()
	return self:get("x"), self:get("y")
end

--[[ absolute positioning ]]--

function Sprite:_loadAbsolute()
	if not self.startx then
		-- top left bottom right
		self.startx ,self.starty, self.endx, self.endy = getAbsolutes()
	end
end

function Sprite:setAbsoluteX(x)
	self:_loadAbsolute()
	if type(x) == "string" then
		return self:set("x", x.."Absolute")
	else
		return self:set("x", x+self.startx)
	end
end

function Sprite:setAbsoluteY(y)
	self:_loadAbsolute()
	if type(y) == "string" then
		return self:set("y", y.."Absolute")
	else
		return self:set("y", y+self.starty)
	end
end

function Sprite:setAbsolutePosition(x, y)
	return self:setAbsoluteX(x)
			   :setAbsoluteY(y)
end

--[[ z-axis manipulations ]]--

function Sprite:bringToFront()
	local parent = self:getParent()
	if parent then
		parent:addChild(self)
	end
	return self
end
 
function Sprite:sendToBack()
	local parent = self:getParent()
	if parent then
		parent:addChildAt(self, 0)
	end
	return self
end
 
function Sprite:setIndex(index)
	local parent = self:getParent()
	if parent then
		if index<parent:getChildIndex(self) then
			index=index-1
		end
		parent:addChildAt(self, index)
	end
	return self
end

--[[ simple collision detection ]]--

function Sprite:collidesWith(sprite2)
	local x,y,w,h = self:getBounds(stage)
	local x2,y2,w2,h2 = sprite2:getBounds(stage)

	return not ((y+h < y2) or (y > y2+h2) or (x > x2+w2) or (x+w < x2))
end

--[[ messing with set method ]]--

Sprite._set = Sprite.set

function Sprite:set(param, value)
	self:_testAnchor()
	self:_loadAbsolute()
	if Sprite.transform[param] then
		local matrix = self:getMatrix()
		matrix[param](matrix, value)
		self:setMatrix(matrix)
	else
		if param == "x" then
			if type(value) == "string" then
				local _, _, width, height = self:getBounds(stage)
				local ax, ay = self:getAnchorPoint()
				local xPosition = {
					left = ax*width,
					center = application:getContentWidth()/2 - width/2 + ax*width,
					right = application:getContentWidth() - ax*width,
					leftAbsolute = ax*width+self.startx,
					centerAbsolute = application:getContentWidth()/2 - width/2 + ax*width,
					rightAbsolute = (self.endx - ax*width)
				}
				value = xPosition[value]
				if not value then
					error("Invalid position name")
				end
			end
			--baseline fix
			if self._baseX then
				value = value - self._baseX
			end
			if self._offX then
				value = value + self._offX
			end
		elseif param == "y" then
			if type(value) == "string" then
				local _, _, width, height = self:getBounds(stage)
				local ax, ay = self:getAnchorPoint()
				local yPosition = {
					top = ay*height,
					center = application:getContentHeight()/2 - height/2 + ay*height,
					bottom = application:getContentHeight() - ay*height,
					topAbsolute = ay*height+self.starty,
					centerAbsolute = application:getContentHeight()/2 - height/2 + ay*height,
					bottomAbsolute = (self.endy - ay*height)
				}
				value = yPosition[value]
				if not value then
					error("Invalid position name")
				end
			end
			--baseline fix
			if self._baseY then
				value = value - self._baseY
			end
			if self._offY then
				value = value + self._offY
			end
		end
		Sprite._set(self, param, value)
	end
	return self
end

function Sprite:setX(x)
	return self:set("x", x)
end

function Sprite:setY(y)
	return self:set("y", y)
end

function Sprite:setPosition(x, y)
	return self:set("x", x)
			   :set("y", y)
end

function Sprite:ignoreTouchHandler(event)
	-- Simple handler to ignore touches on a sprite. This blocks touches
	-- from other objects below it.
	if self:hitTestPoint(event.touch.x, event.touch.y) then
		event:stopPropagation()
	end
	return self
end

function Sprite:ignoreMouseHandler(event)
	-- Simple handler to ignore mouse events on a sprite. This blocks mouse events
	-- from other objects below it.
	if self:hitTestPoint(event.x, event.y) then
		event:stopPropagation()
	end
	return self
end

function Sprite:ignoreTouches(event)
	-- Tell a sprite to ignore (and block) all mouse and touch events
	return self:addEventListener(Event.MOUSE_DOWN, self.ignoreMouseHandler, self)
			   :addEventListener(Event.TOUCHES_BEGIN, self.ignoreTouchHandler, self)
end

function Sprite:setWidth(newWidth)
	-- Set a sprite's width using the scale property
	local x,y,width,height=self:getBounds(self)
	local newScale=newWidth/width
	return self:setScaleX(newScale)
end
 
function Sprite:setHeight(newHeight)
	-- Set a sprite's height using the scale property
	local x,y,width,height=self:getBounds(self)
	local newScale=newHeight/height
	return self:setScaleY(newScale)
end

--[[ skew transformation ]]--

Sprite.transform = {
	"skew",
	"skewX",
	"skewY"
}
function Sprite:setSkew(xAng, yAng)
	return self	:set("skewX", xAng)
				:set("skewY", yAng)
end

function Sprite:setSkewX(xAng)
	return self:set("skewX", xAng)
end

function Sprite:setSkewY(yAng)
	return self:set("skewY", yAng)
end

--[[ flipping ]]--

function Sprite:flipHorizontal()
	return self:setScaleX(-self:getScaleX())
end

function Sprite:flipVertical()
	return self:setScaleY(-self:getScaleY())
end

--[[ hiding/showing visually and from touch/mouse events ]]--

function Sprite:hide()
	if not self.isHidden then
		self.xScale, self.yScale = self:getScale()
		self:setScale(0)
		self.isHidden = true
	end
	return self
end

function Sprite:isHidden()
	return self.isHidden
end

function Sprite:show()
	if self.isHidden then
		self:setScale(self.xScale, self.yScale)
	end
	return self
end

--[[
	TEXTUREREGION EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(TextureRegion)

--[[
	TEXTUREPACK EXTENSIONS
]]--

--[[ shorthand ]]--

TexturePack._new = TexturePack.new

function TexturePack.new(...)
	
	local pack
	if type(arg[1] == "string") then
		pack = TexturePack._new(arg[1]..".txt", arg[1]..".png")
	else
		pack = TexturePack._new(...)
	end

	return pack
end

--[[
	BITMAP EXTENSIONS
]]--

--[[ shorthand for creating bitmaps ]]--

Bitmap._new = Bitmap.new

function Bitmap.new(...)
	
	if type(arg[1] == "string") then
		arg[1] = Texture.new(unpack(arg))
	end
	
	local bitmap = Bitmap._new(arg[1])
	bitmap.texture = arg[1]
	return bitmap
end

Bitmap._setAnchorPoint = Bitmap.setAnchorPoint

function Bitmap:setAnchorPoint(x, y)
	y = y or x
	return self:_setAnchorPoint(x,y)
end

--[[ chaining ]]--

changeAllSetFunctions(Bitmap)

--[[
	TEXTFIELD EXTENSIONS
]]--

--[[ baseline fix ]]--

TextField._BLnew = TextField.new

function TextField.new(...)
	local text = TextField._BLnew(...)
	
	text._baseX, text._baseY = text:getBounds(stage)
	
	return text
end

--[[ chaining ]]--

changeAllSetFunctions(TextField)

--[[
	SHAPE EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(Shape)

Shape.__beginPath =  Shape.beginPath
function Shape:beginPath(...)
	self:__beginPath(...)
	return self
end

Shape.__moveTo =  Shape.moveTo
function Shape:moveTo(...)
	self:__moveTo(...)
	return self
end

Shape.__lineTo =  Shape.lineTo
function Shape:lineTo(...)
	self:__lineTo(...)
	return self
end

Shape.__endPath =  Shape.endPath
function Shape:endPath(...)
	self:__endPath(...)
	return self
end

Shape.__closePath =  Shape.closePath
function Shape:closePath(...)
	self:__closePath(...)
	return self
end

--[[ draw a polygon from a list of vertices ]]--

function Shape:drawPoly(points)
	self:beginPath()
	for i,p in ipairs(points) do
              self:lineTo(p[1], p[2])
	end
	self:closePath()
	self:endPath()
	return self
end

--[[ draw rectangle ]]--

function Shape:drawRectangle(width, height)
	return self:drawPoly({
		{0, 0},
		{width, 0},
		{width, height},
		{0, height}
	})
end

--[[ arcs and curves ]]--

local function bezier3(p1,p2,p3,mu)
   local mum1,mum12,mu2
   local p = {}
   mu2 = mu * mu
   mum1 = 1 - mu
   mum12 = mum1 * mum1
   p.x = p1.x * mum12 + 2 * p2.x * mum1 * mu + p3.x * mu2
   p.y = p1.y * mum12 + 2 * p2.y * mum1 * mu + p3.y * mu2
   return p
end

local function bezier4(p1,p2,p3,p4,mu)
   local mum1,mum13,mu3;
   local p = {}
   mum1 = 1 - mu
   mum13 = mum1 * mum1 * mum1
   mu3 = mu * mu * mu
   p.x = mum13*p1.x + 3*mu*mum1*mum1*p2.x + 3*mu*mu*mum1*p3.x + mu3*p4.x
   p.y = mum13*p1.y + 3*mu*mum1*mum1*p2.y + 3*mu*mu*mum1*p3.y + mu3*p4.y
   return p     
end

local function quadraticCurve(startx, starty, cpx, cpy, x, y, mu)
	local inc = mu or 0.1 -- need a better default
	local t = {}
	for i = 0,1,inc do
		local p = bezier3(
			{ x=startx, y=starty },
			{ x=cpx, y=cpy },
			{ x=x, y=y },
		i)
		t[#t+1] = p.x
		t[#t+1] = p.y
	end
	return t
end

Shape._new = Shape.new

function Shape.new()
	local shape = Shape._new()
	shape._lastPoint = nil
	shape._allPoints = {}
	return shape
end

Shape._moveTo = Shape.moveTo

function Shape:moveTo(x,y)
	self:_moveTo(x, y)
	self._lastPoint = { x, y }
	self._allPoints[#self._allPoints] = x
	self._allPoints[#self._allPoints] = y
	return self
end

Shape._lineTo = Shape.lineTo

function Shape:lineTo(x,y)
	self:_lineTo(x, y)
	self._lastPoint = { x, y }
	self._allPoints[#self._allPoints] = x
	self._allPoints[#self._allPoints] = y
	return self
end

Shape._clear = Shape.clear

function Shape:clear()
	Shape._clear()
	self._allPoints = {}
	return self
end

function Shape:getPoints()
	return self._allPoints
end

function Shape:quadraticCurveTo(cpx, cpy, x, y, mu)
	if self._lastPoint then
		local points = quadraticCurve(self._lastPoint[1], self._lastPoint[2], cpx, cpy, x, y, mu)
		for i = 1, #points, 2 do
			self:_lineTo(points[i],points[i+1])
		end
	end
	self._lastPoint = { x, y }
	return self
end

function Shape:bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y, mu)
	if self._lastPoint then
		local inc = mu or 0.1 -- need a better default
		for i = 0,1,inc do  
			local p = bezier4(
				{ x=self._lastPoint[1], y=self._lastPoint[2] },
				{ x=cp1x, y=cp1y },
				{ x=cp2x, y=cp2y },
				{ x=x, y=y },
			i)
			self:_lineTo(p.x,p.y)
		end
	end
	self._lastPoint = { x, y }
end

function Shape:drawRoundRectangle(width, height, radius)
	self:beginPath()
	self:moveTo(0, radius)
		:lineTo(0, height - radius)
		:quadraticCurveTo(0, height, 
			radius, height)
		:lineTo(width - radius, height)
		:quadraticCurveTo(width, height, 
			width, height - radius)
		:lineTo(width, radius)
		:quadraticCurveTo(width, 0, 
			width - radius, 0)
		:lineTo(radius, 0)
		:quadraticCurveTo(0, 0, 
			0, radius)
	self:closePath()
	self:endPath()
	return self
end

--[[ draw elipse from ndoss ]]--

function Shape:drawEllipse(x,y,xradius,yradius,startAngle,endAngle,anticlockwise)
	local sides = (xradius + yradius) / 2  -- need a better default
	local dist  = 0

	-- handle missing entries
	if startAngle == nil then startAngle = 0 end
	if endAngle   == nil then endAngle   = 2*math.pi end

	-- Find clockwise distance (convert negative distances to positive)
	dist = endAngle - startAngle
	if (dist < 0) then
		dist = 2*math.pi - ((-dist) % (2*math.pi))
	end

	-- handle clockwise/anticlockwise
	if anticlockwise == nil or anticlockwise == false then
		-- CW
		-- Handle special case where mod of the two angles is equal but
		-- they're really not equal 
		if dist == 0 and startAngle ~= endAngle then
			dist = 2*math.pi
		end
	else
		-- CCW
		dist = dist - 2*math.pi

		-- Handle special case where mod of the two angles is equal but
		-- they're really not equal 
		if dist == 0 and startAngle ~= endAngle then
			dist = -2*math.pi
		end

	end
	self:beginPath()
	-- add the lines
	for i=0,sides do
		local angle = (i/sides) *  dist + startAngle
		self:lineTo(x + math.cos(angle) * xradius,
                         y + math.sin(angle) * yradius)
	end
	self:closePath()
	self:endPath()
	return self
end

--[[ draw arc from ndoss ]]--
function Shape:drawArc(centerX, centerY, radius, startAngle, endAngle, anticlockwise)
	return self:drawEllipse(centerX, centerY, radius, radius, startAngle ,endAngle, anticlockwise)
end

--[[ draw circle from ndoss ]]--

function Shape:drawCircle(centerX, centerY, radius, anticlockwise)
	return self:drawEllipse(centerX, centerY, radius, radius, 0, 2*math.pi, anticlockwise)
end

--[[
	TILEMAP EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(TileMap)

TileMap.__shift =  TileMap.shift
function TileMap:shift(...)
	self:__shift(...)
	return self
end

--[[
	MOVIECLIP EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(MovieClip)

MovieClip.__play =  MovieClip.play
function MovieClip:play(...)
	self:__play(...)
	return self
end

MovieClip.__stop =  MovieClip.stop
function MovieClip:stop(...)
	self:__stop(...)
	return self
end

MovieClip.__gotoAndPlay =  MovieClip.gotoAndPlay
function MovieClip:gotoAndPlay(...)
	self:__gotoAndPlay(...)
	return self
end

MovieClip.__gotoAndStop =  MovieClip.gotoAndStop
function MovieClip:gotoAndStop(...)
	self:__gotoAndStop(...)
	return self
end

--[[
	APPLICATION EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(Application)

Application.__openUrl =  Application.openUrl
function Application:openUrl(...)
	self:__openUrl(...)
	return self
end

Application.__vibrate =  Application.vibrate
function Application:vibrate(...)
	self:__vibrate(...)
	return self
end

--[[ fix if loical dimensions are not set ]]--

Application.__getContentWidth =  Application.getContentWidth
function Application:getContentWidth()
	local size = self:__getContentWidth()
	if size == 0 then
		local orientation = application:getOrientation()
		if orientation == Application.LANDSCAPE_LEFT or orientation == Application.LANDSCAPE_RIGHT then
			size = application:getDeviceHeight()
		else
			size = application:getDeviceWidth()
		end
	end
	return size
end

Application.__getContentHeight =  Application.getContentHeight
function Application:getContentHeight()
	local size = self:__getContentHeight()
	if size == 0 then
		local orientation = application:getOrientation()
		if orientation == Application.LANDSCAPE_LEFT or orientation == Application.LANDSCAPE_RIGHT then
			size = application:getDeviceWidth()
		else
			size = application:getDeviceHeight()
		end
	end
	return size
end

--[[ absolute positioning ]]--

function Application:_loadAbsolute()
	if not self.startx then
		-- top left bottom right
		self.startx ,self.starty, self.endx, self.endy = getAbsolutes()
	end
end

function Application:getAbsoluteWidth()
	self:_loadAbsolute()
	return self.endx - self.startx
end

function Application:getAbsoluteHeight()
	self:_loadAbsolute()
	return self.endy - self.starty
end

function Application:setVolume(volume)
	self.currentVolume = volume
	for i = 1, #self.sounds do
		self.sounds[i]:setVolume(volume)
	end
end

function Application:getVolume()
	if self.currentVolume then
		return self.currentVolume
	else
		return 1
	end
end

--[[
	SOUNDS EXTENSIONS
]]--

Sound._play = Sound.play

function Sound:play()
	local channel = self:_play()
	if channel ~= nil then
		channel.isPlaying = true
		channel:addEventListener(Event.COMPLETE, function(channel)
			self.isPlaying = false
			application.sounds[self.id] = nil
		end, channel)
		if application.sounds == nil then
			application.sounds = {}
			application.currentSound = 1
		end
		channel.id = application.currentSound
		application.sounds[channel.id] = channel
		application.currentSound = application.currentSound + 1
		--setting global volume
		channel:setVolume(application:getVolume())
	end
	return channel
end

--[[ loop sounds ]]--

function Sound:loop()
	return self:play(0, math.huge)
end

--[[
	SOUNDSCHANNEL EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(SoundChannel)

SoundChannel.__stop =  SoundChannel.stop
function SoundChannel:stop(...)
	self:__stop(...)
	self.isPlaying = false
	application.sounds[self.id] = nil
	return self
end

--[[ check if sound is still playing ]]--

function SoundChannel:isPlaying()
	return self.isPlaying
end

--[[
	MATRIX EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(Matrix)

--[[ abstract functions ]]--

function Matrix:rotate(deg)
	local rad = math.rad(deg)
	return self:multiply(Matrix.new(math.cos(rad), math.sin(rad), -math.sin(rad), math.cos(rad), 0, 0))
end

function Matrix:translate(x,y)
	if not y then y = x end
	return self:multiply(Matrix.new(1, 0, 0, 1, x, y))
end

function Matrix:translateX(x)
	return self:translate(x, 0)
end

function Matrix:translateY(y)
	return self:translate(0, y)
end

function Matrix:scale(x,y)
	if not y then y = x end
	return self:multiply(Matrix.new(x, 0, 0, y, 0, 0))
end

function Matrix:scaleX(x)
	return self:scale(x, 1)
end

function Matrix:scaleY(y)
	return self:scale(1, y)
end

function Matrix:skew(xAng,yAng)
	if not yAng then yAng = xAng end
	xAng = math.rad(xAng)
	yAng = math.rad(yAng)
	return self:multiply(Matrix.new(1, math.tan(yAng), math.tan(xAng), 1, 0, 0))
end

function Matrix:skewX(xAng)
	return self:skew(xAng, 0)
end

function Matrix:skewY(yAng)
	return self:skew(0, yAng)
end

function Matrix:multiply(matrix)
	local m11 = matrix:getM11()*self:getM11() + matrix:getM12()*self:getM21()
	local m12 = matrix:getM11()*self:getM12() + matrix:getM12()*self:getM22()
	local m21 = matrix:getM21()*self:getM11() + matrix:getM22()*self:getM21()
	local m22 = matrix:getM21()*self:getM12() + matrix:getM22()*self:getM22()
	local tx = self:getTx() + matrix:getTx()
	local ty = self:getTy() + matrix:getTy()
	return self:setElements(m11, m12, m21, m22, tx, ty)
end

function Matrix:copy()
	return Matrix.new(self:getElements())
end

function Matrix:apply(obj)
	if obj.setMatrix then
		obj:setMatrix(self)
	end
	return self
end

function Matrix:reset()
	return self:setElements(1, 0, 0, 1, 0, 0)
end

--[[
	MOUSE/TOUCH EVENTS CROSSCOMPATABILITY
]]--

local os = application:getDeviceInfo()
 
if os == "Windows" or os == "Mac OS" then
	EventDispatcher.__addEventListener = EventDispatcher.addEventListener
 
	local function wrapper(t, e)
		e.touch = {}
		e.touch.id = 1
		e.touch.x = e.x
		e.touch.y = e.y
		
		if t.data then
			t.listener(t.data, e)
		else
			t.listener(e)
		end
	end
 
	function EventDispatcher:addEventListener(type, listener, data)
		if type == Event.TOUCHES_BEGIN then
			self:__addEventListener(Event.MOUSE_DOWN, wrapper, {listener = listener, data = data})
		elseif type == Event.TOUCHES_MOVE then
			self:__addEventListener(Event.MOUSE_MOVE, wrapper, {listener = listener, data = data})
		elseif type == Event.TOUCHES_END then
			self:__addEventListener(Event.MOUSE_UP, wrapper, {listener = listener, data = data})
		else
			self:__addEventListener(type, listener, data)
		end
		return self
	end
end

--[[
	NAMED COLORS
]]--
Colors = {
	ALICEBLUE = 0XF0F8FF,
	ANTIQUEWHITE = 0XFAEBD7,
	AQUA = 0X00FFFF,
	AQUAMARINE = 0X7FFFD4,
	AZURE = 0XF0FFFF,
	BEIGE = 0XF5F5DC,
	BISQUE = 0XFFE4C4,
	BLACK = 0X000000,
	BLANCHEDALMOND = 0XFFEBCD,
	BLUE = 0X0000FF,
	BLUEVIOLET = 0X8A2BE2,
	BROWN = 0XA52A2A,
	BURLYWOOD = 0XDEB887,
	CADETBLUE = 0X5F9EA0,
	CHARTREUSE = 0X7FFF00,
	CHOCOLATE = 0XD2691E,
	CORAL = 0XFF7F50,
	CORNFLOWERBLUE = 0X6495ED,
	CORNSILK = 0XFFF8DC,
	CRIMSON = 0XDC143C,
	CYAN = 0X00FFFF,
	DARKBLUE = 0X00008B,
	DARKCYAN = 0X008B8B,
	DARKGOLDENROD = 0XB8860B,
	DARKGRAY = 0XA9A9A9,
	DARKGREY = 0XA9A9A9,
	DARKGREEN = 0X006400,
	DARKKHAKI = 0XBDB76B,
	DARKMAGENTA = 0X8B008B,
	DARKOLIVEGREEN = 0X556B2F,
	DARKORANGE = 0XFF8C00,
	DARKORCHID = 0X9932CC,
	DARKRED = 0X8B0000,
	DARKSALMON = 0XE9967A,
	DARKSEAGREEN = 0X8FBC8F,
	DARKSLATEBLUE = 0X483D8B,
	DARKSLATEGRAY = 0X2F4F4F,
	DARKSLATEGREY = 0X2F4F4F,
	DARKTURQUOISE = 0X00CED1,
	DARKVIOLET = 0X9400D3,
	DEEPPINK = 0XFF1493,
	DEEPSKYBLUE = 0X00BFFF,
	DIMGRAY = 0X696969,
	DIMGREY = 0X696969,
	DODGERBLUE = 0X1E90FF,
	FIREBRICK = 0XB22222,
	FLORALWHITE = 0XFFFAF0,
	FORESTGREEN = 0X228B22,
	FUCHSIA = 0XFF00FF,
	GAINSBORO = 0XDCDCDC,
	GHOSTWHITE = 0XF8F8FF,
	GOLD = 0XFFD700,
	GOLDENROD = 0XDAA520,
	GRAY = 0X808080,
	GREY = 0X808080,
	GREEN = 0X008000,
	GREENYELLOW = 0XADFF2F,
	HONEYDEW = 0XF0FFF0,
	HOTPINK = 0XFF69B4,
	INDIANRED  = 0XCD5C5C,
	INDIGO  = 0X4B0082,
	IVORY = 0XFFFFF0,
	KHAKI = 0XF0E68C,
	LAVENDER = 0XE6E6FA,
	LAVENDERBLUSH = 0XFFF0F5,
	LAWNGREEN = 0X7CFC00,
	LEMONCHIFFON = 0XFFFACD,
	LIGHTBLUE = 0XADD8E6,
	LIGHTCORAL = 0XF08080,
	LIGHTCYAN = 0XE0FFFF,
	LIGHTGOLDENRODYELLOW = 0XFAFAD2,
	LIGHTGRAY = 0XD3D3D3,
	LIGHTGREY = 0XD3D3D3,
	LIGHTGREEN = 0X90EE90,
	LIGHTPINK = 0XFFB6C1,
	LIGHTSALMON = 0XFFA07A,
	LIGHTSEAGREEN = 0X20B2AA,
	LIGHTSKYBLUE = 0X87CEFA,
	LIGHTSLATEGRAY = 0X778899,
	LIGHTSLATEGREY = 0X778899,
	LIGHTSTEELBLUE = 0XB0C4DE,
	LIGHTYELLOW = 0XFFFFE0,
	LIME = 0X00FF00,
	LIMEGREEN = 0X32CD32,
	LINEN = 0XFAF0E6,
	MAGENTA = 0XFF00FF,
	MAROON = 0X800000,
	MEDIUMAQUAMARINE = 0X66CDAA,
	MEDIUMBLUE = 0X0000CD,
	MEDIUMORCHID = 0XBA55D3,
	MEDIUMPURPLE = 0X9370D8,
	MEDIUMSEAGREEN = 0X3CB371,
	MEDIUMSLATEBLUE = 0X7B68EE,
	MEDIUMSPRINGGREEN = 0X00FA9A,
	MEDIUMTURQUOISE = 0X48D1CC,
	MEDIUMVIOLETRED = 0XC71585,
	MIDNIGHTBLUE = 0X191970,
	MINTCREAM = 0XF5FFFA,
	MISTYROSE = 0XFFE4E1,
	MOCCASIN = 0XFFE4B5,
	NAVAJOWHITE = 0XFFDEAD,
	NAVY = 0X000080,
	OLDLACE = 0XFDF5E6,
	OLIVE = 0X808000,
	OLIVEDRAB = 0X6B8E23,
	ORANGE = 0XFFA500,
	ORANGERED = 0XFF4500,
	ORCHID = 0XDA70D6,
	PALEGOLDENROD = 0XEEE8AA,
	PALEGREEN = 0X98FB98,
	PALETURQUOISE = 0XAFEEEE,
	PALEVIOLETRED = 0XD87093,
	PAPAYAWHIP = 0XFFEFD5,
	PEACHPUFF = 0XFFDAB9,
	PERU = 0XCD853F,
	PINK = 0XFFC0CB,
	PLUM = 0XDDA0DD,
	POWDERBLUE = 0XB0E0E6,
	PURPLE = 0X800080,
	RED = 0XFF0000,
	ROSYBROWN = 0XBC8F8F,
	ROYALBLUE = 0X4169E1,
	SADDLEBROWN = 0X8B4513,
	SALMON = 0XFA8072,
	SANDYBROWN = 0XF4A460,
	SEAGREEN = 0X2E8B57,
	SEASHELL = 0XFFF5EE,
	SIENNA = 0XA0522D,
	SILVER = 0XC0C0C0,
	SKYBLUE = 0X87CEEB,
	SLATEBLUE = 0X6A5ACD,
	SLATEGRAY = 0X708090,
	SLATEGREY = 0X708090,
	SNOW = 0XFFFAFA,
	SPRINGGREEN = 0X00FF7F,
	STEELBLUE = 0X4682B4,
	TAN = 0XD2B48C,
	TEAL = 0X008080,
	THISTLE = 0XD8BFD8,
	TOMATO = 0XFF6347,
	TURQUOISE = 0X40E0D0,
	VIOLET = 0XEE82EE,
	WHEAT = 0XF5DEB3,
	WHITE = 0XFFFFFF,
	WHITESMOKE = 0XF5F5F5,
	YELLOW = 0XFFFF00,
	YELLOWGREEN = 0X9ACD32,
}

local function colorCallback(color)
	if type(color) == "string" then
		color = color:upper()
		color = Colors[color]
		if color == nil then
			error("Invalid color name")
		end
	end
	return color
end

overRideMethod(TextField, "setTextColor", 2, colorCallback)
overRideMethod(Application, "setBackgroundColor", 2, colorCallback)
overRideMethod(Shape, "setFillStyle", 3, colorCallback)
overRideMethod(Shape, "setLineStyle", 3, colorCallback)

--[[
	PHYSICS EXTENSIONS
]]--

function loadPhysicsExtension()

	b2.World._new = b2.World.new
	
	function b2.World.new(...)
		local world = b2.World._new(...)
		world.sprites = {}
		world.curSprite = 1
		return world
	end
	
	function b2.World:makeDraggable(object)
		--create empty box2d body for joint
		--since mouse cursor is not a body
		--we need dummy body to create joint
		local ground = self:createBody({})
		
		--joint with dummy body
		local mouseJoint = nil
		-- create a mouse joint on mouse down
		object.onDragStart = function(self, event)
			if object:hitTestPoint(event.touch.x, event.touch.y) then
				local jointDef = b2.createMouseJointDef(ground, object.body, 
				event.touch.x, event.touch.y, 100000)
				mouseJoint = self:createJoint(jointDef)
			end
		end
	
		-- update the target of mouse joint on mouse move
		object.onDragMove = function(self, event)
			if mouseJoint ~= nil then
				mouseJoint:setTarget(event.touch.x, event.touch.y)
			end
		end
	
	
		-- destroy the mouse joint on mouse up
		object.onDragEnd = function(self, event)
			if mouseJoint ~= nil then
				self:destroyJoint(mouseJoint)
				mouseJoint = nil
			end
		end
	
		-- register for mouse events
		object:addEventListener(Event.TOUCHES_BEGIN, object.onDragStart, self)
		object:addEventListener(Event.TOUCHES_MOVE, object.onDragMove, self)
		object:addEventListener(Event.TOUCHES_END, object.onDragEnd, self)
	end
	
	function b2.World:undoDraggable(object)
		-- register for mouse events
		object:removeEventListener(Event.TOUCHES_BEGIN, object.onDragStart, self)
		object:removeEventListener(Event.TOUCHES_MOVE, object.onDragMove, self)
		object:removeEventListener(Event.TOUCHES_END, object.onDragEnd, self)
		object.onDragStart = nil
		object.onDragMove = nil
		object.onDragEnd = nil
	end
	
	function b2.World:createRectangle(object, config)
		
		self.conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			resitution = 0.2,
			update = true,
			draggable = false,
			width = nil,
			height = nil
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				self.conf[key]= value
			end
		end
		
		if object and self.conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if self.conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif self.conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		
		local angle
		if object then
			angle = object:getRotation()
			object:setRotation(0)
		end
		
		local width = self.conf.width or object:getWidth()
		local height = self.conf.height or object:getHeight()
		
		local poly = b2.PolygonShape.new()
		poly:setAsBox(width/2, height/2)
		
		local fixture = body:createFixture{shape = poly, density = self.conf.density, 
		friction = self.conf.friction, restitution = self.conf.resitution}
		
		if object then
			object:setAnchorPoint(0.5, 0.5)
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(angle))
			object.body = body
			if self.conf.type == "dynamic" and self.conf.draggable then
				self:makeDraggable(object)
			end
			object:setRotation(angle)
		end
		
		body.userdata = {}
		body.joints = {}
		
	end
	
	function b2.World:createCircle(object, config)
		
		self.conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			resitution = 0.2,
			update = true,
			draggable = false,
			radius = nil
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				self.conf[key]= value
			end
		end
		
		if object and self.conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if self.conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif self.conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		local angle
		if object then
			angle = object:getRotation()
			object:setRotation(0)
		end
		
		local radius = self.conf.radius or object:getWidth()/2
		
		local circle = b2.CircleShape.new(0, 0, radius)
		
		local fixture = body:createFixture{shape = circle, density = self.conf.density, 
		friction = self.conf.friction, restitution = self.conf.resitution}
		
		if object then
			object:setAnchorPoint(0.5, 0.5)
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(angle))
			object.body = body
			if self.conf.type == "dynamic" and self.conf.draggable then
				self:makeDraggable(object)
			end
			object:setRotation(angle)
		end
		
		body.userdata = {}
		body.joints = {}
		
	end
	
	--[[function b2.World:createRoundRectangle(object, width, height, radius, config)
		
		self.conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			resitution = 0.2,
			update = true,
			draggable = false
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				self.conf[key]= value
			end
		end
		
		if object and self.conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if self.conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif self.conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		
		local chain = b2.ChainShape.new()
		local vertices = {}
		local startW = -width/2
		local startH = -height/2
		local endW = width/2
		local endH = height/2
		vertices[#vertices+1] = startW
		vertices[#vertices+1] = startH + radius
		vertices[#vertices+1] = startW
		vertices[#vertices+1] = endH - radius
		local points = quadraticCurve(startW, endH - radius,
				startW, endH, 
				startW + radius, endH)
		for i = 1, #points do
			vertices[#vertices+1] = points[i]
		end
		vertices[#vertices+1] = endW - radius
		vertices[#vertices+1] = endH
		local points = quadraticCurve(endW - radius, endH,
				endW, endH, 
				endW, endH - radius)
		for i = 1, #points do
			vertices[#vertices+1] = points[i]
		end
		
		vertices[#vertices+1] = endW
		vertices[#vertices+1] = startH + radius
		local points = quadraticCurve(endW, startH + radius,
				endW, startH, 
				endW - radius, startH)
		for i = 1, #points do
			vertices[#vertices+1] = points[i]
		end
		vertices[#vertices+1] = startW + radius
		vertices[#vertices+1] = startH
		local points = quadraticCurve(startW + radius, startH,
				startW, startH, 
				startW, startH + radius)
		for i = 1, #points do
			vertices[#vertices+1] = points[i]
		end
		chain:createChain(unpack(vertices))
		
		local fixture = body:createFixture{shape = chain, density = self.conf.density, 
		friction = self.conf.friction, restitution = self.conf.resitution}
		
		if object then
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(object:getRotation()))
			object.body = body
			if self.conf.type == "dynamic" and self.conf.draggable then
				self:makeDraggable(object)
			end
		end
		
		body.userdata = {}
		body.joints = {}
		
	end]]
	
	function b2.World:createTerrain(object, vertices, config)
		
		self.conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			resitution = 0.2,
			update = true,
			draggable = false
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				self.conf[key]= value
			end
		end
		
		if object and self.conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if self.conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif self.conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		
		local chain = b2.ChainShape.new()
		chain:createChain(unpack(vertices))
		
		local fixture = body:createFixture{shape = chain, density = self.conf.density, 
		friction = self.conf.friction, restitution = self.conf.resitution}
		
		if object then
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(object:getRotation()))
			object.body = body
			if self.conf.type == "dynamic" and self.conf.draggable then
				self:makeDraggable(object)
			end
		end
		
		body.userdata = {}
		body.joints = {}
		
	end
	
	function b2.World:update()
		-- edit the step values if required. These are good defaults!
		self:step(1/60, 8, 3)
		--iterate through all child sprites
		local sprites = #self.sprites
		for i = 1, sprites do
			--get specific sprite
			local sprite = self.sprites[i]
			-- check if sprite HAS a body (ie, physical object reference we added)
			if sprite.body then
				--update position to match box2d world object's position
				--get physical body reference
				local body = sprite.body
				--get body coordinates
				local bodyX, bodyY = body:getPosition()
				--apply coordinates to sprite
				sprite:setPosition(bodyX, bodyY)
				--apply rotation to sprite
				sprite:setRotation(math.deg(body:getAngle()))
			end
		end
	end
	
	function b2.World:getDebug()
		--set up debug drawing
		local debugDraw = b2.DebugDraw.new()
		debugDraw:setFlags(b2.DebugDraw.SHAPE_BIT + b2.DebugDraw.JOINT_BIT)
		self:setDebugDraw(debugDraw)
		return debugDraw
	end
	
	function b2.World:removeBody(object)
		if object.body then
			if object.id then
				self.sprites[object.id] = nil
			end
			Timer.delayedCall(1, function()
				self:destroyBody(object.body)
			end)
			object.body = nil
			object:removeFromParent()
		end
	end
	
	function b2.Body:setData(key, value)
		self.userdata[key] = value
	end
	
	function b2.Body:getData(key)
		return self.userdata[key]
	end
end

--[[ catching the load of box2d ]]--

local _require = require
require = function(name)
	_require(name)
	if name == "box2d" then
		-- load box2d extensions
		loadPhysicsExtension()
		require = _require
	end
end
