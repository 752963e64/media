require( 'usual/helper' )

media = {}

media.player = {}
media.frame = {}
media.window = {}
media.display = {}
media.audio = {}

function media.player.setup( step, fps, dpf )
  if not media.player.step then
    media.player.step = step    -- control step second
  end
  
  if not media.player.fps then
    media.player.fps = fps    -- fixed frame per sec
  end
  
  if not media.player.dpf then
    media.player.dpf = dpf  -- fixed delta per frame
  end

  if not media.player.pathprefix then
    media.player.pathprefix = 'frames/'
  end

  if not media.player.fileprefix then
    media.player.fileprefix = 'frame-'  
  end

  if not media.player.fileext then
    media.player.fileext = '.png' -- .bmp, .tga, .jpg
  end
end

function media.load()
  media.player.dt = 0             -- delta time
  media.player.timeelapsed = 0     
  media.player.playing = false 
  media.player.pathprefix = 'frames/'
  media.player.fileprefix = 'frame-'  
  media.player.fileext = '.png' -- .bmp, .tga, .jpg

  if media.player.mode == 'video' then
    media.player.setup( 3, 25, 1/25 )
    media.player.ui = {}
    media.player.ui.frame = love.graphics.newImage( 'ui.png' )
    media.player.ui.width = media.player.ui.frame:getWidth()
    media.player.ui.height = media.player.ui.frame:getHeight()
  
  elseif media.player.mode == 'diaporama' then
    media.player.setup( 1, 25, 1/25 )
    media.player.effect = {}
    media.player.effect.slide_topdown = true
  
  elseif media.player.mode == 'presentation' then
    media.player.setup( 1, 25, 1/25 )
    media.player.ui = {}
    media.player.ui.mouse = true
    media.player.ui.keyboard = true 
    media.player.effect = {}
    media.player.effect.slide_rightleft = true
  
  elseif media.player.mode == 'sprite' then
    media.player.setup( 1, 30, 1/30 )
    media.player.ui = {}
    media.frame.sps = { 64, 64 } -- squared pratical shape
  
  else
    assert( media.player.mode, "no media.player.mode set, cannot continue." )
  end

  if media.player.ui then
    media.player.ui.button_previous_frame = true
    media.player.ui.button_next_frame = true
  end

  media.frame.dt = 0
  media.frame.idx = 1
  media.frame.next = true
  media.frame.x = 0
  media.frame.y = 0
  media.frame.width = 0
  media.frame.height = 0
  media.frame.image = nil
  media.frame.fps = 0 -- the recorded rate
  media.frame.rendered = 0

  media.display.fullscreen = false

  media.window.width, media.window.height, media.window.flags = love.window.getMode()
  media.display.width, media.display.height = love.window.getDesktopDimensions( media.window.flags.display )

  media.errorcooldown = 0
  media.error = nil

  if love.filesystem.isDirectory( media.player.pathprefix ) then
    media.frame.total = helper.countFiles( media.player.pathprefix )
  else
    media.error = "Unable to open media.player.pathprefix:" .. media.player.pathprefix
    love.event.quit()
  end

  media.play()
end

function media.play()
  media.player.playing = true
  if media.audio and media.audio.source then love.audio.play( media.audio.source ) end
end

function media.pause()
  media.player.playing = not media.player.playing
  if media.audio and media.audio.source then
    if media.player.playing then
      love.audio.resume( media.audio.source )
    else
      love.audio.pause( media.audio.source )
    end
  end
end

function media.stop()
  if media.player.playing then
    media.player.playing = false
    media.frame.image = nil
    if media.audio and media.audio.source then
      love.audio.stop( media.audio.source )
    end
  end
end

function media.next()
  local forward = ( media.player.step*media.player.fps )
  media.frame.idx = media.frame.idx + forward
  
  if media.frame.idx > media.frame.total then
    media.frame.idx = media.frame.total  
  end

  if media.audio and media.audio.source then
    local position = media.audio.source:tell( "seconds" )
    local offset = position/media.player.timeelapsed
    media.audio.source:seek( position+(2.6*offset), "seconds" ) 
  end

  if media.showinfo then
    media.frame.rendered = media.frame.rendered + forward
  end
  
  media.player.timeelapsed = media.player.timeelapsed + media.player.step
end

function media.back()
  local rewind = ( media.player.step*media.player.fps )
  media.frame.idx = media.frame.idx - rewind
  
  if media.frame.idx <= 0 then media.frame.idx = 1 end
  
  if media.audio and media.audio.source then
    local position = media.audio.source:tell( 'seconds' )
    local offset = position/media.player.timeelapsed
    -- maybe min/max no ?
    media.audio.source:seek( position-(2.6*offset), 'seconds' ) 
  end

  if media.showinfo then
    media.frame.rendered = media.frame.rendered - rewind
  end
  
  media.player.timeelapsed = media.player.timeelapsed - media.player.step
  if media.player.timeelapsed < 0 then media.player.timeelapsed = 0 end
end

function media.step( dt )
   -- may skip frame in case of delay
  local index = media.frame.idx
  media.frame.dt = media.frame.dt + dt

  while media.frame.dt > media.player.dpf do
    media.frame.dt = media.frame.dt - media.player.dpf
    media.frame.idx = media.frame.idx + 1
    media.frame.next = true
  end

  if (index+2) < media.frame.idx then
    media.error = "Some frames has been skipped."
  end
end

function media.fullscreen()
  -- success = love.window.setFullscreen( not love.window.getFullscreen() )
  if love.window.getFullscreen() then
    media.window.flags.fullscreen = false
    success = love.window.setMode( media.frame.width, media.frame.height, media.window.flags )
  else
    media.window.flags.fullscreen = true
    success = love.window.setMode( media.display.width, media.display.height, media.window.flags )
  end  
  if not success then media.error = 'Unable to setup fullscreen mode.' end
end

function media.update( dt )
  if media.player.playing then
    media.step( dt )
      
    if media.frame.next then
      media.frame.next = nil
      if media.frame.idx > media.frame.total then
        media.stop()
      else
        media.frame.image = nil
        collectgarbage()
  
	      media.frame.fullpath = media.player.pathprefix ..
          media.player.fileprefix ..
          media.frame.idx ..
          media.player.fileext
        
        if love.filesystem.isFile( media.frame.fullpath ) then
	        media.frame.image = love.graphics.newImage( media.frame.fullpath )
          -- store frame size
          if media.frame.image then
            media.frame.width = media.frame.image:getWidth()
            media.frame.height = media.frame.image:getHeight()
            if media.window.width ~= media.frame.width and not media.window.flags.fullscreen then
              love.window.setMode( media.frame.width, media.frame.height, media.window.flags )
            end
          end
        else
          media.error = 'Not a file: ' .. media.frame.fullpath
          media.stop()
        end
  
        -- media.fullscreen = love.window.getFullscreen()
        if media.player.playing then
          media.window.width, media.window.height = love.window.getDimensions( )
  
          if love.window.getFullscreen() then
            media.frame.x = (media.window.width-media.frame.width)/2
            media.frame.y = (media.window.height-media.frame.height)/2
          else
            if media.frame.x ~= 0 and media.frame.y ~= 0 then
              media.frame.x, media.frame.y = 0, 0;
            end
          end
        end
      end
    end

    -- testing frame persec
    media.player.dt = media.player.dt + dt
    
    if media.player.playing and media.player.dt >= 1 then
      media.player.timeelapsed = media.player.timeelapsed+media.player.dt
      media.player.dt = 0
      if media.frame.fps > 0 then
	      media.frame.rendered = media.frame.rendered + media.frame.fps 
        media.frame.fps = media.frame.idx - media.frame.rendered
      else
	      media.frame.fps = media.frame.idx
      end
      
      if media.frame.fps <= (media.player.fps-5) then
        media.errorcooldown = media.errorcooldown +1
        if media.errorcooldown == 3 then
          media.errorcooldown = 0
          media.error = 'Your computer seems slow with such an fps rate.'
        end
      end
    end
  end
end

function media.draw()
  if media.frame.image then
    love.graphics.draw( media.frame.image, media.frame.x, media.frame.y )

    if not media.showinfo then return end

    if media.window.width > 0 and media.frame.width > 0 then
      love.graphics.printf( "FPS: " .. media.frame.fps ..
        " time step: " .. media.player.dpf ..
        " duration: " .. media.player.timeelapsed,
        (media.window.width/2)-175,
        media.window.height-(media.window.height-20),
        350,
        "center" )
      
      love.graphics.printf( "frame number: " .. media.frame.idx ..
        " path: " .. media.frame.fullpath,
        (media.window.width/2)-175,
        media.window.height-(media.window.height-35),
        350,
        "center" )
      
      love.graphics.printf( "frame width: " .. media.frame.width,
        media.window.width-200,
        media.window.height-50,
        150,
        "right" )
      
      love.graphics.printf( "frame height: " .. media.frame.height,
        media.window.width-200,
        media.window.height-30,
        150,
        "right" )

      love.graphics.printf( "window width: " .. media.window.width,
        (media.window.width+50)-media.window.width,
        media.window.height-50,
        150 ,
        "left" )
      
      love.graphics.printf( "window height: " .. media.window.height,
        (media.window.width+50)-media.window.width,
        media.window.height-30,
        150,
        "left" )

      if media.error then
        love.graphics.printf( media.error,
          (media.window.width/2)-150,
          (media.window.height/2)-18,
          300,
          "center" )
      end
    end
  end

  if media.player.ui then
    love.graphics.draw( media.player.ui.frame, 0, 0 )
  end
end

return media

