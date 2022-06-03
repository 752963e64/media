require( 'usual/helper' )
require( 'usual/event' )
require( 'usual/media' )

function love.errhand( message )
  print( message )
end

function love.load()
  media.showinfo = true
  event.showinfo = true
  helper.loadFont( 'ubuntu-b.ttf' )

  if media.player then
    media.player.mode = 'video'            -- player mode
    media.player.fps = 25                  -- fixed frame per sec  
    media.player.dpf = 1/media.player.fps  -- delta per frame
    media.player.keyboard = {}
    media.player.mouse = {}
  end

  if media.audio then
    media.audio.source = helper.loadAudio( 'output.mp3' )
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
