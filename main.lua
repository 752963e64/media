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
  end

  if media.audio then
    media.audio.source = helper.loadAudio( 'output.mp3' )
  end

  error = {}
  error.dt = 0
  ui = love.graphics.newImage( 'ui.png' )
  event.load()
  media.load()
end


function love.keypressed( key, isRepeat )
  if key == 'f' then
    media.fullscreen()
  end
  event.keypressed( key, isRepeat )
end


function love.keyreleased( key )
  event.keyreleased( key )
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


function love.mousepressed( x, y, button )
end

function love.mousereleased( x, y, button )
end

-- l
--     Left Mouse Button. 
-- m
--     Middle Mouse Button. 
-- r
--     Right Mouse Button. 
-- wd
--     Mouse Wheel Down. 
-- wu
--     Mouse Wheel Up. 
-- x1
--     Mouse X1 (also known as button 4). 
-- x2
--     Mouse X2 (also known as button 5). 

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

  love.graphics.draw( ui, 0, 0 )
  -- love.graphics.printf( "engine FPS: " .. love.timer.getFPS(), 0, 5, 845, "center" )
  event.draw( media.window.width, media.window.height )
end
