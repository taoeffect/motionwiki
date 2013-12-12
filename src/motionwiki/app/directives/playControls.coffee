## Play controls directive

define ['require', 'jquery'], (require, $)->

  angular.module('mw_directives').directive 'mwPlayControls', [ ->
    templateUrl: '/includes/templates/directives/playControls.html'
    restrict: 'A'
    link: (scope, element, attrs)->
      console.log "play controls directive"
      scope.active = false
      slider = $('#sample-change-keypress')
      input = $('#input-with-keypress')
      myInterval = -> 

      $('body').keyup (e) ->
        if e.keyCode is 39
          value = parseInt slider.val() 
          slider.val (value + 1)
        if e.keyCode is 37 
          value = parseInt slider.val()
          slider.val (value - 1)


      scope.play = ->
        scope.active = !scope.active
        if scope.active is true
          myInterval = setInterval ->
            value = parseInt slider.val()
            slider.val (value + 1)
          , 1000
        else
          clearInterval myInterval
      scope.forward = ->
        value = parseInt slider.val()
        slider.val (value + 1)
      scope.backward = ->
        value = parseInt slider.val()
        slider.val (value - 1)


  ]

