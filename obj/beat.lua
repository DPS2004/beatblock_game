local obj = {
  layer = -1,
  uplayer = 3,
  slice = false,
  x=screencenter.x,
  y=screencenter.y,
  angle=0,
  startangle=0,
  smult2=1,
  endangle=0,
  hb=0,
  movetime=0,
  smult=1,
  inverse = false,
  hityet = false,
  hold = false,
  mine = false,
  side = false,
  minehold = false,
  spr = sprites.beat.square,
  spr2 = sprites.beat.inverse,
  spr3 = sprites.beat.hold,
  spr4 = sprites.beat.mine,
  spr5 = sprites.beat.side,
  spr6 = sprites.beat.minehold
}
obj.ox = obj.x
obj.oy = obj.y


function obj.update(dt)
  if obj.inverse then
    obj.layer = 1
  end
  -- How long it takes to move from beat spawn to hitting the paddle
  if obj.movetime == 0 then
    obj.movetime = obj.hb - cs.cbeat
  end
  

  -- Progress is a number from 0 (spawn) to 1 (paddle)
  local progress = 1 - ((obj.hb - cs.cbeat) / obj.movetime)

  -- Interpolate angle between startangle and endangle based on progress. Beat should be at endangle when it hits the paddle.
  if (obj.hb - cs.cbeat) > 0 then --only clamp when moving towards point
    if obj.spinease == "linear" then
      obj.angle = helpers.clamp(helpers.lerp(obj.startangle, obj.endangle, progress), obj.startangle, obj.endangle) % 360
    elseif obj.spinease == "inExpo"  then
      --print(2 ^ (10 * (progress - 1)))
      obj.angle = helpers.clamp(helpers.lerp(obj.startangle, obj.endangle, 2 ^ (10 * (progress - 1))), obj.startangle, obj.endangle) % 360
    end
  end
  
  local p1 = nil
  local p2 = nil
  
  if obj.inverse then
    p1 = helpers.rotate(((obj.hb - cs.cbeat)*cs.level.properties.speed*obj.smult*-1)+cs.extend+cs.length-24,obj.angle,obj.ox,obj.oy)
  elseif obj.side then
    p1 = helpers.rotate((obj.hb - cs.cbeat)*cs.level.properties.speed*obj.smult+cs.extend+cs.length-10,obj.angle,obj.ox,obj.oy)
  elseif not obj.hold and not obj.minehold then
    p1 = helpers.rotate((obj.hb - cs.cbeat)*cs.level.properties.speed*obj.smult+cs.extend+cs.length,obj.angle,obj.ox,obj.oy)
  elseif obj.hold or obj.minehold then
    p1 = helpers.rotate((obj.hb - cs.cbeat)*cs.level.properties.speed*obj.smult+cs.extend+cs.length,obj.angle,obj.ox,obj.oy)
    p2 = helpers.rotate((obj.hb - cs.cbeat+obj.duration)*cs.level.properties.speed*obj.smult*obj.smult2+cs.extend+cs.length,obj.angle2,obj.ox,obj.oy)
    obj.x2 = p2[1]
    obj.y2 = p2[2]
    
  end
  obj.x = p1[1]
  obj.y = p1[2]  

  if (obj.hb - cs.cbeat) <= 0 and not obj.side then
    if not obj.mine then
      if not obj.hold and not obj.minehold then
        if helpers.angdistance(obj.angle,cs.p.angle) <= cs.p.paddle_size / 2 then 
          em.init("hitpart",obj.x,obj.y)
          obj.delete = true
          pq = pq .. "   player hit!"
          cs.hits = cs.hits + 1
          cs.combo = cs.combo + 1
          if cs.beatsounds then
            te.play(sounds.click,"static")
          end
          if cs.p.cemotion == "miss" then
            cs.p.emotimer = 0
            cs.p.cemotion = "idle"
          end
        else
          local mp = em.init("misspart",screencenter.x,screencenter.x)
          mp.angle = obj.angle
          mp.distance = (obj.hb - cs.cbeat)*cs.level.properties.speed+cs.length
          mp.spr = (obj.inverse and not obj.slice and obj.spr2) or (obj.spr) --Determine which sprite the misspart should use
          mp.update()
          obj.delete = true
          pq = pq .. "   player missed!"
          cs.misses = cs.misses + 1
          cs.combo = 0
          cs.p.emotimer = 100
          cs.p.cemotion = "miss"

          cs.p.hurtpulse()
        end
      elseif obj.hold then
        if helpers.angdistance(obj.angle,cs.p.angle) <= cs.p.paddle_size / 2 then 
          if obj.hityet == false then
            obj.hityet = true
            pq = pq .. "   started hitting hold"
            if cs.beatsounds then
            te.play(sounds.hold,"static")
            end
          end
          --em.init("hitpart",obj.x,obj.y)
          --print(helpers.angdistance(obj.angle,cs.p.angle).. " is less than " .. cs.p.paddle_size / 2)
          obj.angle = helpers.interpolate(obj.endangle,obj.angle2,((obj.hb - cs.cbeat)*-1)/obj.duration, obj.holdease)
          
          
          p1 = helpers.rotate(cs.extend+cs.length,obj.angle,obj.ox,obj.oy)
          p2 = helpers.rotate((obj.hb - cs.cbeat+obj.duration)*cs.level.properties.speed*obj.smult*obj.smult2+cs.extend+cs.length,obj.angle2,obj.ox,obj.oy)
          obj.x2 = p2[1]
          obj.y2 = p2[2]
          obj.x = p1[1]
          obj.y = p1[2]  
          
          if ((obj.hb - cs.cbeat)*-1)/obj.duration >= 1 then
            pq = pq .. "   finished hold!"
            cs.hits = cs.hits + 1
            cs.combo = cs.combo + 1
            if cs.beatsounds then
              te.play(sounds.click,"static")
            end
            if cs.p.cemotion == "miss" then
              cs.p.emotimer = 0
              cs.p.cemotion = "idle"
              
            end
            obj.delete = true
            em.init("hitpart",obj.x,obj.y)
          end
        else
          local mp = em.init("misspart",screencenter.x,screencenter.x)
          mp.angle = obj.angle
          mp.distance = (obj.hb - cs.cbeat)*cs.level.properties.speed+cs.length
          mp.spr = obj.spr3 --Set the miss part's sprite to that of a hold
          mp.update()
          obj.delete = true
          pq = pq .. "   player missed hold!"
          cs.misses = cs.misses + 1
          cs.combo = 0
          cs.p.emotimer = 100
          cs.p.cemotion = "miss"

          cs.p.hurtpulse()
        end

      --mine hold
      elseif obj.minehold then
        --avoiding mine hold
        if helpers.angdistance(obj.angle,cs.p.angle) >= cs.p.paddle_size / 2 then 
          if obj.hityet == false then
            obj.hityet = true
            pq = pq .. "   started mine hold"
          end
          --em.init("hitpart",obj.x,obj.y)
          --print(helpers.angdistance(obj.angle,cs.p.angle).. " is less than " .. cs.p.paddle_size / 2)
          obj.angle = helpers.interpolate(obj.endangle,obj.angle2,((obj.hb - cs.cbeat)*-1)/obj.duration, obj.holdease)
          
          
          p1 = helpers.rotate(cs.extend+cs.length,obj.angle,obj.ox,obj.oy)
          p2 = helpers.rotate((obj.hb - cs.cbeat+obj.duration)*cs.level.properties.speed*obj.smult*obj.smult2+cs.extend+cs.length,obj.angle2,obj.ox,obj.oy)
          obj.x2 = p2[1]
          obj.y2 = p2[2]
          obj.x = p1[1]
          obj.y = p1[2]  
          
          if ((obj.hb - cs.cbeat)*-1)/obj.duration >= 1 then
            pq = pq .. "   finished mine hold!"
            cs.hits = cs.hits + 1
            cs.combo = cs.combo + 1
            if cs.p.cemotion == "miss" then
              cs.p.emotimer = 0
              cs.p.cemotion = "idle"
              
            end
            obj.delete = true
            em.init("hitpart",obj.x,obj.y)
          end
        --failed mine hold
        else
          local mp = em.init("misspart",screencenter.x,screencenter.x)
          mp.angle = obj.angle
          mp.distance = (obj.hb - cs.cbeat)*cs.level.properties.speed+cs.length
          mp.spr = obj.spr6 --Set the miss part's sprite to that of a hold
          mp.update()
          obj.delete = true
          pq = pq .. "   player hit mine hold!"
          cs.misses = cs.misses + 1
          cs.combo = 0
          cs.p.emotimer = 100
          cs.p.cemotion = "miss"
          if cs.beatsounds then
            te.play(sounds.mine,"static")
          end

          cs.p.hurtpulse()
        end
      end

    elseif obj.mine then

      --mine
      if helpers.angdistance(obj.angle,cs.p.angle) <= cs.p.paddle_size / 2 then 
        -- mine is hit

        
        
        local mp = em.init("misspart",screencenter.x,screencenter.x)
        mp.angle = obj.angle
        mp.distance = (obj.hb - cs.cbeat)*cs.level.properties.speed+cs.length
        mp.spr = obj.spr4 --Determine which sprite the misspart should use
        mp.update()
        obj.delete = true
        pq = pq .. "   player hit mine!"
        cs.misses = cs.misses + 1
        cs.combo = 0
        cs.p.emotimer = 100
        cs.p.cemotion = "miss"
        if cs.beatsounds then
          te.play(sounds.mine,"static")
        end

        cs.p.hurtpulse()
      else
        em.init("hitpart",obj.x,obj.y)
        obj.delete = true
        pq = pq .. "   player missed mine!"
        cs.hits = cs.hits + 1
        cs.combo = cs.combo + 1
        if cs.p.cemotion == "miss" then
          cs.p.emotimer = 0
          cs.p.cemotion = "idle"
        end
      end
    end
  elseif obj.side then
    --side notes
    if helpers.angdistance(obj.angle,cs.p.angle) <= cs.p.paddle_size / 2 and helpers.angdistance(obj.angle,cs.p.angleprevframe) > cs.p.paddle_size / 2 and math.abs(obj.hb - cs.cbeat) <= 1/4 then
      em.init("hitpart",obj.x,obj.y)
      obj.delete = true
      pq = pq .. "   player hit!"
      cs.hits = cs.hits + 1
      cs.combo = cs.combo + 1
      if cs.beatsounds then
        te.play(sounds.click,"static")
      end
      if cs.p.cemotion == "miss" then
        cs.p.emotimer = 0
        cs.p.cemotion = "idle"
      end
    elseif obj.hb - cs.cbeat <= -1/4 then
      local mp = em.init("misspart",screencenter.x,screencenter.x)
      mp.angle = obj.angle
      mp.distance = (obj.hb - cs.cbeat)*cs.level.properties.speed+cs.length
      mp.spr = (obj.inverse and not obj.slice and obj.spr2) or (obj.spr5) --Determine which sprite the misspart should use
      mp.update()
      obj.delete = true
      pq = pq .. "   player missed!"
      cs.misses = cs.misses + 1
      cs.combo = 0
      cs.p.emotimer = 100
      cs.p.cemotion = "miss"
      cs.p.hurtpulse()
    elseif helpers.angdistance(obj.angle,cs.p.angle) <= cs.p.paddle_size / 2 and helpers.angdistance(obj.angle,cs.p.angleprevframe) <= cs.p.paddle_size / 2 and (obj.hb - cs.cbeat) <= 0 then
      local mp = em.init("misspart",screencenter.x,screencenter.x)
      mp.angle = obj.angle
      mp.distance = (obj.hb - cs.cbeat)*cs.level.properties.speed+cs.length
      mp.spr = (obj.inverse and not obj.slice and obj.spr2) or (obj.spr5) --Determine which sprite the misspart should use
      mp.update()
      obj.delete = true
      pq = pq .. "   player missed!"
      cs.misses = cs.misses + 1
      cs.combo = 0
      cs.p.emotimer = 100
      cs.p.cemotion = "miss"
      cs.p.hurtpulse()
      if cs.beatsounds then
        te.play(sounds.mine,"static")
      end
    end
  end

end

function obj.draw()  
  if not obj.slice then
    love.graphics.setColor(1,1,1,1)
    if not obj.hold and not obj.minehold then
      if obj.inverse then
        love.graphics.draw(obj.spr2,obj.x,obj.y,0,1,1,8,8)
      elseif obj.mine then
        love.graphics.draw(obj.spr4,obj.x,obj.y,0,1,1,8,8)
      elseif obj.side then
        love.graphics.draw(obj.spr5,obj.x,obj.y,math.rad(obj.angle),1,1,12,10)
      else
        love.graphics.draw(obj.spr,obj.x,obj.y,0,1,1,8,8)
      end
    elseif obj.hold then
      local completion = math.max(0, (cs.cbeat - obj.hb) / obj.duration)
      helpers.drawhold(obj.ox, obj.oy, obj.x, obj.y, obj.x2, obj.y2, completion, obj.angle1, obj.angle2, obj.segments, obj.spr3, obj.holdease, "hold")
    elseif obj.minehold then
      local completion = math.max(0, (cs.cbeat - obj.hb) / obj.duration)
      helpers.drawhold(obj.ox, obj.oy, obj.x, obj.y, obj.x2, obj.y2, completion, obj.angle1, obj.angle2, obj.segments, obj.spr6, obj.holdease, "minehold")
    end
  else
    obj.x, obj.y = helpers.drawslice(obj.ox, obj.oy, (obj.hb - cs.cbeat)*cs.level.properties.speed*obj.smult, obj.angle, obj.inverse, 1)
  end
end
return obj