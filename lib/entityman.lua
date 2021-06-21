local em = {
  deep = deeper.init()
}

function em.init(en,x,y,kvtable)
  local path = "obj/" .. en .. ".lua" --todo fix this
  local code = love.filesystem.load(path)
  local new = code()
  if not kvtable then kvtable = {} end
  new.x = x
  new.y = y
  for k,v in pairs(kvtable) do
    new[k] = v
  end
  new.name = en
  table.insert(entities,new)

  return entities[#entities]
end


function em.update(dt)
  
  for i,v in ipairs(entities) do
    if not paused then
      em.deep.queue(v.uplayer, em.update2, v, dt)
    elseif v.runonpause then
      em.deep.queue(v.uplayer, em.update2, v, dt)
    end
  end
  em.deep.execute() -- OH MY FUCKING GOD IM SUCH A DINGUS
end


function em.draw()
  for i, v in ipairs(entities) do
    if not v.skiprender then
      em.deep.queue(v.layer, v.draw)
    end
  end
  em.deep.execute()
  for i,v in ipairs(entities) do
    if v.delete then
      table.remove(entities, i)
    end
  end
end


function em.update2(v,dt)
  v.update(dt)
end


return em