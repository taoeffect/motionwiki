define ['TweenMax'], (TweenMax)->
    #line is the tag of what will be animated, type is addition or deletion
    doAnimate: (line, type) ->
        switch type
            when "motionwikiAddition"
                console.log "doing motionwikiAddition"
                TweenMax.from line, 2,
                    x: -500

                TweenMax.from line, 4,
                    autoAlpha: 0

                TweenMax.to line, 2,
                    color: "#1f9a33"
                    backgroundColor: "#26f447"
                    scaleY: 1.2
                    delay: 1

                TweenMax.to line, 1,
                    scaleY: 1
                    delay: 3

            when "motionwikiDeletion"
                console.log "doing motionwikiDeletion"
                TweenMax.to line, 2,
                    color: "#90240d"
                    backgroundColor: "#e32e07"
                    delay: 1

                TweenMax.to line, 1,
                    autoAlpha: 0
                    x: 50
                    delay: 3.2

            when "motionwikiModification"
                console.log "doing motionwikiModification"
                TweenMax.to line, 3,
                    color: "#000000"
                    backgroundColor: "#ffed04"
