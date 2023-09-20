Gamemanager = class('Gamemanager',Entity)

Event = {}
Event.onload = {}
Event.onoffset = {}
Event.onbeat = {}

local elist = love.filesystem.getDirectoryItems('levelformat/events/')
for i,v in ipairs(elist) do
	if v ~= '_TEMPLATE.lua' then
			local einfo, eonload, eonoffset, eonbeat = dofile('levelformat/events/'..v)
			local etype = ''
			if eonload then
				Event.onload[einfo.event] = eonload
				etype = etype .. ' onload'
			end
			if eonoffset then
				Event.onoffset[einfo.event] = eonoffset
				etype = etype .. ' onoffset'
			end
			if eonbeat then
				Event.onbeat[einfo.event] = eonbeat
				etype = etype .. ' onbeat'
			end
			
			print('loaded event "'..einfo.name..'" ('..einfo.event..etype..')')
	end
end

function Gamemanager:initialize(params)
	
	self.skiprender = true
	self.skipupdate = true
  self.layer = 1
  self.uplayer = -9999
  self.x=0
  self.y=0
  self.songfinished = false
	
  Entity.initialize(self,params)
	
	cs.p = em.init("player",{x=project.res.cx,y=project.res.cy})
end



function Gamemanager:resetlevel()
  cs.offset = cs.level.properties.offset
	cs.songoffset = 0
  cs.startbeat = cs.startbeat or project.startbeat or 0
  cs.cbeat = 0-cs.offset +cs.startbeat
  cs.autoplay = false
  cs.length = 42
  cs.pt = 0
  cs.bg = love.graphics.newImage("assets/bgs/nothing.png")  

  cs.misses= 0
  cs.hits = 0
  cs.combo = 0
  cs.maxhits = 0
	
	--deal with new level format
	cs.allevents = {}
	if cs.chart then
		for i,v in ipairs(cs.chart) do
			table.insert(cs.allevents,v)
		end
	end
	for i,v in ipairs(cs.level.events) do
		table.insert(cs.allevents,v)
	end
	--from now on cs.level.events should be cs.allevents
	
  for i,v in ipairs(cs.allevents) do
    if v.type == "beat" or v.type == "slice" or v.type == "sliceinvert" or v.type == "inverse" or v.type == "hold" or v.type == "mine" or v.type == "side" or v.type == "minehold" or v.type == "ringcw" or v.type == "ringccw" then
      cs.maxhits = cs.maxhits + 1
    end
  end

  cs.on = true

  cs.beatsounds = true
  cs.extend = 0
  for i,v in ipairs(cs.allevents) do
    v.played = false
    v.autoplayed = false
  end
  cs.vfx = {}
  cs.vfx.hom = false
  cs.vfx.bgnoise = {enable=false,image=love.graphics.newImage("assets/game/noise/0noiseatlas.png"),r=1,b=1,g=1}
  cs.lastsigbeat = math.floor(cs.cbeat)
	
	--onload pass
	print('running onload events...')
	local oltotal = 0
  for i,v in ipairs(cs.allevents) do
		if Event.onload[v.type] then
			if (not v.play_onload) then
				Event.onload[v.type](v)
				v.play_onload = true
				oltotal = oltotal + 1
			end
		end
	end
	print('ran ' .. oltotal .. ' events')
end

function Gamemanager:beattoms(beat,bpm) --you gotta Trust me that the numbers check out here
	bpm = bpm or cs.level.bpm
	return beat * (60000/bpm)
end

function Gamemanager:mstobeat(ms,bpm)
	bpm = bpm or cs.level.bpm
	return ms / (60000/bpm) 
end

function Gamemanager:gradecalc(pct) --idk where else to put this, but it shouldn't go into helpers because its so game specific.
  local lgrade = ""
  local lgradepm = ""
  
  if pct == 100 then
    lgrade = "s"
  elseif pct >= 90 then
    lgrade = "a"
  elseif pct >= 80 then
    lgrade = "b"
  elseif pct >= 70 then
    lgrade = "c"
  elseif pct >= 60 then
    lgrade = "d"
  else
    lgrade = "f"
  end
  lgradepm = "none"
  if lgrade ~= "s" and lgrade ~= "f" then
    if pct % 10 <= 3 then
      lgradepm = "minus"
    elseif pct % 10 >= 7 then
      lgradepm = "plus"
    end
  end
  return lgrade, lgradepm
end


function Gamemanager:update(dt)
	--IMPORTANT:
	--The way that this is set up will 100% be a performance bottleneck in the future.
	--But for now, it works well enough, even on stuff like Waves From Nothing (jit is amazing!)
	--If more complicated levels start chugging, this is where you will want to optimize.
	prof.push("gamemanager update")
  if not self.on then
    return
  end

  pq = ""
  if cs.source == nil or self.songfinished then
    cs.cbeat = cs.cbeat + (cs.level.bpm/60) * love.timer.getDelta()
  else
    cs.source:update()
    local b,sb = cs.source:getBeat(1)
    cs.cbeat = b+sb + cs.songoffset
    --print(b+sb)
  end

  -- read the level
	
	
  for i,v in ipairs(cs.allevents) do -- onoffset + onbeat pass
  -- preload events such as beats
    if Event.onoffset[v.type] then 
			if v.time <= cs.cbeat+cs.offset and (not v.play_onoffset) then
				Event.onoffset[v.type](v)
				v.play_onoffset = true
			end
			
			--[[
			
      if v.type == "inverse" then
        v.played = true
        local newbeat = em.init("beat",{
					x=project.res.cx,
					y=project.res.cy,
					angle = v.angle,
					endangle = v.endangle,
					spinease = v.spinease,
					hb = v.time,
					smult = v.speedmult,
					inverse = true
				})
        pq = pq .. "    ".. "spawn here!"
        newbeat:update(dt)
      end
			
      if v.type == "hold" then
        v.played = true
        local newbeat = em.init("hold",{
					x = project.res.cx,
					y = project.res.cy,
					segments = v.segments,
					duration = v.duration,
					holdease = v.holdease,
					angle = v.angle1,
					angle2 = v.angle2,
					endangle = v.endangle,
					spinease = v.spinease,
					hb = v.time,
					smult = v.speedmult
				})
        pq = pq .. "    ".. "hold spawn here!"
				newbeat:update(dt)
      end
			if v.type == "mine" then
        v.played = true
        local newbeat = em.init("mine",{
					x=project.res.cx,
					y=project.res.cy,
					angle = v.angle,
					endangle = v.endangle,
					spinease = v.spinease,
					hb = v.time,
					smult = v.speedmult
				})
        pq = pq .. "    ".. "mine here!"
        newbeat:update(dt)
      end
      if v.type == "minehold" then
        v.played = true
        local newbeat = em.init("minehold",{
					x = project.res.cx,
					y = project.res.cy,
					segments = v.segments,
					duration = v.duration,
					holdease = v.holdease,
					angle = v.angle1,
					angle2 = v.angle2,
					endangle = v.endangle,
					spinease = v.spinease,
					hb = v.time,
					smult = v.speedmult
				})
        pq = pq .. "    ".. "mine hold spawn here!"
				newbeat:update(dt)
      end
			
      if v.type == "side" then
        v.played = true
        local newbeat = em.init("side",{
					x=project.res.cx,
					y=project.res.cy,
					angle = v.angle,
					endangle = v.endangle,
					spinease = v.spinease,
					hb = v.time,
					smult = v.speedmult
				})
        pq = pq .. "    ".. "side here!"
        newbeat:update(dt)
      end
      if v.type == "slice" then
        v.played = true
        local newbeat = em.init("beat",project.res.cx,project.res.cy)
        newbeat.angle = v.angle
        newbeat.slice = true
        
        newbeat.startangle = v.angle
        newbeat.endangle = v.endangle or v.angle -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.hb = v.time
        newbeat.smult = v.speedmult
        pq = pq .. "    ".. "spawn here!"
        newbeat.update()
      end
      if v.type == "sliceinvert" then
        v.played = true
        local newbeat = em.init("beat",project.res.cx,project.res.cy)
        newbeat.angle = v.angle
        newbeat.slice = true
        newbeat.inverse = true
        
        newbeat.startangle = v.angle
        newbeat.endangle = v.endangle or v.angle -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.hb = v.time
        newbeat.smult = v.speedmult
        pq = pq .. "    ".. "spawn here!"
        newbeat.update()
      end
      if v.type == "inverse" then
        v.played = true
        local newbeat = em.init("beat",project.res.cx,project.res.cy)
        newbeat.angle = v.angle
        newbeat.startangle = v.angle
        newbeat.endangle = v.endangle or v.angle -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.hb = v.time
        newbeat.smult = v.speedmult
        newbeat.inverse = true
        pq = pq .. "    ".. "spawn here!"
        newbeat.update()
      end
      if v.type == "side" then
        v.played = true
        local newbeat = em.init("beat",project.res.cx,project.res.cy)
        newbeat.angle = v.angle
        newbeat.startangle = v.angle
        newbeat.endangle = v.endangle or v.angle -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.spinease = v.spinease or "linear" -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.hb = v.time
        newbeat.smult = v.speedmult
        newbeat.side=true
        pq = pq .. "    ".. "spawn here!"
        newbeat.update()
      end
      if v.type == "ringcw" then
        v.played = true
        local newbeat = em.init("beat",project.res.cx,project.res.cy)
        newbeat.spinrate = v.spinrate or 1 -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.spinease = v.spinease or "linear" -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.hb = v.time
        newbeat.smult = v.speedmult
        newbeat.ringcw=true
        pq = pq .. "    ".. "spawn here!"
        newbeat.update()
      end
      if v.type == "ringccw" then
        v.played = true
        local newbeat = em.init("beat",project.res.cx,project.res.cy)
        newbeat.spinrate = v.spinrate or 1 -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.spinease = v.spinease or "linear" -- Funny or to make sure nothing bad happens if endangle isn't specified in the json
        newbeat.hb = v.time
        newbeat.smult = v.speedmult
        newbeat.ringccw=true
        pq = pq .. "    ".. "spawn here!"
        newbeat.update()
      end
			
			if v.type == "videobg" and cs.videobg == nil then
        cs.videobg = love.graphics.newVideo(clevel..v.file)
				pq = pq .. "      loaded videobg"
      end
			]]--

    end
		
    -- load other events on the beat
		if Event.onbeat[v.type] then
			if v.time <= cs.cbeat and (not v.play_onbeat) then
				Event.onbeat[v.type](v)
				v.play_onbeat = true
			end
		end
		
		--[[
    if v.time <= cs.cbeat and v.played == false then
      
      v.played = true
      if v.type == "setBPM" then
				cs.level.bpm = v.bpm
        cs.source:setBPM(v.bpm, v.time)
        pq = pq .. "    set bpm to "..v.bpm .. " !!"
      end
      if v.type == "play" then
        cs.source = lovebpm.newTrack()
          :load(cs.sounddata)
          :setBPM(v.bpm)
          :setLooping(false)
          :play()
          :on("end", function(f) print("song finished!!!!!!!!!!") self.songfinished = true end)
        cs.songoffset = v.time
        cs.source:setBeat(cs.cbeat - v.time)
        pq = pq .. "    ".. "now playing ".. v.file
      end
      
      if v.type == "width" then

        
        flux.to(cs.p,v.duration,{paddle_size=v.newwidth}):ease("linear")
        pq = pq.. "    width set to " .. v.newwidth
      end
      
      if v.type == "multipulse" then
        pq = pq.. "    pulsing, generating other pulses"
        cs.extend = 10
        flux.to(cs,10,{extend=0}):ease("linear")
        for i=1,v.reps do
          table.insert(cs.allevents,{type="singlepulse",time=v.time+v.delay*i,played=false})
        end
      end

      if v.type == "singlepulse" then
        cs.extend = 10
        flux.to(cs,10,{extend=0}):ease("linear")
        pq = pq.. "    pulsing"
      end
      
      if v.type == "setbg" then
        cs.bg = love.graphics.newImage("assets/bgs/".. v.file)
        pq = pq.. "     set bg to " .. v.file
      end
      if v.type == "hom" then
        cs.vfx.hom = v.enable

        if v.enable then
          pq = pq .. "    ".. "Hall Of Mirrors enabled"
        else
          pq = pq .. "    ".. "Hall Of Mirrors disabled"
        end
      end
      if v.type == "bgnoise" then
        cs.vfx.bgnoise.enable = v.enable
        if v.enable then
          cs.vfx.bgnoise.image = love.graphics.newImage("assets/game/noise/" .. v.filename)
          cs.vfx.bgnoise.r = v.r or 1
          cs.vfx.bgnoise.g = v.g or 1
          cs.vfx.bgnoise.b = v.b or 1
          cs.vfx.bgnoise.a = v.a or 1
        else
          cs.vfx.bgnoise.image = love.graphics.newImage("assets/game/noise/0noiseatlas.png")
          cs.vfx.bgnoise.r = 1
          cs.vfx.bgnoise.g = 1
          cs.vfx.bgnoise.b = 1
          cs.vfx.bgnoise.a = 0
        end
        if v.enable then
          pq = pq .. "    ".. "BG Noise enabled with filename of " .. v.filename
        else
          pq = pq .. "    ".. "BG Noise disabled"
        end
      end
      if v.type == "circle" then
        pq = pq .. "    ".. "circle spawned"
        local nc = em.init("circlevfx",v.x,v.y)
        nc.delt = v.delta
      end
      if v.type == "square" then
        pq = pq .. "    ".. "square spawned"
        local nc = em.init("squarevfx",v.x,v.y)
        nc.r = v.r
        nc.dx = v.dx
        nc.dy = v.dy
        nc.dr = v.dr
        nc.life = v.life
        nc.update()
        
      end
			
			if v.type == "videobg" then
        pq = pq .. "    ".. "playing videobg"
				cs.drawvideobg = true
        cs.videobg:play()
      end
			
      if v.type == "showresults" then
        flux.to(cs.p,60,{ouchpulse=300,lookradius=0}):ease("inExpo"):oncomplete(function(f) 
					cs:gotoresults()
				end )
        
      end
      if v.type == "lua" then
        pq = pq .. "    ".. "ran lua code"
        local code = loadstring(v.code) -- NOOOOOO YOU CANT RUN ARBITRARY CODE THATS A SECURITY RISK
        code()  --haha loadstring go brrr
      end
    end
		]]--
  end
  
  
  if cs.combo >= math.floor(cs.maxhits / 4) then
    cs.p.cemotion = "happy"
    cs.p.emotimer = 2
    --print("player should be happy")
  end
	
  prof.pop("gamemanager update")
end


function Gamemanager:draw()
	prof.push("gamemanager draw")
  if not cs.vfx.hom then
    love.graphics.clear()
  end
  
  love.graphics.setBlendMode("alpha")
  color()

  --if cs.vfx.hom then
    --for i=0,cs.vfx.homint do
      --love.graphics.points(math.random(0,400),math.random(0,240))
    --end 
    
  --end
  --ouch the lag
  if cs.vfx.bgnoise.enable then
    love.graphics.setColor(cs.vfx.bgnoise.r,cs.vfx.bgnoise.g,cs.vfx.bgnoise.b,cs.vfx.bgnoise.a)
    love.graphics.draw(cs.vfx.bgnoise.image,math.random(-2048+project.res.x,0),math.random(-2048+project.res.y,0))
  end
  love.graphics.draw(cs.bg)
	
	if cs.drawvideobg then
		love.graphics.setShader(shaders.videoshader)
		love.graphics.draw(cs.videobg)
		love.graphics.setShader()
	end

  color()
  em.draw()
	color('black')
  --love.graphics.print(cs.hits.." / " .. (cs.misses+cs.hits),10,10)
  if cs.combo >= 10 then
    love.graphics.setFont(fonts.digitaldisco)
    love.graphics.print(cs.combo..loc.get("combo"),10,220)
  end
  color()
	prof.pop("gamemanager draw")

end


return Gamemanager