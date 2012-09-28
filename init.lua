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

--[[
	EVENTDISPATCHER EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(EventDispatcher)

EventDispatcher.__dispatchEvent =  EventDispatcher.dispatchEvent
function EventDispatcher:dispatchEvent(...)
	self:__dispatchEvent(unpack(arg))
	return self
end

--[[
	SPRITE EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(Sprite)

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
	if Sprite.transform[param] then
		local matrix = self:getMatrix()
		matrix[param](matrix, value)
		self:setMatrix(matrix)
	else
		local _, _, width, height = self:getBounds(stage)
		if param == "x" and type(value) == "string" then
			local xPosition = {
				left = 0,
				center = (application:getContentWidth() - width)/2,
				right = application:getContentWidth() - width
			}
			if xPosition[value] then
				value = xPosition[value]
			end
		end
		if param == "y" and type(value) == "string" then
			local yPosition = {
				top = 0,
				center = (application:getContentHeight() - height)/2,
				bottom = application:getContentHeight() - height
			}
			if yPosition[value] then
				value = yPosition[value]
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

function Bitmap:getTexture()
	return texture
end

--[[ chaining ]]--

changeAllSetFunctions(Bitmap)

--[[
	TEXTFIELD EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(TextField)

--[[
	SHAPE EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(Shape)

Shape.__beginPath =  Shape.beginPath
function Shape:beginPath(...)
	self:__beginPath(unpack(arg))
	return self
end

Shape.__moveTo =  Shape.moveTo
function Shape:moveTo(...)
	self:__moveTo(unpack(arg))
	return self
end

Shape.__lineTo =  Shape.lineTo
function Shape:lineTo(...)
	self:__lineTo(unpack(arg))
	return self
end

Shape.__endPath =  Shape.endPath
function Shape:endPath(...)
	self:__endPath(unpack(arg))
	return self
end

Shape.__closePath =  Shape.closePath
function Shape:closePath(...)
	self:__closePath(unpack(arg))
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

function Shape:drawRect(width, height)
	return self:drawPoly({
		{0, 0},
		{width, 0},
		{width, height},
		{0, height}
	})
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
	self:__shift(unpack(arg))
	return self
end

--[[
	MOVIECLIP EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(MovieClip)

MovieClip.__play =  MovieClip.play
function MovieClip:play(...)
	self:__play(unpack(arg))
	return self
end

MovieClip.__stop =  MovieClip.stop
function MovieClip:stop(...)
	self:__stop(unpack(arg))
	return self
end

MovieClip.__gotoAndPlay =  MovieClip.gotoAndPlay
function MovieClip:gotoAndPlay(...)
	self:__gotoAndPlay(unpack(arg))
	return self
end

MovieClip.__gotoAndStop =  MovieClip.gotoAndStop
function MovieClip:gotoAndStop(...)
	self:__gotoAndStop(unpack(arg))
	return self
end

--[[
	APPLICATION EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(Application)

Application.__openUrl =  Application.openUrl
function Application:openUrl(...)
	self:__openUrl(unpack(arg))
	return self
end

Application.__vibrate =  Application.vibrate
function Application:vibrate(...)
	self:__vibrate(unpack(arg))
	return self
end

--[[
	SOUNDS EXTENSIONS
]]--

--[[ loop sounds ]]--

function Sound:loop()
	return self:play(0, math.huge)
end

--[[
	SOUNDSCHANNEL EXTENSIONS
]]--

--[[ chaining ]]--

changeAllSetFunctions(MovieClip)

SoundChannel.__stop =  SoundChannel.stop
function SoundChannel:stop(...)
	self:__stop(unpack(arg))
	return self
end

--[[
	MATRIX EXTENSIONS
]]--

--[[
	SOUNDSCHANNEL EXTENSIONS
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