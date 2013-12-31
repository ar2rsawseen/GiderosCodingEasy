--[[
       SOME GLOBAL SETTINGS
]]--
local sets = {
	tapTime = 0.2,
	tapLongTime = 0.5,
	tapDisperse = 50,
	swipeDistance = 100,
	swipeDisperse = 50
}

--[[
        EVENT NAMES
]]--
Event.SINGLE_TAP = "singleTap"
Event.DOUBLE_TAP = "doubleTap"
Event.TRIPLE_TAP = "tripleTap"
Event.LONG_TAP = "longTap"
Event.SWIPE_DOWN = "swipeDown"
Event.SWIPE_UP = "swipeUp"
Event.SWIPE_LEFT = "swipeLeft"
Event.SWIPE_RIGHT = "swipeRight"
Event.DRAG_START = "dragStart"
Event.DRAG_MOVE = "dragMove"
Event.DRAG_END = "dragEnd"

--[[
        SUBSCRIPTIONS TO EVENTS
]]--
local events = {}
events[Event.SINGLE_TAP] = {}
events[Event.DOUBLE_TAP] = {}
events[Event.TRIPLE_TAP] = {}
events[Event.LONG_TAP] = {}
events[Event.SWIPE_DOWN] = {}
events[Event.SWIPE_UP] = {}
events[Event.SWIPE_LEFT] = {}
events[Event.SWIPE_RIGHT] = {}

EventDispatcher._GEEaddEventListener = EventDispatcher.addEventListener
function EventDispatcher:addEventListener(type, listener, data)
	if string.find(type, "Tap") ~= nil or string.find(type, "swipe") ~= nil then
		events[type][self] = true
	end
	self:_GEEaddEventListener(type, listener, data)
	return self
end

EventDispatcher._GEEremoveEventListener = EventDispatcher.removeEventListener
function EventDispatcher:removeEventListener(type, listener, data)
	if string.find(string.lower(type), "tap") ~= nil or string.find(string.lower(type), "swipe") ~= nil then
		events[type][self] = nil
	end
	self:_GEEremoveEventListener(type, listener, data)
	return self
end

--[[
		TAP AND SWIPE EVENTS
]]--

local touches = {}
local startTime = 0
local tapCount = 0
local resetCount
stage:addEventListener(Event.TOUCHES_BEGIN, function(e)
	if startTime == 0 then
		startTime = os.timer()
		touches[e.touch.id] = {}
		touches[e.touch.id].x = e.touch.x
		touches[e.touch.id].y = e.touch.y
		touches[e.touch.id].count = #e.allTouches
	end
end)

stage:addEventListener(Event.TOUCHES_MOVE, function(e)
	
end)

stage:addEventListener(Event.TOUCHES_END, function(e)
	if touches[e.touch.id] then --if touch is defined
		if math.abs(e.touch.x - touches[e.touch.id].x) <= sets.tapDisperse and
			math.abs(e.touch.y - touches[e.touch.id].y) <= sets.tapDisperse then
			--can be a tap event
			
			--calculate minimum touching fingers
			e.touchCount = math.min(#e.allTouches, touches[e.touch.id].count)
			if os.timer() - startTime <= sets.tapTime then
				if resetCount then
					resetCount:stop()
					resetCount = nil
				end
				tapCount = tapCount + 1
				if tapCount == 1 then
					dispatchTapEvent(Event.SINGLE_TAP, e)
					resetCount = Timer.delayedCall(sets.tapTime*1000, ressetTapCount)
				elseif tapCount == 2 then
					dispatchTapEvent(Event.DOUBLE_TAP, e)
					resetCount = Timer.delayedCall(sets.tapTime*1000, ressetTapCount)
				else
					dispatchTapEvent(Event.TRIPLE_TAP, e)
					tapCount = 0
				end
			else
				tapCount = 0
				if os.timer() - startTime >= sets.tapLongTime then
					dispatchTapEvent(Event.LONG_TAP, e)
				end
			end
		else
			--can be a swipe event
			if math.abs(e.touch.x - touches[e.touch.id].x) <= sets.swipeDisperse and
				math.abs(e.touch.y - touches[e.touch.id].y) > sets.swipeDistance then --vertical
				e.swipeDistance = e.touch.y - touches[e.touch.id].y
				if e.touch.y - touches[e.touch.id].y > 0 then --down
					dispatchSwipeEvent(Event.SWIPE_DOWN, e)
				else --up
					dispatchSwipeEvent(Event.SWIPE_UP, e)
				end
			elseif math.abs(e.touch.x - touches[e.touch.id].x) > sets.swipeDistance and
				math.abs(e.touch.y - touches[e.touch.id].y) <= sets.swipeDisperse then --horizontal
				e.swipeDistance = e.touch.x - touches[e.touch.id].x
				if e.touch.x - touches[e.touch.id].x > 0 then --right
					dispatchSwipeEvent(Event.SWIPE_RIGHT, e)
				else --left
					dispatchSwipeEvent(Event.SWIPE_LEFT, e)
				end
			end
		end
		touches[e.touch.id] = nil
		startTime = 0
	end
end)

function ressetTapCount()
	tapCount = 0
	resetCount = nil
end

function dispatchTapEvent(event, e)
	for i, val in pairs(events[event]) do
		if i:hitTestPoint(e.touch.x, e.touch.y) then
			local event = Event.new(event)
			event.x = e.touch.x
			event.y = e.touch.y
			if e.touchCount then
				event.touchCount = e.touchCount
			end
			i:dispatchEvent(event)
		end
	end
end

function dispatchSwipeEvent(event, e)
	for i, val in pairs(events[event]) do
		if i:hitTestPoint(e.touch.x, e.touch.y) then
			local event = Event.new(event)
			if e.swipeDistance then
				event.swipeDistance = e.swipeDistance
			end
			i:dispatchEvent(event)
		end
	end
end

--[[
		DRAGGING EVENTS
]]--

function Sprite:setDragging(state)
	if self._draggingState and not state then
		self:removeEventListener(Event.MOUSE_DOWN, self._dragStart, self)
		self:removeEventListener(Event.MOUSE_MOVE, self._dragMove, self)
		self:removeEventListener(Event.MOUSE_UP, self._dragEnd, self)
	elseif not self._draggingState and state then
		self:addEventListener(Event.MOUSE_DOWN, self._dragStart, self)
		self:addEventListener(Event.MOUSE_MOVE, self._dragMove, self)
		self:addEventListener(Event.MOUSE_UP, self._dragEnd, self)
	end
end

function Sprite:_dragStart(e)
	if self:hitTestPoint(e.x, e.y) then
		local event = Event.new(Event.DRAG_START)
		event.x = e.x
		event.y = e.y
		self:dispatchEvent(event)
		self._isDragging = true
		self._dragX = self:getX() - e.x
		self._dragY = self:getY() - e.y
	end
end

function Sprite:_dragMove(e)
	if self._isDragging then
		self:setX(e.x + self._dragX)
		self:setY(e.y + self._dragY)
		local event = Event.new(Event.DRAG_MOVE)
		event.x = e.x
		event.y = e.y
		self:dispatchEvent(event)
	end
end

function Sprite:_dragEnd(e)
	if self._isDragging then
		local event = Event.new(Event.DRAG_END)
		event.x = e.x
		event.y = e.y
		self:dispatchEvent(event)
		self._isDragging = false
	end
end
