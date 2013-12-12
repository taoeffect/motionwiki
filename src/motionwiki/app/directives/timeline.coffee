## Timeline Directive

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_directives').directive 'mwTimeline', [ ->
    templateUrl: '/includes/templates/directives/timeline.html'
    restrict: 'E'
    link: (scope, element, attrs)->
      console.log "timeline directive"


      slider = $('#sample-change-keypress')
      input = $('#input-with-keypress')

      console.log slider

      slider.noUiSlider
        range: [20,80]
        start: 40
        handles: 1
        serialization:
          resolution: 1
          to: input

      input.keydown (e)->
        value = parseInt slider.val()
        switch(e.which)
          when 38
            slider.val (value + 1)
          when 40
            slider.val(value - 1)
  ]

