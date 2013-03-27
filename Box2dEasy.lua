--[[
	PHYSICS EXTENSIONS
]]--

function loadPhysicsExtension()

	--implementing vectors
	b2.Vect = Core.class()
	
	--create new vector from 2 points (A starting point and B ending point)
	function b2.Vect:init(startX, startY, endX, endY)
		self.startX = startX
		self.startY = startY
		self.endX = endX
		self.endY = endY
		self.xVect = startX - endX
		self.yVect = startY - endY
	end
	
	--get vector on x axis
	function b2.Vect:getX()
		return self.xVect
	end
	
	--get vector on y axis
	function b2.Vect:getY()
		return self.yVect
	end
	
	--get the length of the vector (distance between A and B points)
	function b2.Vect:getLength()
		if not self.length then
			self.length = math.sqrt(self.xVect*self.xVect + self.yVect*self.yVect)
		end
		return self.length
	end
	
	--get the angle of vector (angle for AB line, when up is 0 radians)
	function b2.Vect:getAngle()
		if not self.angle then
			self.angle = math.acos(self.yVect/(self:getLength()))
	
			if(self.xVect > 0) then
				self.angle = -self.angle
			end
		end
		return self.angle
	end
	
	--get point on AB vector with provided distance from point A
	function b2.Vect:getPoint(fromDistance)
		local ratio = math.sqrt((fromDistance*fromDistance)/(self.xVect*self.xVect + self.yVect*self.yVect))
		local endX = self.startX + self.xVect*ratio
		local endY = self.startY + self.yVect*ratio
		return endX, endY
	end
	
	b2.World._new = b2.World.new
	
	function b2.World.new(...)
		local world = b2.World._new(...)
		world.sprites = {}
		world.curSprite = 1
		world.beginCallbacks = {}
		world.endCallbacks = {}
		world:addEventListener(Event.BEGIN_CONTACT, world._handleBeginContact, world)
		world:addEventListener(Event.END_CONTACT, world._handleEndContact, world)
		return world
	end
	
	function b2.World:_handleBeginContact(e)
		--getting contact bodies
		local fixtureA = e.fixtureA
		local fixtureB = e.fixtureB
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()
		
		local collisionHandler
		if self.beginCallbacks[bodyA] and self.beginCallbacks[bodyA][bodyB] then
			collisionHandler = self.beginCallbacks[bodyA][bodyB]
			object1 = bodyA.object
			object2 = bodyB.object
		elseif self.beginCallbacks[bodyB] and self.beginCallbacks[bodyB][bodyA] then
			collisionHandler = self.beginCallbacks[bodyB][bodyA]
			object1 = bodyB.object
			object2 = bodyA.object
		end
		
		if collisionHandler then
			if collisionHandler.data then
				collisionHandler.callback(collisionHandler.data, object1, object2, e)
			else
				collisionHandler.callback(object1, object2, e)
			end
		end
	end
	
	function b2.World:_handleEndContact(e)
		--getting contact bodies
		local fixtureA = e.fixtureA
		local fixtureB = e.fixtureB
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()
		
		local collisionHandler, object1, object2
		if self.endCallbacks[bodyA] and self.endCallbacks[bodyA][bodyB] then
			collisionHandler = self.endCallbacks[bodyA][bodyB]
			object1 = bodyA.object
			object2 = bodyB.object
		elseif self.endCallbacks[bodyB] and self.endCallbacks[bodyB][bodyA] then
			collisionHandler = self.endCallbacks[bodyB][bodyA]
			object1 = bodyB.object
			object2 = bodyA.object
		end
		
		if collisionHandler then
			if collisionHandler.data then
				collisionHandler.callback(collisionHandler.data, object1, object2, e)
			else
				collisionHandler.callback(object1, object2, e)
			end
		end
	end
	
	function b2.World:addBeginContact(object1, object2, callback, data)
		local body1 = object1.body
		local body2 = object2.body
		if not self.beginCallbacks[body1] then
			self.beginCallbacks[body1] = {}
		end
		if not self.beginCallbacks[body1][body2] then
			self.beginCallbacks[body1][body2] = {}
		end
		local t = {}
		t.callback = callback
		if data then
			t.data = data
		end
		self.beginCallbacks[body1][body2] = t
		return self
	end
	
	function b2.World:addEndContact(object1, object2, callback, data)
		local body1 = object1.body
		local body2 = object2.body
		if not self.endCallbacks[body1] then
			self.endCallbacks[body1] = {}
		end
		if not self.endCallbacks[body1][body2] then
			self.endCallbacks[body1][body2] = {}
		end
		local t = {}
		t.callback = callback
		if data then
			t.data = data
		end
		self.endCallbacks[body1][body2] = t
		return self
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
		return self
	end
	
	function b2.World:undoDraggable(object)
		-- register for mouse events
		object:removeEventListener(Event.TOUCHES_BEGIN, object.onDragStart, self)
		object:removeEventListener(Event.TOUCHES_MOVE, object.onDragMove, self)
		object:removeEventListener(Event.TOUCHES_END, object.onDragEnd, self)
		object.onDragStart = nil
		object.onDragMove = nil
		object.onDragEnd = nil
		return self
	end
	
	function b2.World:__enchanceObject(object)
		--local body = object.body
		for k,v in pairs(b2.Body) do
			if type(v) == "function" and not object[k] then
				if (k:sub(1, 3) == "set" or k:sub(1, 5) == "apply" or k:sub(1, 7) == "destroy") then
					object[k] = function(self, ...)
						object.body[k](object.body, ...)
						return self
					end
				else
					object[k] = function(self, ...)
						return object.body[k](object.body, ...)
					end
				end
			end
		end
		for k,v in pairs(b2.Fixture) do
			if type(v) == "function" and not object[k] then
				if (k:sub(1, 3) == "set" or k:sub(1, 5) == "apply" or k:sub(1, 7) == "destroy") then
					object[k] = function(self, ...)
						object.body[k](object.body, ...)
						return self
					end
				else
					object[k] = function(self, ...)
						return object.body[k](object.body, ...)
					end
				end
			end
		end
	end
	
	function b2.World:createRectangle(object, config)
		
		local conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			restitution = 0.2,
			update = true,
			draggable = false,
			width = nil,
			height = nil,
			isSensor = false
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				conf[key]= value
			end
		end
		
		if object and conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		
		local angle
		if object then
			angle = object:getRotation()
			object:setRotation(0)
		end
		
		local width = conf.width or object:getWidth()
		local height = conf.height or object:getHeight()
		
		local poly = b2.PolygonShape.new()
		poly:setAsBox(width/2, height/2)
		
		local fixture = body:createFixture{shape = poly, density = conf.density, 
		friction = conf.friction, restitution = conf.restitution, isSensor = conf.isSensor}
		
		if object then
			object:setAnchorPoint(0.5, 0.5)
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(angle))
			object.body = body
			body.object = object
			if conf.type == "dynamic" and conf.draggable then
				self:makeDraggable(object)
			end
			object:setRotation(angle)
			self:__enchanceObject(object)
		end
		
		body.userdata = {}
		body.joints = {}
		
		return self
	end
	
	function b2.World:createCircle(object, config)
		
		local conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			restitution = 0.2,
			update = true,
			draggable = false,
			radius = nil,
			isSensor = false
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				conf[key]= value
			end
		end
		
		if object and conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		local angle
		if object then
			angle = object:getRotation()
			object:setRotation(0)
		end
		
		local radius = conf.radius or object:getWidth()/2
		
		local circle = b2.CircleShape.new(0, 0, radius)
		
		local fixture = body:createFixture{shape = circle, density = conf.density, 
		friction = conf.friction, restitution = conf.restitution, isSensor = conf.isSensor}
		
		if object then
			object:setAnchorPoint(0.5, 0.5)
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(angle))
			object.body = body
			body.object = object
			if conf.type == "dynamic" and conf.draggable then
				self:makeDraggable(object)
			end
			object:setRotation(angle)
			self:__enchanceObject(object)
		end
		
		body.userdata = {}
		body.joints = {}
		
		return self
	end
	
	--[[function b2.World:createRoundRectangle(object, width, height, radius, config)
		
		local conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			restitution = 0.2,
			update = true,
			draggable = false,
			isSensor = false
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				conf[key]= value
			end
		end
		
		if object and conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		
		local poly = b2.PolygonShape.new()
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
		poly:set(unpack(vertices))
		
		local fixture = body:createFixture{shape = chain, density = conf.density, 
		friction = conf.friction, restitution = conf.restitution, isSensor = conf.isSensor}
		
		if object then
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(object:getRotation()))
			object.body = body
			body.object = object
			if conf.type == "dynamic" and conf.draggable then
				self:makeDraggable(object)
			end
			self:__enchanceObject(object)
		end
		
		body.userdata = {}
		body.joints = {}
		
		return self
		
	end]]
	
	function b2.World:createTerrain(object, vertices, config)
		
		local conf = {
			type = "static",
			density = 1.0,
			friction = 1.0,
			restitution = 0.2,
			update = true,
			draggable = false,
			isSensor = false
		}
		
		if config then
			--copying configuration
			for key,value in pairs(config) do
				conf[key]= value
			end
		end
		
		if object and conf.update then
			object.id = self.curSprite
			self.sprites[object.id] = object
			self.curSprite = self.curSprite + 1
		end
		
		local setType = b2.STATIC_BODY
		if conf.type == "dynamic" then
			setType = b2.DYNAMIC_BODY
		elseif conf.type == "kinematic" then
			setType = b2.KINEMATIC_BODY
		end
		
		--create box2d physical object
		local body = self:createBody{type = setType}
		
		local chain = b2.ChainShape.new()
		chain:createChain(unpack(vertices))
		
		local fixture = body:createFixture{shape = chain, density = conf.density, 
		friction = conf.friction, restitution = conf.restitution, isSensor = conf.isSensor}
		
		if object then
			body:setPosition(object:getX(), object:getY())
			body:setAngle(math.rad(object:getRotation()))
			object.body = body
			body.object = object
			if conf.type == "dynamic" and conf.draggable then
				self:makeDraggable(object)
			end
			self:__enchanceObject(object)
		end
		
		body.userdata = {}
		body.joints = {}
		
		return self
		
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
		return self
	end
	
	function b2.World:getDebug()
		--set up debug drawing
		local debugDraw = b2.DebugDraw.new()
		debugDraw:setFlags(b2.DebugDraw.SHAPE_BIT + b2.DebugDraw.JOINT_BIT)
		self:setDebugDraw(debugDraw)
		return debugDraw
	end
	
	function b2.World:removeBody(object, destroy)
		if object.body then
			if object.id then
				self.sprites[object.id] = nil
			end
			Timer.delayedCall(1, function()
				self:destroyBody(object.body)
			end)
			object.body = nil
			if destroy then
				object:removeFromParent()
			end
		end
		return self
	end
	
	function b2.Body:setData(key, value)
		self.userdata[key] = value
		return self
	end
	
	function b2.Body:getData(key)
		return self.userdata[key]
	end
end

--[[ catching the load of box2d ]]--

local _require = require
require = function(name)
	local answer = _require(name)
	if name == "box2d" then
		-- load box2d extensions
		loadPhysicsExtension()
		require = _require
	end
	return answer
end
