define [], () ->
  animate = (line, type) -> #line is the tag of what will be animated, type is addition or deletion
    if type is "motionwikiAddition"
      TweenLite.from line, 2,
        x: -500

      TweenLite.from line, 4,
        autoAlpha: 0

      TweenLite.to line, 2,
        color: "#1f9a33"
        backgroundColor: "#26f447"
        scaleY: 1.2
        delay: 1

      TweenLite.to line, 1,
        scaleY: 1
        delay: 3

    else if type is "motionwikiDeletion"
      TweenLite.to line, 2,
        color: "#90240d"
        backgroundColor: "#e32e07"
        delay: 1

      TweenLite.to line, 1,
        autoAlpha: 0
        x: 50
        delay: 3.2

    else if type is "motionwikiModification"
      TweenLite.to line, 3,
        color: "#000000"
        backgroundColor: "#ffed04"
