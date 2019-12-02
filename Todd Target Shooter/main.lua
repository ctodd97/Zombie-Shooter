-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
display.setStatusBar( display.HiddenStatusBar )

-- Get the screen metrics (use the entire device screen area)
local WIDTH = display.actualContentWidth
local HEIGHT = display.actualContentHeight
local xMin = display.screenOriginX
local yMin = display.screenOriginY
local xMax = xMin + WIDTH
local yMax = yMin + HEIGHT
local xCenter = (xMin + xMax) / 2
local yCenter = (yMin + yMax) / 2

-- File local variables
local bullets      -- display group of all active bullets
local targets      -- display group of all active targets

local gun = display.newImageRect( "gun.png", 40, 100 )
gun.x = xCenter
gun.y = yMax

local hits = 0
local miss = 0
local perc = 0

-- Hits counter
local hitsTxt = display.newText( "Hits: " .. hits, xMax/6, yMin + 20, native.systemFont, 25 )
hitsTxt:setFillColor( 0, 1, 0 )

-- miss counter
local missTxt = display.newText( "Miss: " .. miss, xMax/2, yMin + 20, native.systemFont, 25)
missTxt:setFillColor( 1, 0, 0)

-- percent of hits
local percTxt = display.newText( "Hit: " .. perc .. "%", xMax - xMax/6, yMin + 20, native.systemFont, 25)
percTxt:setFillColor( 0, .5, 1 )

-- Create and return a new bullet object.
function createBullet()
	local b = display.newImageRect( bullets, "bullet.png", 32, 60 )      --(use the bullets group as the parent)
	b.x = xCenter
	b.y = yMax - 50

	return b
end

-- Create a return a new target object at a random altitude.
function createTarget()
	local t = display.newGroup()
	t = display.newImageRect( targets, "zombie.png", 30, 50 )
	t.x = xMax + 15
	t.y = math.random( yMin+70, yMax-70 )
	targets:insert(t)   -- put t into the targets group
	return t
end

-- Called when a bullet goes off the top of the screen
-- Delete the bullet.
function bulletDone( obj )
	obj:removeSelf(b)
end

-- Called when a target goes off the left of the screen
-- Delete the target and count a miss.
function targetDone( obj )
	transition.cancel( obj )
	obj:removeSelf( )
	miss = miss + 1
	missTxt.text = "Miss: " .. miss
	percCalc()
end

--called to end explosion animation
function explosionDone( obj )
	obj:removeSelf( e )
end

--calculate percentage, called whenever a hit/miss is added
function percCalc()
	perc = math.floor((( hits / (hits + miss) ) * 100) + .5 )
	percTxt.text = "Hit: " .. perc .. "%"
end

-- Called when the screen is touched
-- Fire a new bullet.
function touched( event )
	if event.phase == "began" then
		local b = createBullet()
		transition.to( b, { x = xCenter, y = yMin, time = 1000, onComplete = bulletDone } )
	end
end

-- Return true if the given bullet hit the given target
function hitTest( b, t )
	if math.abs(b.x - t.x) <= 15 and math.abs(b.y - t.y) <= 15 then
		transition.cancel(t)
		return true
	else
		return false
	end
end

-- Called before each animation frame
function newFrame()
	-- Launch new targets at random intervals and speeds
	if math.random(0, 20) < 0.5		then
		local t = createTarget()
		transition.to( t, { x = xMin, rotation = 360, time = math.random( 3000, 5000 ), onComplete = targetDone } )
	end


	-- Test for hits (all bullets against all targets)
	local zombies = {}   -- to hold objects that need deferred deleting
	for i = 1, bullets.numChildren do
		local b = bullets[i]
		for j = 1, targets.numChildren do
			local t = targets[j]
			if hitTest( b, t ) then
				-- Add bullet and target to the zombie list for deferred delete.
				-- (Deleting them now will screw up the for loops)
				zombies[#zombies + 1] = b
				zombies[#zombies + 1] = t

				-- Count a hit
				hits = hits + 1
				hitsTxt.text = "Hits: " .. hits
				percCalc()


				-- Make an explosion
				e = display.newImageRect( "explosion.png", 48, 48 )
				e.x = t.x
				e.y = t.y
				--transition.fadeOut( e, { xScale = 2, yScale = 2, time = 4000, onComplete = explosionDone }  )
				transition.to( e, { xScale = 1.5, yScale = 1.5, alpha = 0, time = 1000, onComplete = explosionDone } )

			end
		end
	end

	-- Now delete all the zombie objects
	for i = 1, #zombies do
		local obj = zombies[i]
		transition.cancel( obj )
		obj:removeSelf()
	end
end

-- Init the app
function initApp()
	-- Create display groups for active bullets and targets
	bullets = display.newGroup()
	targets = display.newGroup()


	-- Add event listeners
	Runtime:addEventListener( "touch", touched )
	Runtime:addEventListener( "enterFrame", newFrame )
end

-- Start the game
initApp()