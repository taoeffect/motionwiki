#this next part is where i made a test button. It will be commented out during integration
# var locationtoaddbutton= document.getElementById('baseNav');
# var testbutton= document.createElement('input');

# testbutton.type= 'button';
# testbutton.id= 'ButtonForMap';
# testbutton.value= 'ON';

# locationtoaddbutton.appendChild(testbutton);
#testbutton.onclick= showthemap;
#$("#ButtonForMap").click(function(){alert();});
$("#ButtonForMap").click -> #lets assume you gave the button for the map the div id= ButtonForMap
  if $(this).val() is "ON"
    $("#MAP").remove()  if $("#MAP").length
    $mapSource = $("<script>")
    $mapSource.attr "src", "miniPageNav.js"
    $("#MyScript").append $mapSource
    $(this).val "OFF"
  else
    $(this).val "ON"
    $("#MAP").slideUp "slow", ->


(($) -> #i'm working on a reload function that should be called eveytime an animation happens. not done yet
  $.fn.reloadMap = ->
    $("#MAP").remove()
) jQuery