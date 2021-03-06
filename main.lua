local helper = require( 'usual/helper' )
local event = require( 'usual/event' )
local media = require( 'usual/media' )

function love.errhand( message )
  print( message )
end

--[[
  As you can see all the control is bind from there.
  The main goal is to keep media.lua an handy module
  for older love version, currently 9.1.
  newer version got ogv addition so it's really of
  special case if you wish to use it.

  The main things to perform are to setup media.player.mode,
  your audio source[optional], the control input you wish to handle[optional].

  All options will be documented as soon I entirely define internal correctly.
]]--

function love.load()
  media.showinfo = true                    -- print information to screen
  event.showinfo = true                    --  "                       "

  if media.player then
    media.player.mode = 'video'            -- player mode
    media.player.fps = 25                  -- fixed frame per sec
    media.player.dpf = 1/media.player.fps  -- delta per frame

    -- optional, all of these can be omited.
    media.player.cache = true              -- cache entire content to be played
    media.player.autoplay = true           -- play either directly or after loading cache
    media.player.font = 'ubuntu-b.ttf'     -- load some font
    media.audio.source = 'output.mp3'      -- audio source
    -- media.player.keyboard = {}             -- allows keyboard input
    -- media.player.mouse = {}                -- allows mouse input
    media.frame.resize = {                 -- if you wish to resize frames
      width = 480,
      height = 280
    }

    media.player.fullscreen = {
      enable  = false,                     -- fullscreen by default
      lock    = false,                     -- lock fullscreen
      type    = 'normal',
      -- 'normal' applies the closest valid .width,.height mode to display,
      -- 'desktop' setup fullscreen to window from display size
      width = 640,                         -- applies to 'normal' type
      height = 480                         -- applies to 'normal' type
      -- usual PC modes 640x480, 800x600, 1024x768, 1280x720
      -- usual phone modes 320x480, no idea if screen orientation is supported, don't see any ref inside doc...
    }

    -- media.player.scaling = 'ui'         -- scale to ui size

    media.player.ui = {                    -- if you wish some predefined frame as a skin, this is the right place to define that.
      frame = 'ui.png'
    }
  end

  error = {}
  error.dt = 0
  event.load()
  media.load()
end


function love.keypressed( key, isRepeat )
  if media.player.keyboard then
    if key == 'f' then
      media.fullscreen()
    end
  end
  event.keypressed( key, isRepeat )
end


function love.keyreleased( key )
  event.keyreleased( key )

  if media.player.keyboard then
    if key == 'right' then
      media.next()
    end
    if key == 'left' then
      media.back()
    end
    if key == 'p' then
      media.pause()
    end
  end
end


function love.mousepressed( x, y, button )
  -- need smoothing input
  if media.player.mouse then
    if button == 'wd' then
      media.back()
    elseif button == 'wu' then
      media.next()
    else
    end
  end
end


function love.mousereleased( x, y, button )
  if media.player.mouse then
    if button == 'l' then
      media.back()
    elseif button == 'm' then
      media.pause()
    elseif button == 'r' then
      media.next()
    elseif button == 'x1' then
      assert(false, 'custom mouse button x1')
    elseif button == 'x2' then
      assert(false, 'custom mouse button x2')
    else
      assert(false, 'droped mouse button:' .. button)
    end
  end
end


function love.update( dt )
  media.update( dt )

  if media.error or event.error then 
    error.dt = error.dt + dt
    if error.dt > 2 then
      error.dt = 0
      media.error, event.error = nil, nil
    end
  end
end


function love.draw()
  media.draw()
  -- love.graphics.printf( "engine FPS: " .. love.timer.getFPS(), 0, 5, 845, "center" )
  event.draw( media.window.width, media.window.height )
end
