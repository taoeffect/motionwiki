define ['TweenMax'], (TweenMax)->
    #line is the tag of what will be animated, type is addition or deletion

    firstAnimation = true

    doDeleteStuff = (jQueryObject) ->
        jQueryObject.each (index, el) ->
            scrollToView(el)
            window.scrollTo(el.offsetTop, el.offsetTop - 200)
        deleteParent(jQueryObject)

    deleteParent = (jQueryObject) ->
        jQueryObject.parent().remove()

    scrollToView = (jQueryObject) ->
        if firstAnimation is true
            # jQueryObject.each (index, el) ->
            #     el.scrollIntoView()
            #     window.scrollTo(el.offsetTop, el.offsetTop - 200)
            jQueryObject.each (index, el) ->
                el.scrollIntoView()
                window.scrollTo(el.offsetTop, el.offsetTop - 200)
                return false
            #jQueryObject.scrollIntoView()
            #window.scrollTo(jQueryObject.offsetTop, jQueryObject.offsetTop - 200)

            

    doAnimate: (line, type, jQueryObject, pureDelete, cb) ->



        if firstAnimation is true
            #jQueryObject.each (index, el) ->
            ##el.scrollIntoView()
                #scrollToView(el)
                #window.scrollTo(el.offsetTop, el.offsetTop - 200)
            scrollToView(jQueryObject)
            firstAnimation = false
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
                {
                    scaleY: 1
                    delay: 3
                    #onComplete: scrollToView,
                    #onCompleteParams: [jQueryObject]
                }

            when "motionwikiDeletion"
                console.log "doing motionwikiDeletion"
                TweenMax.to line, 2,
                {
                    color: "#90240d"
                    backgroundColor: "#e32e07"
                    delay: 1
                }

                TweenMax.to line, 1,
                {
                    autoAlpha: 0
                    x: 50
                    delay: 3.2
                    onComplete: doDeleteStuff,
                    onCompleteParams: [jQueryObject]
                }
                   
                        


            when "motionwikiModification"
                console.log "doing motionwikiModification"
                TweenMax.to line, 3,
                {
                    color: "#000000"
                    backgroundColor: "#ffed04"
                    #onComplete: scrollToView,
                    #onCompleteParams: [jQueryObject]
                }
                console.log "modification done"

    
