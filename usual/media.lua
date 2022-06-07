local helper = require( 'usual/helper' )
local loader = require( 'usual/loader' )

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

  if media.player.font and type(media.player.font) == 'string' then
    helper.loadFont( media.player.font )
  end

  if media.audio.source and type(media.audio.source) == 'string' then
    media.audio.source = helper.loadAudio( media.audio.source )
  end
end

function media.load()
  media.player.dt = 0                 -- delta time
  media.player.timeelapsed = 0
  media.player.playing = false
  media.player.pathprefix = 'frames/'
  media.player.fileprefix = 'frame-'  
  media.player.fileext = '.png'       -- .bmp, .tga, .jpg

  if media.player.mode == 'video' then
    media.player.setup( 3, 25, 1/25 )

  elseif media.player.mode == 'diaporama' then
    media.player.setup( 1, 25, 1/25 )
    media.player.effect = {}
    media.player.effect.slide_topdown = true
  
  elseif media.player.mode == 'presentation' then
    media.player.setup( 1, 25, 1/25 )
    media.player.effect = {}
    media.player.effect.slide_rightleft = true
  
  elseif media.player.mode == 'sprite' then
    media.player.setup( 1, 30, 1/30 )
    media.frame.sps = { 64, 64 } -- squared pratical shape
  
  else
    assert( media.player.mode, "no media.player.mode set, cannot continue." )
  end


  if media.player.ui then

    if media.player.ui.frame then
      assert( type( media.player.ui.frame ) == 'string',
        'media.player.ui.frame: doesn\'t look like a string.' )
      assert( love.filesystem.isFile( media.player.ui.frame ),
        'That file:"'.. media.player.ui.frame ..'" doesn\'t exists.' )
      media.player.ui.frame = love.graphics.newImage( media.player.ui.frame )
      
      if media.player.ui.frame then
        media.player.ui.width = media.player.ui.frame:getWidth()
        media.player.ui.height = media.player.ui.frame:getHeight()
      end
    end

    media.player.scaling = 'ui'
    media.player.ui.button_previous_frame = true
    media.player.ui.button_next_frame = true
    media.player.ui.button_quit = true
  end

  media.frame = {
    dt = 0,
    idx = 1,
    next = true,
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    image = nil,
    fps = 0,         -- the recorded rate
    rendered = 0
  }
  
  media.window.width,
  media.window.height,
  media.window.flags = love.window.getMode()

  if media.player.fullscreen and media.player.fullscreen.enable then
    media.window.flags.fullscreen = true
    love.window.setMode( media.window.width, media.window.height, media.window.flags )
  end

  media.display.width,
  media.display.height = love.window.getDesktopDimensions( media.window.flags.display )

  media.errorcooldown = 0
  media.error = nil

  assert( love.filesystem.isDirectory( media.player.pathprefix ),
      "Unable to open media.player.pathprefix:" .. media.player.pathprefix )

  media.frame.total = helper.countFiles( media.player.pathprefix )

  media.buf, media.load = 0, 0

  if media.player.cache then
    media.frame.cache = {}
  end

  -------[[ loader ]]-------------------------------------------------------------------------
  loader.loading = false                    -- loader processing
  
  loader.width = 30                         -- loader bar width
  loader.height = 10                        -- loader bar height

  loader.x = (media.window.width-media.player.ui.width)/2 + media.player.ui.width/2   -- loader x axis
  loader.y = (media.window.height-media.player.ui.height)/2 + media.player.ui.height-15        -- loader y axis (cuz i know ui thickness...)

  loader.current = 0
  loader.max = 100
  loader.padding = 3
  
  loader.color = {
    outline = { 58, 55, 88, 255 },
    bar =     { 95, 205, 228, 255 },
    text =    { 95, 205, 228, 255 }
  }
  
  loader.r,
  loader.g,
  loader.b,
  loader.a = love.graphics.getColor()
  
  loader.text = "loading ..."

  -- media.play()
end

function media.loadcache()
  local i = 0
  if #media.frame.cache > 0 then
    i = #media.frame.cache
  end
  
  while i < media.frame.total do
    i = i +1

    media.frame.fullpath = media.player.pathprefix ..
    media.player.fileprefix ..
    i .. media.player.fileext
    
    if love.filesystem.isFile( media.frame.fullpath ) then
      table.insert( media.frame.cache,
        { image = love.graphics.newImage( media.frame.fullpath ), width = 0, height = 0 } )
      
      -- store frames and size
      local n = #media.frame.cache
      if media.frame.cache[n].image then
        media.frame.cache[n].width = media.frame.cache[n].image:getWidth()
        media.frame.cache[n].height = media.frame.cache[n].image:getHeight()
        media.frame.cache[n].fullpath = media.frame.fullpath
        -- scale to frame option?
        -- if media.window.width ~= media.frame.cache[n].width and not media.window.flags.fullscreen then
        --   love.window.setMode( media.frame.cache[n].width, media.frame.cache[n].height, media.window.flags )
        -- end
      end
    else
      media.error = 'Not a file: ' .. media.frame.fullpath
    end

    if i > 0 and ( i % 10 ) == 0 then
      media.load = media.load + 2 ^ 5
      if media.load >= 100 then
        media.load = 0
      end
      break
    end
  end
  local ret = (#media.frame.cache/media.frame.total)
  return ret*100

  --[[-------------------------------------------------------------------------------------------
  media.frame.cache = {}
  local i = 0
  while i < media.frame.total do
    i = i +1  
    media.frame.fullpath = media.player.pathprefix ..
    media.player.fileprefix ..
    i .. media.player.fileext
    
    if love.filesystem.isFile( media.frame.fullpath ) then
      table.insert( media.frame.cache, { image = love.graphics.newImage( media.frame.fullpath ), width = 0, height = 0 } )
      -- store frames and size
      local n = #media.frame.cache
      if media.frame.cache[n].image then
        media.frame.cache[n].width = media.frame.cache[n].image:getWidth()
        media.frame.cache[n].height = media.frame.cache[n].image:getHeight()
        -- if media.window.width ~= media.frame.cache[n].width and not media.window.flags.fullscreen then
        --   love.window.setMode( media.frame.cache[n].width, media.frame.cache[n].height, media.window.flags )
        -- end
      end
    else
      media.error = 'Not a file: ' .. media.frame.fullpath
    end
  end
  --]]-------------------------------------------------------------------------------------------
end

function media.play()
  media.player.playing = true
  
  if media.audio and media.audio.source then
    love.audio.play( media.audio.source )
  end
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
  local ok = false
  assert( media.window.flags, "Window structure missing... media.window.flags" )
  
  if love.window.getFullscreen() and not media.player.lockfullscreen then
    media.window.flags.fullscreen = false
    if media.player.scaling == 'ui' then
      ok = love.window.setMode( media.player.ui.width, media.player.ui.height, media.window.flags )
      media.window.width, media.window.height = media.player.ui.width, media.player.ui.height
    else
      ok = love.window.setMode( media.window.width, media.window.height, media.window.flags )
    end
  else
    if media.window.flags and not media.window.flags.fullscreen then
      media.window.flags.fullscreen = true
      ok = love.window.setMode( media.display.width, media.display.height, media.window.flags )
      media.window.width, media.window.height = media.display.width, media.display.height
      loader.x = (media.window.width-media.player.ui.width)/2 + media.player.ui.width/2   -- loader x axis
      loader.y = (media.window.height-media.player.ui.height)/2 + media.player.ui.height-15
    end
  end  
  
  if not ok then
    if media.player.lockfullscreen then
      media.error = 'Unable to setup fullscreen; see media.player.lockfullscreen.'
    else
      media.error = 'Unable to setup fullscreen mode.'
    end
  end
end

function media.update( dt )
  if media.player.cache and not media.playing then
    
    loader.loading = true
    
    if dt < 0.04 then
      media.buf = media.loadcache()
      loader.current = media.load
      if media.load >= 100 then
        media.load = 0
      end
      -- print(media.buf)
    end
    
    if media.buf >= 100 then
      loader.loading = false
      loader.current = 100
      if media.player.autoplay then
        media.play()
      end
      loader.text = "Done!"
    elseif media.buf > 0 then
      loader.text = media.frame.fullpath .. " " .. string.format( "%.02f%%", media.buf )
    end
  
  end

  if media.player.playing then
    media.step( dt )
      
    if media.frame.next then
      media.frame.next = nil
      if media.frame.idx >= media.frame.total then
        media.stop()
      else
        media.frame.image = nil
        
        if not media.player.cache then
          if media.frame.idx > 0 and ( media.frame.idx % 5 ) == 0 then
            media.player.memflush = true
            collectgarbage()
          end

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

          if media.player.playing then
            media.window.width, media.window.height = love.window.getDimensions( )
  
            if love.window.getFullscreen() then
              media.frame.x = (media.window.width-media.frame.width)/2
              media.frame.y = (media.window.height-media.frame.height)/2
            else
              if media.frame.x ~= 0 and media.frame.y ~= 0 then
                media.frame.x, media.frame.y = 0, 0
              end
            end
          end
        end -- no cache
        if media.frame.cache then
          media.frame.image = media.frame.cache[media.frame.idx].image
          media.frame.width = media.frame.cache[media.frame.idx].width
          media.frame.height = media.frame.cache[media.frame.idx].height
          media.frame.x, media.frame.y = (media.window.width-media.frame.width)/2, (media.window.height-media.frame.height)/2
          media.frame.fullpath = media.frame.cache[media.frame.idx].fullpath
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
      
      if media.frame.fps <= media.player.fps-(media.player.fps/5) then
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
    love.graphics.draw( media.player.ui.frame, (media.window.width-media.player.ui.width)/2, (media.window.height-media.player.ui.height)/2 )
  end

  loader.draw()
end

return media

