
helper = {}

function helper.loadFont( filepath, size )
  local xft = { 
    os = love.system.getOS()
  }

  if xft.os == 'Linux' then
    -- '/usr/share/fonts/truetype/'
    if love.filesystem.isDirectory( '/usr/share/fonts/truetype' ) then
      xft.pathprefix = '/usr/share/fonts/truetype'
      local files = love.filesystem.getDirectoryItems( dirpath )
      if files and #files > 0 then
        
      end
    end
  elseif xft.os == 'Windows' then
    assert(false, 'Windows font handling missing')
  else -- "OS X"
    assert(false, 'OS X font handling missing')
  end
  
  xft.size = 11

  if size and size > 0 then
    xft.size = size
  end
  
  xft.ttf = love.graphics.newFont( filepath, xft.size )
  
  love.graphics.setFont( xft.ttf )
end


function helper.countFiles( dirpath )
  local files = love.filesystem.getDirectoryItems( dirpath )
  return #files
end


function helper.loadAudio( audiopath )
    if love.filesystem.isFile( audiopath ) then
      return love.audio.newSource( audiopath, 'static' )
    end
end

return helper
