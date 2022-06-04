
helper = {
  os = love.system.getOS()
}

function helper.loadFont( filepath, size )
  local xft = {}
  
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
