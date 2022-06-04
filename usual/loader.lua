
loader = {}

function loader.draw()
  if loader.loading then
    love.graphics.setColor( loader.color.outline )
    
    love.graphics.rectangle( "line",
      loader.x,
      loader.y,
      loader.width,
      loader.height )
    
    love.graphics.setColor( loader.color.bar )
  
    loader.wx = loader.width*loader.current/loader.max-loader.padding*2
  
    if loader.wx < 0 then loader.wx = 0 end
  
    love.graphics.rectangle( "fill",
      loader.x+loader.padding,
      loader.y+loader.padding,
      loader.wx,
      loader.height-loader.padding*2 )
    
    love.graphics.setColor( loader.color.text )
    
    love.graphics.printf( loader.text,
      loader.x+50,
      loader.y-2,
      loader.x,
      "left" )
    
    love.graphics.setColor( loader.r, loader.g, loader.b, loader.a )
  end
end

return loader
