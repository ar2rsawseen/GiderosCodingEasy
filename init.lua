--[[
	HELPING FUNCTIONS
]]--

--function for adding methods
function addMethod(object, funcName, func)
	object[funcName] = func
end

--function for overriding methods
function overRideMethod(object, func, index, callback)
	if object ~= nil and object[func] ~= nil and object["__"..func] == nil then
		object["__"..func] = object[func]
		object[func] = function(...)
			if arg[index] then
				arg[index] = callback(arg[index])
			end
			return object["__"..func](unpack(arg))
		end
	end
end

local function print_r (t, indent, done)
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
	SPRITE EXTENSIONS
]]--

--[[ z-axis manipulations ]]--

function Sprite:bringToFront()
	local parent = self:getParent()
	if parent then
		parent:addChild(self)
	end
end
 
function Sprite:sendToBack()
	local parent = self:getParent()
	if parent then
		parent:addChildAt(self, 0)
	end
end
 
function Sprite:setIndex(index)
	local parent = self:getParent()
	if parent then
		if index<parent:getChildIndex(self) then
			index=index-1
		end
		parent:addChildAt(self, index)
	end
end

--[[ simple collision detection ]]--

function Sprite:collidesWith(sprite2)
	local x,y,w,h = self:getBounds(stage)
	local x2,y2,w2,h2 = sprite2:getBounds(stage)

	return not ((y+h < y2) or (y > y2+h2) or (x > x2+w2) or (x+w < x2))
end

--[[ messing up with set method ]]--

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
end

--[[ position wrappers ]]--

function Sprite:setX(x)
	self:set("x", x)
end

function Sprite:setY(y)
	self:set("y", y)
end

function Sprite:setPosition(x, y)
	self:set("x", x)
	self:set("y", y)
end

--[[ skew transformation ]]--

Sprite.transform = {
	"skew",
	"skewX",
	"skewY"
}
function Sprite:setSkew(xAng, yAng)
	self:set("skewX", xAng)
	self:set("skewY", yAng)
end

function Sprite:setSkewX(xAng)
	self:set("skewX", xAng)
end

function Sprite:setSkewY(yAng)
	self:set("skewY", yAng)
end

--[[ flipping ]]--

function Sprite:flipHorizontal()
	self:setScaleX(-1)
end

function Sprite:flipVertical()
	self:setScaleY(-1)
end

--[[ hiding/showing visually and from touch/mouse events ]]--

function Sprite:hide()
	if not self.isHidden then
		self.xScale, self.yScale = self:getScale()
		self:setScale(0)
		self.isHidden = true
	end
end

function Sprite:isHidden()
	return self.isHidden
end

function Sprite:show()
	if self.isHidden then
		self:setScale(self.xScale, self.yScale)
	end
end

--[[
	SHAPE EXTENSIONS
]]--

--[[ draw a polygon from a list of vertices ]]--

function Shape:drawPoly(points)
	self:beginPath()
	for i,p in ipairs(points) do
              self:lineTo(p[1], p[2])
	end
	self:closePath()
	self:endPath()
end

--[[ draw rectangle ]]--

function Shape:drawRect(width, height)
	self:drawPoly({
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

end

--[[ draw arc from ndoss ]]--
function Shape:drawArc(centerX, centerY, radius, startAngle, endAngle, anticlockwise)
   self:drawEllipse(centerX, centerY, radius, radius, startAngle ,endAngle, anticlockwise)
end

--[[ draw circle from ndoss ]]--

function Shape:drawCircle(centerX, centerY, radius, anticlockwise)
   self:drawEllipse(centerX, centerY, radius, radius, 0, 2*math.pi, anticlockwise)
end

--[[
	SOUNDS EXTENSIONS
]]--

--[[ loop sounds ]]--

function Sound:loop()
	return self:play(0, math.huge)
end

--[[
	MATRIX EXTENSIONS
]]--

function Matrix:rotate(deg)
	local rad = math.rad(deg)
	self:multiply(Matrix.new(math.cos(rad), math.sin(rad), -math.sin(rad), math.cos(rad), 0, 0))
end

function Matrix:translate(x,y)
	if not y then y = x end
	self:multiply(Matrix.new(1, 0, 0, 1, x, y))
end

function Matrix:translateX(x)
	self:translate(x, 0)
end

function Matrix:translateY(y)
	self:translate(0, y)
end

function Matrix:scale(x,y)
	if not y then y = x end
	self:multiply(Matrix.new(x, 0, 0, y, 0, 0))
end

function Matrix:scaleX(x)
	self:scale(x, 1)
end

function Matrix:scaleY(y)
	self:scale(1, y)
end

function Matrix:skew(xAng,yAng)
	if not yAng then yAng = xAng end
	xAng = math.rad(xAng)
	yAng = math.rad(yAng)
	self:multiply(Matrix.new(1, math.tan(yAng), math.tan(xAng), 1, 0, 0))
end

function Matrix:skewX(xAng)
	self:skew(xAng, 0)
end

function Matrix:skewY(yAng)
	self:skew(0, yAng)
end

function Matrix:multiply(matrix)
	local m11 = matrix:getM11()*self:getM11() + matrix:getM12()*self:getM21()
	local m12 = matrix:getM11()*self:getM12() + matrix:getM12()*self:getM22()
	local m21 = matrix:getM21()*self:getM11() + matrix:getM22()*self:getM21()
	local m22 = matrix:getM21()*self:getM12() + matrix:getM22()*self:getM22()
	local tx = self:getTx() + matrix:getTx()
	local ty = self:getTy() + matrix:getTy()
	self:setElements(m11, m12, m21, m22, tx, ty)
end

function Matrix:copy()
	return Transform.new(self:getElements())
end

function Matrix:apply(obj)
	if obj.setMatrix then
		obj:setMatrix(self)
	end
end

function Matrix:reset()
	self:setElements(1, 0, 0, 1, 0, 0)
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
	end
end

--[[
	NAMED COLORS
]]--
local colors = {
	aliceblue = 0xf0f8ff,
	antiquewhite = 0xfaebd7,
	aqua = 0x00ffff,
	aquamarine = 0x7fffd4,
	azure = 0xf0ffff,
	beige = 0xf5f5dc,
	bisque = 0xffe4c4,
	black = 0x000000,
	blanchedalmond = 0xffebcd,
	blue = 0x0000ff,
	blueviolet = 0x8a2be2,
	brown = 0xa52a2a,
	burlywood = 0xdeb887,
	cadetblue = 0x5f9ea0,
	chartreuse = 0x7fff00,
	chocolate = 0xd2691e,
	coral = 0xff7f50,
	cornflowerblue = 0x6495ed,
	cornsilk = 0xfff8dc,
	crimson = 0xdc143c,
	cyan = 0x00ffff,
	darkblue = 0x00008b,
	darkcyan = 0x008b8b,
	darkgoldenrod = 0xb8860b,
	darkgray = 0xa9a9a9,
	darkgrey = 0xa9a9a9,
	darkgreen = 0x006400,
	darkkhaki = 0xbdb76b,
	darkmagenta = 0x8b008b,
	darkolivegreen = 0x556b2f,
	darkorange = 0xff8c00,
	darkorchid = 0x9932cc,
	darkred = 0x8b0000,
	darksalmon = 0xe9967a,
	darkseagreen = 0x8fbc8f,
	darkslateblue = 0x483d8b,
	darkslategray = 0x2f4f4f,
	darkslategrey = 0x2f4f4f,
	darkturquoise = 0x00ced1,
	darkviolet = 0x9400d3,
	deeppink = 0xff1493,
	deepskyblue = 0x00bfff,
	dimgray = 0x696969,
	dimgrey = 0x696969,
	dodgerblue = 0x1e90ff,
	firebrick = 0xb22222,
	floralwhite = 0xfffaf0,
	forestgreen = 0x228b22,
	fuchsia = 0xff00ff,
	gainsboro = 0xdcdcdc,
	ghostwhite = 0xf8f8ff,
	gold = 0xffd700,
	goldenrod = 0xdaa520,
	gray = 0x808080,
	grey = 0x808080,
	green = 0x008000,
	greenyellow = 0xadff2f,
	honeydew = 0xf0fff0,
	hotpink = 0xff69b4,
	indianred  = 0xcd5c5c,
	indigo  = 0x4b0082,
	ivory = 0xfffff0,
	khaki = 0xf0e68c,
	lavender = 0xe6e6fa,
	lavenderblush = 0xfff0f5,
	lawngreen = 0x7cfc00,
	lemonchiffon = 0xfffacd,
	lightblue = 0xadd8e6,
	lightcoral = 0xf08080,
	lightcyan = 0xe0ffff,
	lightgoldenrodyellow = 0xfafad2,
	lightgray = 0xd3d3d3,
	lightgrey = 0xd3d3d3,
	lightgreen = 0x90ee90,
	lightpink = 0xffb6c1,
	lightsalmon = 0xffa07a,
	lightseagreen = 0x20b2aa,
	lightskyblue = 0x87cefa,
	lightslategray = 0x778899,
	lightslategrey = 0x778899,
	lightsteelblue = 0xb0c4de,
	lightyellow = 0xffffe0,
	lime = 0x00ff00,
	limegreen = 0x32cd32,
	linen = 0xfaf0e6,
	magenta = 0xff00ff,
	maroon = 0x800000,
	mediumaquamarine = 0x66cdaa,
	mediumblue = 0x0000cd,
	mediumorchid = 0xba55d3,
	mediumpurple = 0x9370d8,
	mediumseagreen = 0x3cb371,
	mediumslateblue = 0x7b68ee,
	mediumspringgreen = 0x00fa9a,
	mediumturquoise = 0x48d1cc,
	mediumvioletred = 0xc71585,
	midnightblue = 0x191970,
	mintcream = 0xf5fffa,
	mistyrose = 0xffe4e1,
	moccasin = 0xffe4b5,
	navajowhite = 0xffdead,
	navy = 0x000080,
	oldlace = 0xfdf5e6,
	olive = 0x808000,
	olivedrab = 0x6b8e23,
	orange = 0xffa500,
	orangered = 0xff4500,
	orchid = 0xda70d6,
	palegoldenrod = 0xeee8aa,
	palegreen = 0x98fb98,
	paleturquoise = 0xafeeee,
	palevioletred = 0xd87093,
	papayawhip = 0xffefd5,
	peachpuff = 0xffdab9,
	peru = 0xcd853f,
	pink = 0xffc0cb,
	plum = 0xdda0dd,
	powderblue = 0xb0e0e6,
	purple = 0x800080,
	red = 0xff0000,
	rosybrown = 0xbc8f8f,
	royalblue = 0x4169e1,
	saddlebrown = 0x8b4513,
	salmon = 0xfa8072,
	sandybrown = 0xf4a460,
	seagreen = 0x2e8b57,
	seashell = 0xfff5ee,
	sienna = 0xa0522d,
	silver = 0xc0c0c0,
	skyblue = 0x87ceeb,
	slateblue = 0x6a5acd,
	slategray = 0x708090,
	slategrey = 0x708090,
	snow = 0xfffafa,
	springgreen = 0x00ff7f,
	steelblue = 0x4682b4,
	tan = 0xd2b48c,
	teal = 0x008080,
	thistle = 0xd8bfd8,
	tomato = 0xff6347,
	turquoise = 0x40e0d0,
	violet = 0xee82ee,
	wheat = 0xf5deb3,
	white = 0xffffff,
	whitesmoke = 0xf5f5f5,
	yellow = 0xffff00,
	yellowgreen = 0x9acd32
}

local function colorCallback(color)
	if type(color) == "string" then
		color:lower()
		if colors[color] then
			color = colors[color]
		end
	end
	return color
end

overRideMethod(TextField, "setTextColor", 2, colorCallback)
overRideMethod(Application, "setBackgroundColor", 2, colorCallback)
overRideMethod(Shape, "setFillStyle", 3, colorCallback)
overRideMethod(Shape, "setLineStyle", 3, colorCallback)