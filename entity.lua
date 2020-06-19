local middleclass = {
  _VERSION     = 'Entity v1.0.0',
  _DESCRIPTION = 'A basic entity class designed for Solar2D',
  _URL         = 'https://github.com/depilz/corona-entity',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2020 Denis Claros Pilz

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

-- Helpers
local function groupGetX(group, anchor, world)
 return group.object:getX(anchor, world)
end


local function groupGetY(group, anchor, world)
 return group.object:getY(anchor, world)
end


local idCounter = 0
local generateID = function(object)
 idCounter = idCounter+1
 return object.."_"..idCounter
end


-- ---------------------------------------------------------------------------------------------------------------------
-- Entity --
-- ---------------------------------------------------------------------------------------------------------------------
local Entity = Class("entity")
Entity._direction = 1
Entity.anchorX    = .5
Entity.anchorY    = .5

function Entity:initialize(parent, x, y)
 self.group = display.newGroup()
 self.group.object = self
 self.group.getX = groupGetX
 self.group.getY = groupGetY
 if parent then parent:insert(self.group) end
 if x then self:setPosition(x, y) end

 self.id = generateID(self.class.name)

 self._transitions = {}
end


function Entity:init()
 if self._initialized then return false end

 self:hardReset()
 self._initialized = true

 return true
end


-- Basics --------------------------------------------------------------------------------------------------------------

function Entity:getParent()
 return self.group.parent
end


function Entity:setPosition(x, y, params)
 if params then
   params.x   = x or self.group.x
   params.y   = y or self.group.y

   self:transitionTo(params)

 else
   self.group.x, self.group.y = x or self.group.x, y or self.group.y

 end
end


function Entity:move(x, y, params)
 if params then
   params.x   = x and self.group.x + x
   params.y   = y and self.group.y + y
   self:transitionTo(params)
 else
   self.group.x, self.group.y = self.group.x + (x or 0), self.group.y + (y or 0)
 end
end


function Entity:getX(anchorX, world)
 local x, _ = self:getPosition(anchorX, nil, world)

 return x
end


function Entity:getY(anchorY, world)
 local _, y = self:getPosition(nil, anchorY, world)

 return y
end


function Entity:getPosition(anchorX, anchorY, world)
 assert(self.group.y, (tostring(self) or "UNKNOWN")..": operation over a removed object")

 local x, y = self.group:localToContent(self:getInnerPoint(anchorX, anchorY))
 if world then
   return (world.group or world):contentToLocal(x, y)
 else
   return x, y
 end
end


function Entity:worldToLocal(x, y, world)
 x, y = x or 0, y or 0

 if world then
   x, y = world:localToContent(x, y)
 end

 return (self.group or self):contentToLocal(x, y)
end


function Entity:localToWorld(x, y, world)
 x, y = x or 0, y or 0
 x, y = (self.group or self):localToContent(x, y)

 if world then
   x, y = world:contentToLocal(x, y)
 end

 return x, y
end


function Entity:localToContent(x, y)
 return self.group:localToContent(x or 0, y or 0)
end


function Entity:contentToLocal(x, y)
 return self.group:contentToLocal(x or 0, y or 0)
end


function Entity:relocate(group)
 self:setPosition(self:localToWorld(0, 0, group))
 group:insert(self.group)
end


function Entity:distanceTo(worldX, worldY, selfX, selfY)
 local selfX, selfY = selfX or 0, selfY or 0

 local dX, dY = self:worldToLocal(worldX, worldY)
 dX, dY = dX-(selfX or 0), dY-(selfY or 0)

 return math.hypotenuse(dX,dY)
end


function Entity:getWidth()
 return self.width or self.group.width
end


function Entity:getHeight()
 return self.height or self.group.height
end




function Entity:getInnerPoint(anchorX, anchorY)
 return anchorX and self.group.xScale*(anchorX-self:getAnchorX())*self:getWidth()  or 0,
        anchorY and self.group.yScale*(anchorY-self:getAnchorY())*self:getHeight() or 0
end


function Entity:getAnchorX()
 local anchor = self.anchorX or self.group.anchorX
 return self._direction == 1 and anchor or 1 - anchor
end


function Entity:getAnchorY()
 return self.anchorY and 1 - self.anchorY or self.group.anchorY
end


function Entity:vanish(params)
 local params = params or {}

 params.time       = params.time or 800
 params.transition = params.transition or easing.outQuad

 self:setVisibility(0, params)
end


function Entity:setVisibility(alpha, params)
 if params then
   params.alpha = alpha
   self:transitionTo(params)
 elseif type(alpha) == "boolean" then
   self.group.isVisible = alpha
 else
   self.group.alpha = alpha
 end
end


function Entity:isVisible()
 return self.group.isVisible and self.group.alpha > 0
end


function Entity:rotate(angle)
 self.group.rotation = angle
end


function Entity:getRotation()
 local r = 0
 local obj = self.group or self
 while obj do
   r = r +obj.rotation
   obj = obj.parent
 end
 return r
end


function Entity:getXScale()
 local s = 1
 local obj = self.group
 while obj do
   s = s*obj.xScale
   obj = obj.parent
 end
 return s
end


function Entity:getYScale()
 local s = 1
 local obj = self.group
 while obj do
   s = s*obj.yScale
   obj = obj.parent
 end
 return s
end


function Entity:setScale(scale, params)
  if params then
    params.tag   = params.tag or self.id
    params.xScale = scale
    params.yScale = scale
    transition.to(self.group, params)
  else
    self.group.xScale, self.group.yScale = scale*self._direction, scale
  end
end


function Entity:setXScale(scale)
 if scale < 0 then self._direction = -1; scale = math.abs(scale) end
 self.group.xScale = scale*self._direction
 self.width  = self.class.width*scale
end


function Entity:setYScale(scale)
 self.group.yScale = scale
 self.height = self.class.height*scale
end


function Entity:getDirection()
 return self._direction
end


function Entity:faceLeft()
 self:setDirection(-1)
end


function Entity:faceRight()
 self:setDirection(1)
end


function Entity:setDirection(direction)
 self._direction = direction
 self.group.xScale = direction*math.abs(self.group.xScale)
end


function Entity:toFront()
 self.group:toFront()
end


function Entity:toBack()
 self.group:toBack()
end


function Entity:getFocus(object, touchID)
 display.getCurrentStage():setFocus(object or self.group)
end


function Entity:releaseFocus(touchID)
 display.getCurrentStage():setFocus(touchID and self.group or nil, nil)
end


function Entity:playSound(sound, params)
 if self.__sfx[sound] then
   return SoundPlayer.playSound(self.__sfx[sound][math.random(#self.__sfx[sound])], params)
 end
end


function Entity:_stopSound(channel)
 return SoundPlayer.stop(channel)
end


-- Transitions ---------------------------------------------------------------------------------------------------------

function Entity:transitionTo(params, tag)
 params.tag = self.id..(params.tag or tag or "")
 self._transitions[params.tag] = true
 transition.to(params.table or self.group, params)
end


function Entity:_cancelTransition(tag)
 assert(tag ~= nil, "Should specify a tag on Entity Cancel")
 transition.cancel(self.id..(tag or ""))
end


function Entity:performWithDelay(time, task)
 return timer.performWithDelay(time, task)
end


-- Object Flow ---------------------------------------------------------------------------------------------------------

function Entity:resume()
 if not self._paused then return end
 self._paused = false

 for k,v in pairs(self._transitions) do
   transition.resume(k)
 end
end


function Entity:pause()
 if self._paused then return end
 self._paused = true

 for k,v in pairs(self._transitions) do
   transition.pause(k)
 end
end


-- Interrupt: - Stops all the transitions and activities
--            - The entity stills initialized
function Entity:interrupt()
 for k,v in pairs(self._transitions) do
   transition.cancel(k)
 end
end


-- Stop: - Completely stops the entity
--       - Interrups any activity
--       - Interrups any activity
--       - The entity won't work again until a hard reset and a re-initialization
function Entity:stop()
 self._initialized = false
 self:interrupt()
end


-- Reset: - Bring the entity to a base state
--        - The entity remains initialized
function Entity:reset()

end


-- Hard reset: - Restore the entity as if it had never been initialized
--             - Set all the default values
--             - Completly stops the entity
--             - It's called at the begining of the entity init()
function Entity:hardReset()
 self:setVisibility(1)
 self._initialized = false
 self.group.isVisible = true
 self.group.alpha     = 1
 self.group.rotation  = 0
 self.group.xScale    = 1
 self.group.yScale    = 1

 self.group.direction = 1
 if self._direction == -1 then
   self:faceLeft()
 end

 self:reset()
end


function Entity:clear()
 self:stop()

 if self.dispose then self:dispose()
 else                 self:remove()
 end
end


function Entity:remove()
 self:stop()

 if self.group.removeSelf then
   self.group:removeSelf()
 end
end

-- EventDispatch -------------------------------------------------------------------------------------------------------

function Entity:addEventListener(...)
 self.group:addEventListener(...)
end


function Entity:removeEventListener(...)
 self.group:removeEventListener(...)
end


function Entity:dispatchEvent(...)
 self.group:dispatchEvent(...)
end


return Entity
