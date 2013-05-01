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

local function defExt(path, ext)
	local found, len, remainder = string.find(path, "^(.*)%.[^%.]*$")
	if found then
		return path
	else
		return path .. "." .. ext
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


function io.exists(file)
    local f = io.open(file, "rb")
    if f == nil then
        return false
    end
    f:close()
    return true
end

function io.copy(src, dst)
    local srcf = io.open(src, "rb")
    local dstf = io.open(dst, "wb")

    local size = 2^13      -- good buffer size (8K)
    while true do
        local block = srcf:read(size)
        if not block then break end
        dstf:write(block)
    end

    srcf:close()
    dstf:close()
end

--[[ CHAINING STARTS ]]--

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

changeAllSetFunctions(EventDispatcher)

EventDispatcher.__dispatchEvent =  EventDispatcher.dispatchEvent
function EventDispatcher:dispatchEvent(...)
	self:__dispatchEvent(...)
	return self
end

changeAllSetFunctions(Sprite)

changeAllSetFunctions(TextureRegion)

changeAllSetFunctions(Bitmap)

changeAllSetFunctions(TextField)

changeAllSetFunctions(Shape)

Shape.__beginPath =  Shape.beginPath
function Shape:beginPath(...)
	self:__beginPath(...)
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

changeAllSetFunctions(TileMap)

TileMap.__shift =  TileMap.shift
function TileMap:shift(...)
	self:__shift(...)
	return self
end

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

changeAllSetFunctions(SoundChannel)

UrlLoader.__load =  UrlLoader.load
function UrlLoader:load(...)
	self:__load(...)
	return self
end

UrlLoader.__close =  UrlLoader.close
function UrlLoader:close(...)
	self:__close(...)
	return self
end

changeAllSetFunctions(Timer)

Timer.__start =  Timer.start
function Timer:start(...)
	self:__start(...)
	return self
end

Timer.__stop =  Timer.stop
function Timer:stop(...)
	self:__stop(...)
	return self
end

Timer.__reset =  Timer.reset
function Timer:reset(...)
	self:__reset(...)
	return self
end

changeAllSetFunctions(Matrix)

changeAllSetFunctions(TextInputDialog)

--[[CHAINING ENDS]]--



--[[
	SPRITE EXTENSIONS
]]--

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
	
	self._offX = math.round(self._offX + dx)
	self._offY = math.round(self._offY + dy)
	
	local newX = curX + self._offX
	local newY = curY + self._offY
	
	self:_set("x", math.round(newX))
	self:_set("y", math.round(newY))
	
	return self
end

Sprite._setRotation = Sprite.setRotation

function Sprite:setRotation(angle)
	return self:set("rotation", angle)
end

Sprite._get = Sprite.get

function Sprite:get(param)
	self:_testAnchor()
	if Sprite.transform[param] ~= nil then
		return Sprite.transform[param]
	else
		if param == "x" then
			local x = self:_get("x")
			return x - self._offX
		elseif param == "y" then
			local y = self:_get("y")
			return y - self._offY
		else
			local ret
			if self.body then
				ret = self.body:get(param)
			end
			if ret ~= nil then
				return ret
			else
				return self:_get(param)
			end
		end
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
		parent:addChildAt(self, 1)
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

function Sprite:getIndex()
	local parent = self:getParent()
	if parent then
		return parent:getChildIndex(self)
	end
end

function Sprite:addChildAtBack(child)
	self:addChildAt(child, 1)
	return self
end

function Sprite:addChildBefore(child, reference)
	local index = self:getChildIndex(reference)
	self:addChildAt(child, index-1)
	return self
end

function Sprite:addChildAfter(child, reference)
	local index = self:getChildIndex(reference)
	self:addChildAt(child, index+1)
	return self
end

function Sprite:replaceChild(existing, newchild)
	local index = self:getChildIndex(existing)
	self:removeChild(existing)
	self:addChildAt(newchild, index)
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
	if Sprite.transform[param] ~= nil then
		Sprite.transform[param] = value
		local matrix = self:getMatrix()
		matrix[param](matrix, value)
		self:setMatrix(matrix)
		if param == "skewX" or param == "skewY" or param == "skew" then
			self:setAnchorPoint(self:getAnchorPoint())
		end
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
			if self._offX then
				value = value + self._offX
			end
			value = math.round(value)
			if self.body then
				local x,y = self.body:getPosition()
				self.body:setPosition(value, y)
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
			if self._offY then
				value = value + self._offY
			end
			value = math.round(value)
			if self.body then
				local x,y = self.body:getPosition()
				self.body:setPosition(x, value)
			end
		elseif param == "rotation" then
			if self.body then
				self.body:setAngle(math.rad(value))
			end
		end
		local status = pcall(function()
			Sprite._set(self, param, value)
		end)
		if not status and self.body then
			self.body:set(param, value)
		end
		if param == "rotation" or param == "scaleX" or param == "scaleY" or param == "scale" then
			self:setAnchorPoint(self:getAnchorPoint())
		end
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
	self:addEventListener(Event.MOUSE_DOWN, self.ignoreMouseHandler, self)
	self:addEventListener(Event.TOUCHES_BEGIN, self.ignoreTouchHandler, self)
	return self
end

function Sprite:enableTouches()
	-- Tell a sprite to ignore (and block) all mouse and touch events
	self:removeEventListener(Event.MOUSE_DOWN, self.ignoreMouseHandler, self)
	self:removeEventListener(Event.TOUCHES_BEGIN, self.ignoreTouchHandler, self)
	return self
end

function Sprite:setWidth(newWidth)
	-- Set a sprite's width using the scale property
	local x,y,width,height=self:getBounds(self)
	local newScale=newWidth/width
	self:setScaleX(newScale)
	return self
end
 
function Sprite:setHeight(newHeight)
	-- Set a sprite's height using the scale property
	local x,y,width,height=self:getBounds(self)
	local newScale=newHeight/height
	self:setScaleY(newScale)
	return self
end

--[[ skew transformation ]]--

Sprite.transform = {
	skew = 0,
	skewX = 0,
	skewY = 0
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

function Sprite:getSkew()
	return self:get("skewX"), self:get("skewY")
end

function Sprite:getSkewX()
	return self:get("skewX")
end

function Sprite:getSkewY()
	return self:get("skewY")
end

--[[ flipping ]]--

function Sprite:flipHorizontal()
	self:setScaleX(-self:getScaleX())
	return self
end

function Sprite:flipVertical()
	self:setScaleY(-self:getScaleY())
	return self
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

function Sprite:isVisibleDeeply()
	-- Answer true only if the sprite and all it's a parents are visible. Normally, isVisible() will
	-- return true even if a sprite is actually not visible on screen by wont of one of it's parents
	-- being made invisible.
	--
	local try=self
	while (try) do
		if  not(try:isVisible() and try:getAlpha()>0) then
			return false
		end
		try = try:getParent()
	end
	return true
end

--[[
	TEXTUREPACK EXTENSIONS
]]--

--[[ shorthand ]]--

TexturePack._new = TexturePack.new

function TexturePack.new(...)
	
	local pack
	local arg = {...}
	if type(arg[1]) == "string" then
		local txt=defExt(arg[1], "txt")
		local png=defExt(arg[2] or arg[1], "png")
		pack = TexturePack._new(txt, png)
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
	local arg = {...}
	if type(arg[1]) == "string" then
		arg[1] = Texture.new(...)
	end
	
	local bitmap = Bitmap._new(arg[1])
	bitmap.texture = arg[1]
	return bitmap
end

function Bitmap:getTexture()
	return self.texture
end

Bitmap._setAnchorPoint = Bitmap.setAnchorPoint

function Bitmap:setAnchorPoint(x, y)
	y = y or x
	self:_setAnchorPoint(x,y)
	return self
end

--[[
	TEXTFIELD EXTENSIONS
]]--

--[[ Completely overriding TextField ]]--

_TextField = TextField

TextField = Core.class(Sprite)

function TextField:init(...)
	local arg = {...}
	self._text = _TextField.new(...)
	self:addChild(self._text)
	self._font = arg[1]
	self._offsetX = 0
	self._offsetY = 0
	
	local baseX, baseY = self._text:getBounds(stage)
	self._text:setPosition(-baseX, -baseY)
end

function TextField:setText(...)
	self._text:setText(...)
	if self._shadow then
		self._shadow:setText(...)
	end
	return self
end

function TextField:getText()
	return self._text:getText()
end

function TextField:setTextColor(...)
	self._text:setTextColor(...)
	if self._shadow then
		self._shadow:setTextColor(...)
	end
	return self
end

function TextField:getTextColor()
	return self._text:getTextColor()
end

function TextField:setLetterSpacing(...)
	self._text:setLetterSpacing(...)
	if self._shadow then
		self._shadow:setLetterSpacing(...)
	end
	return self
end

function TextField:getLetterSpacing()
	return self._text:getLetterSpacing()
end

--[[ shadow implementation ]]--

function TextField:setShadow(offX, offY, color, alpha)
	if not self._shadow then
		self._shadow = _TextField.new(self._font, self._text:getText())
		self._shadow:setTextColor(self._text:getTextColor())
		self._shadow:setLetterSpacing(self._text:getLetterSpacing())
		self:addChildAtBack(self._shadow)
	end
	
	self._shadow:setPosition(offX + self._text:getX(), offY + self._text:getY())
	
	if color then
		self._shadow:setTextColor(color)
		if alpha then
			self._shadow:setAlpha(alpha)
		end
	end
	return self
end

--[[
	SHAPE EXTENSIONS
]]--

--[[ draw a polygon from a list of vertices ]]--

function Shape:drawPoly(points)
	local drawOp=self.moveTo
	self:beginPath()
	if type(points[1]) == "table" then
		for i,p in ipairs(points) do
			drawOp(self, p[1], p[2])
			drawOp=self.lineTo
		end
	else
		for i = 1, #points, 2 do
			drawOp(self, points[i], points[i+1])
			drawOp=self.lineTo
		end
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

Shape._new = Shape.__new

function Shape.__new()
	local shape = Shape._new()
	shape._lastPoint = nil
	shape._allPoints = {}
	return shape
end

Shape._moveTo = Shape.moveTo

function Shape:moveTo(x,y)
	self:_moveTo(x, y)
	self._lastPoint = { x, y }
	self._allPoints[#self._allPoints+1] = x
	self._allPoints[#self._allPoints+1] = y
	return self
end

Shape._lineTo = Shape.lineTo

function Shape:lineTo(x,y)
	self:_lineTo(x, y)
	self._lastPoint = { x, y }
	self._allPoints[#self._allPoints+1] = x
	self._allPoints[#self._allPoints+1] = y
	return self
end

Shape._clear = Shape.clear

function Shape:clear()
	self:_clear()
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
			self:lineTo(points[i],points[i+1])
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
			self:lineTo(p.x,p.y)
		end
	end
	self._lastPoint = { x, y }
	return self
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

--[[ global volume implementation ]]--

function Application:setVolume(volume)
	self.currentVolume = volume
	for i = 1, #self.sounds do
		self.sounds[i]:setVolume(volume)
	end
	return self
end

function Application:getVolume()
	if self.currentVolume then
		return self.currentVolume
	else
		return 1
	end
end

Application.__exit = Application.exit
 
function Application:exit()
	if self:getDeviceInfo() == "Android" then self:__exit() end
end

--[[ global antialising implementation ]]--

function Application:enableFiltering()
	self._filtering = true
	return self
end

function Application:disableFiltering()
	self._filtering = false
	return self
end

function Application:isFilteringEnabled()
	return self._filtering
end

Font._new = Font.__new

function Font.__new(...)
	local arg = {...}
	if arg[3] == nil then
		arg[3] = application:isFilteringEnabled()
	end
	local font = Font._new(unpack(arg))
	return font
end

TTFont._new = TTFont.__new

function TTFont.__new(...)
	local arg = {...}
	if arg[3] == nil then
		arg[3] = application:isFilteringEnabled()
	end
	local font = TTFont._new(unpack(arg))
	return font
end

Texture._new = Texture.__new

function Texture.__new(...)
	local arg = {...}
	if arg[2] == nil then
		arg[2] = application:isFilteringEnabled()
	end
	local font = Texture._new(unpack(arg))
	return font
end

--[[
	SOUNDS EXTENSIONS
]]--

Sound._play = Sound.play

function Sound:play(...)
	local channel = self:_play(...)
	if channel ~= nil then
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

function Sound:playWithLoopCount(startTime, nbLoops)
	nbLoops = nbLoops or 1
	local soundLength = self:getLength()
 
	local channel = self:play(startTime, true) -- loop infinitely
 
	-- set looping as false after (loops - 0.5) count
	Timer.delayedCall((nbLoops - 0.5) * soundLength, function() channel:setLooping(false) end)
 
	return channel
end

--[[
	SOUNDSCHANNEL EXTENSIONS
]]--

SoundChannel.__stop =  SoundChannel.stop
function SoundChannel:stop(...)
	self:__stop(...)
	self.isPlaying = false
	application.sounds[self.id] = nil
	return self
end

SoundChannel.___set=SoundChannel.set
 
function SoundChannel:set(param, value)
	if param=="volume" then
		self:setVolume(value)
	elseif param=="pitch" then
		self:setPitch(value)
	else
		SoundChannel.___set(self, param, value)
	end
	return self
end
 
SoundChannel.___get=SoundChannel.get
 
function SoundChannel:get(param, value)
	if param=="volume" then
		return self:getVolume()
	end
	if param=="pitch" then
		return self:getPitch()
	end
	return SoundChannel.___get(self, param, value)
end
 
function SoundChannel:fadeIn(duration, optFinalLevel, completionFunc)
	if GTween then
		self:setVolume(0)
		GTween.new(self, duration, { volume=optFinalLevel or 1 }, { onComplete=completionFunc })
	end
end
 
function SoundChannel:fadeOut(duration, optFinalLevel, completionFunc)
	if GTween then
		GTween.new(self, duration, { volume=optFinalLevel or 0 }, { onComplete=
			function() 
				self:stop()
				if completionFunc then completionFunc() end
			end
		})
	end
end

--[[
	MATRIX EXTENSIONS
]]--

--[[ abstract functions ]]--

function Matrix:rotate(deg)
	local rad = math.rad(deg)
	return self:multiply(Matrix.new(math.cos(rad), -math.sin(rad), math.sin(rad), math.cos(rad), 0, 0))
end

function Matrix:translate(x,y)
	return self:multiply(Matrix.new(1, 0, 0, 1, x, y or x))
end

function Matrix:translateX(x)
	return self:translate(x, 0)
end

function Matrix:translateY(y)
	return self:translate(0, y)
end

function Matrix:scale(sx,sy)
	return self:multiply(Matrix.new(sx, 0, 0, sy or sx, 0, 0))
end

function Matrix:scaleX(x)
	return self:scale(x, 1)
end

function Matrix:scaleY(y)
	return self:scale(1, y)
end

function Matrix:skew(xAng,yAng)
	xAng = math.rad(xAng)
	yAng = math.rad(yAng or xAng)
	return self:multiply(Matrix.new(1, math.tan(xAng), math.tan(yAng), 1, 0, 0))
end

function Matrix:skewX(xAng)
	return self:skew(xAng, 0)
end

function Matrix:skewY(yAng)
	return self:skew(0, yAng)
end

function Matrix:multiply(matrix)
	local m11 = self:getM11()*matrix:getM11() + self:getM12()*matrix:getM21()
	local m12 = self:getM11()*matrix:getM12() + self:getM12()*matrix:getM22()
	local m21 = self:getM21()*matrix:getM11() + self:getM22()*matrix:getM21()
	local m22 = self:getM21()*matrix:getM12() + self:getM22()*matrix:getM22()
	local tx  = self:getM11()*matrix:getTx()  + self:getM12()*matrix:getTy() + self:getTx()
	local ty  = self:getM21()*matrix:getTx()  + self:getM22()*matrix:getTy() + self:getTy()
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
		local colorName=color
		color = color:upper()
		color = Colors[color]
		if color == nil then
			error("Invalid color name", colorName)
		end
	end
	return color
end

overRideMethod(_TextField, "setTextColor", 2, colorCallback)
overRideMethod(Application, "setBackgroundColor", 2, colorCallback)
overRideMethod(Shape, "setFillStyle", 3, colorCallback)
overRideMethod(Shape, "setLineStyle", 3, colorCallback)