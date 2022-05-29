
event = {}

function event.load()
  event.lshift = false
  event.error = 'Press shift+escape to quit the software'
end

function event.keypressed( key, isRepeat )
  if key == 'escape' and event.lshift then
    love.event.quit()
  end

  if key == 'lshift' then
    event.lshift = not event.lshift
  end
end

function event.keyreleased( key )
  if key == 'lshift' then
    event.lshift = false
  end
end

function event.draw( w, h )
  if w > 0 and event.showinfo then
    if event.error then
      love.graphics.printf( event.error, (w/2)-(300/2), (h/2)-7, 300, 'center' )
    end
  end
end

return event

