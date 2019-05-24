-- Helpers
local function groupGetX(group, anchor, container)
  return group.object:getX(anchor, container)
end


local function groupGetY(group, anchor, container)
  return group.object:getY(anchor, container)
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Entity --
-- ---------------------------------------------------------------------------------------------------------------------
local Entity = Class("entity")
Entity.anchorX    = .5
Entity.anchorY    = .5
Entity._direction = 1

local objects = {}
function Entity:initialize(parent, x, y)
  self.group = display.newGroup()
  self.group.object = self
  self.group.getX = groupGetX
  self.group.getY = groupGetY
  if parent then parent:insert(self.group) end
  if x then self:setPosition(x, y) end

  objects[#objects+1] = self

  if self._direction == -1 then
    self:faceLeft()
  end

  self.id = _G.generateID(self.class.name)
end

-- Basics --------------------------------------------------------------------------------------------------------------

function Entity:getParent()
  return self.group.parent
end


function Entity:setPosition(x, y, params)
  if params then
    params.tag = params.tag or self.id
    params.x   = x or self.group.x
    params.y   = y or self.group.y
    transition.to(self.group, params)
  else
    self.group.x, self.group.y = x or self.group.x, y or self.group.y
  end
end


function Entity:move(x, y, params)
  if params then
    params.tag = params.tag or self.id
    params.x   = self.group.x + x
    params.y   = self.group.y + y
    transition.to(self.group, params)
  else
    self.group.x, self.group.y = self.group.x + x, self.group.y + y
  end
end


function Entity:faceLeft()
  self._direction = -1
  self.group.xScale = -1*math.abs(self.group.xScale)
end


function Entity:faceRight()
  self._direction = 1
  self.group.xScale = 1*math.abs(self.group.xScale)
end


function Entity:getX(anchorX, container)
  local x, _ = self:getPosition(anchorX, nil, container)

  return x
end


function Entity:getY(anchorY, container)
  local _, y = self:getPosition(nil, anchorY, container)

  return y
end


function Entity:getPosition(anchorX, anchorY, container)
  local x, y = self.group:localToContent(self:getInnerPoint(anchorX, anchorY))
  local x2, y2

  if container then
    x2, y2 = (container.group or container):contentToLocal(x, y)
  end

  return x2 or x, y2 or y
end


function Entity:worldToLocal(x, y)
  local selfX, selfY = self:getPosition()

  return x-selfX, y-selfY
end


function Entity:distanceTo(worldX, worldY, selfX, selfY)
  local selfX, selfY = selfX or 0, selfY or 0

  local dX, dY = self:wolrdToLocal(worldX, worldY)
  dX, dY = dX-(selfX or 0), dY-(selfY or 0)

  return math.sqrt(dX*dX+dY*dY)
end


function Entity:getInnerPoint(anchorX, anchorY)
  return anchorX and (anchorX - self:getAnchorX())*self:getWidth() or 0, anchorY and (anchorY - self:getAnchorY())*self:getHeight() or 0
end


function Entity:rotate(angle)
  self.group.rotation = angle
end


function Entity:getRotation()
  local r = 0
  local obj = self.group
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


function Entity:getScale()
  local scale = 1
  local group = self.group.parent
  local c = 0
  while group do
    c = c+1
    scale = scale*group.xScale
    group = group.parent
  end
  return scale
end


function Entity:getWidth()
  return self.width or self.group.width
end


function Entity:getHeight()
  return self.height or self.group.height
end


function Entity:getAnchorX()
  return self.anchorX or self.group.anchorX
end


function Entity:getAnchorY()
  return self.anchorY or self.group.anchorY
end


function Entity:setVisibility(alpha, params)
  if params then
    params.tag   = params.tag or self.id
    params.alpha = alpha
    transition.to(self.group, params)
  else
    self.group.alpha = alpha
  end
end


function Entity:isVisible()
  return self.group.isVisible and self.group.alpha > 0
end


function Entity:scale(scale, params)
  if params then
    params.tag   = params.tag or self.id
    params.xScale = scale
    params.yScale = scale
    transition.to(self.group, params)
  else
    self.group.xScale, self.group.yScale = scale*self._direction, scale
  end
end


function Entity:toFront()
  self.group:toFront()
end


function Entity:toBack()
  self.group:toBack()
end


function Entity:getFocus(touchID)
  display.getCurrentStage():setFocus(self.group, touchID)
end


function Entity:releaseFocus(touchID)
  display.getCurrentStage():setFocus(touchID and self.group or nil, nil)
end


-- Flow ----------------------------------------------------------------------------------------------------------------

function Entity:resume()
  if not self._paused then return end
  transition.resume(self.id)
  self._paused = false
end


function Entity:pause()
  if self._paused then return end
  transition.pause(self.id)
  self._paused = true
end

function Entity:stop()
  transition.cancel(self.id)
end


function Entity:clear()
  self:setVisibility(0)
  self:stop()

  if   self.dispose then self:dispose()
  else self:remove()
  end
end


function Entity:remove()
  self:stop()
  self.group:removeSelf()
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
