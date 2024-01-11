local info = {
	event = 'hold',
	name = 'Spawn Hold',
	storeinchart = true,
	hits = 1,
	description = [[Parameters:
time: Beat to spawn on
angle: First Angle to spawn at
angle2: Second Angle to spawn at
duration: How many beats the Hold will last
segments: (Optional) Force a certain number of line segments
holdease: (Optional) Change ease from angle1 to angle2
endangle: (Optional) First Angle to end up at
spinease: (Optional) Ease to use while rotating
speedmult: (Optional) Speed multiplier for approach
]]
}

--onload, onoffset, onbeat
local function onoffset(event)
	
	local newbeat = em.init("hold",{
		x = project.res.cx,
		y = project.res.cy,
		segments = event.segments,
		duration = event.duration,
		holdease = event.holdease,
		angle = event.angle,
		angle2 = event.angle2,
		endangle = event.endangle,
		spinease = event.spinease,
		hb = event.time,
		smult = event.speedmult
	})
	pq = pq .. "    ".. "hold spawn here!"
	newbeat:update(dt)
	
end


return info, onload, onoffset, onbeat