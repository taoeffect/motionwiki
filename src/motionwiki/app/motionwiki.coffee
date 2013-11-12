define ['require', 'jquery', 'JSON', 'wiki/api', 'directives', 'controllers'], (require, $, JSON, api)->
  
  $('<div class="mw_wrapper">').appendTo('body > div')
  $('<div ng-app="motion_wiki" ng-controller="AppCtrl" id="motionwiki" class="mw_main" >').appendTo('.mw_wrapper')
  $('<mw-timeline>').appendTo('div#motionwiki')
  $('<mw-history-grapher>').appendTo('div#motionwiki')
  $('<mw-play-controls>').appendTo('div#motionwiki')
  
  angular.module('motion_wiki', ['mw_directives','mw_controllers']).run [ '$rootScope' , ($rootScope)->
  	console.log $rootScope
  ]
  angular.bootstrap(document.getElementById('motionwiki'),['motion_wiki'])

  

  $('<div>').text('MotionWiki Loaded! Querying wiki...').appendTo('body > div')
  api.query 'Wikipedia', (jqXHR, textStatus)->
    $('<div>').css('color',if jqXHR.status < 300 then 'green' else 'red')
    .html(textStatus + ": <pre style='width:400'>" + JSON.stringify(jqXHR,false,100) + "</pre>")
    .appendTo('body > div')
