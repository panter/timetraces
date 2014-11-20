@addDrag = (elem) ->

  elem.onmousedown = (e) ->
    evt = e or window.event
    start = 0
    diff = 0
    if e.pageX
      start = evt.pageX
    else start = evt.clientX  if evt.clientX
  
    document.body.onmousemove = (e) ->
      evt = e or window.event
      end = 0
      if e.pageX
        end = evt.pageX
      else end = evt.clientX  if evt.clientX
      diff = end - start
      elem.style.left = diff + "px"
      return

    document.body.onmouseup = ->
      
      # do something with the action here
      # elem has been moved by diff pixels in the X axis

      document.body.onmousemove = document.body.onmouseup = null
      return

    return