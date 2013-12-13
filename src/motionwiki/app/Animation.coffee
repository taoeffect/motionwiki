define ['TweenMax', 'jquery'], (TweenMax, $)->
    #line is the tag of what will be animated, type is addition or deletion

    firstAnimation = true
    speedGradient = 6
    animateList = []
    addedLine = false

    doDeleteStuff = (jQueryObject) ->
        #jQueryObject.each (index, el) ->
        #    scrollToView(el)
        #    window.scrollTo(el.offsetTop, el.offsetTop - 200)
        #if (animateList.length == 0)
        #    console.log "jquery.parent().next() = #{jQueryObject.parent().next().text()}"
            #jQueryObject.parent().next().append("<motionwikiDone id='motionwikiDone'>Motionwiki Diffs Done!</motionwikiDone>")
        deleteParent(jQueryObject)
        

        _animate()

    doAddStuff = (jQueryObject) ->
        console.log "modification done"
        if addedLine is true
            addedLine = false
            console.log "jQueryOvject.prop() = #{jQueryObject.prop('id')}"
             #jQueryObject.parent().get(0)
            console.log "jQueryOvject.text() = #{jQueryObject.parent().html()}"
            $('#' + jQueryObject.prop("id")).text(" ")
            $('#' + jQueryObject.prop("id")).parent().wrap("<br> </br>")
            #$('#' + jQueryObject.prop("id")).wrap("<div></div>")
        #if (animateList.length == 0)
           # jQueryObject.parent().next().append("<motionwikiDone id='motionwikiDone'>Motionwiki Diffs Done!</motionwikiDone>")
        #scrollToView(jQueryObject)
        _animate()

    doModifyStuff = (jQueryObject) ->
        console.log "modification done"
            #$('#' + jQueryObject.prop("id")).wrap("<div></div>")
        #if (animateList.length == 0)
           # jQueryObject.parent().next().append("<motionwikiDone id='motionwikiDone'>Motionwiki Diffs Done!</motionwikiDone>")
        scrollToView(jQueryObject)
        _animate()

    deleteParent = (jQueryObject) ->
        jQueryObject.parent().remove()

    scrollToView = (jQueryObject) ->
        if firstAnimation is true
            # jQueryObject.each (index, el) ->
            #     el.scrollIntoView()
            #     window.scrollTo(el.offsetTop, el.offsetTop - 200)
            jQueryObject.get(0).scrollIntoView()
            window.scrollTo(jQueryObject.get(0).offsetTop, jQueryObject.get(0).offsetTop - 200)
            #jQueryObject.scrollIntoView()
            #window.scrollTo(jQueryObject.offsetTop, jQueryObject.offsetTop - 200)
        else
            console.log "jQueryObject.get(0) = #{jQueryObject.get(0)}"
            jQueryObject.get(0).scrollIntoView()
            window.scrollTo(jQueryObject.get(0).offsetTop, jQueryObject.get(0).offsetTop - 200)


    

    #jQueryObject is used for my final animation
    _animate = () ->
        if animateList.length > 0
            animation = animateList[0]
            animateList.splice(0, 1)
            doAnimate2(animation[0], animation[1], animation[2], animation[3], animation[4], null)
            
        else

    doAnimate2 = (line, type, jQueryObject, pureDelete, oldtext, cb) ->

        console.log "animateList.length = #{animateList.length}"

        if firstAnimation is true
            #jQueryObject.each (index, el) ->
            ##el.scrollIntoView()
                #scrollToView(el)
                #window.scrollTo(el.offsetTop, el.offsetTop - 200)
            scrollToView(jQueryObject)
            firstAnimation = false
        switch type
            when "motionwikiAddition"
                console.log "doing motionwikiAddition, line = #{line}"
                lineText = jQueryObject.parent().text()
                console.log "jQueryObject.get(0).text() = #{lineText}"
                scrollToView(jQueryObject)
                if lineText == ""
                    console.log "modify = #{"<span id='" + line.substring(1, line.length)  + "'>"  +  "ADDED LINE" + "</span>"}"
                    jQueryObject.parent().html("<span id='" + line.substring(1, line.length)  + "'>"  +  "ADDED LINE" + "</span>")
                    #jQueryObject = jQueryObject.parent()
                    addedLine = true
                
                TweenMax.from line, 2,
                    x: -500

                TweenMax.from line, 4,
                    autoAlpha: 0

                TweenMax.to line, 2,
                    color: "#1f9a33"
                    backgroundColor: "#26f447"
                    scaleY: 1.2
                    delay: 1/speedGradient

                TweenMax.to line, 1,
                {
                    scaleY: 1
                    delay: 2/speedGradient
                    onComplete: doAddStuff,
                    onCompleteParams: [jQueryObject]
                }

            when "motionwikiDeletion"
                console.log "doing motionwikiDeletion"
                scrollToView(jQueryObject)
                TweenMax.to line, 2,
                {
                    color: "#90240d"
                    backgroundColor: "#e32e07"
                    delay: 1/speedGradient
                }

                TweenMax.to line, 1,
                {
                    autoAlpha: 0
                    x: 50
                    delay: 3.2/speedGradient
                    onComplete: doDeleteStuff,
                    onCompleteParams: [jQueryObject]
                }
                   
                        


            when "motionwikiModification"
                console.log "span = #{"<span id='motionwikiDeletion" + line.substring(23, line.length) + ">"}"
                $(line).parent().append("<span id='motionwikiDeletion" + line.substring(23, line.length) + "'>" + oldtext + "</span>")
                console.log "doing motionwikiModification, line = #{line}, text = #{jQueryObject.parent().text()}"
                deleteLine = "#" + "motionwikiDeletion" + line.substring(23, line.length)
                #doAnimate2(deleteLine, "motionwikiDeletion", $("#" + "motionwikiDeletion" + line.substring(23, line.length)), false, "")
                scrollToView($(deleteLine))
                TweenMax.to deleteLine, 2,
                {
                    color: "#90240d"
                    backgroundColor: "#e32e07"
                    delay: 1/speedGradient
                }

                TweenMax.to deleteLine, 3,
                {
                    autoAlpha: 0
                    x: 50
                    delay: 3.2/speedGradient
                }

                TweenMax.to line, 3,
                {
                    color: "#000000"
                    backgroundColor: "#ffed04"
                    delay: 0/speedGradient
                    onComplete: doModifyStuff,
                    onCompleteParams: [jQueryObject]
                }



            when "motionwikiModification2"
                TweenMax.to line, 3,
                    {
                        color: "#000000"
                        backgroundColor: "#ffed04"
                        delay: 0/speedGradient
                        onComplete: doAddStuff,
                        onCompleteParams: [jQueryObject]
                    }
                

    doAnimate: (line, type, jQueryObject, pureDelete, oldtext, cb) ->
        if animateList.length == 0
            console.log "animateList == 0"
            el = [line, type, jQueryObject, pureDelete, oldtext]
            animateList.push el
            if firstAnimation is true
                _animate()
        else
            console.log "animateList++"
            animateList.push [line, type, jQueryObject, pureDelete, oldtext]

        

    

    
