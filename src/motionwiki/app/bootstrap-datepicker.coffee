# =========================================================
# * bootstrap-datepicker.js 
# * http://www.eyecon.ro/bootstrap-datepicker
# * =========================================================
# * Copyright 2012 Stefan Petre
# *
# * Licensed under the Apache License, Version 2.0 (the "License");
# * you may not use this file except in compliance with the License.
# * You may obtain a copy of the License at
# *
# * http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# * ========================================================= 
not ($) ->
  
  # Picker object
  Datepicker = (element, options) ->
    @element = $(element)
    @format = DPGlobal.parseFormat(options.format or @element.data("date-format") or "mm/dd/yyyy")
    @picker = $(DPGlobal.template).appendTo("div.mw_wrapper").on(click: $.proxy(@click, this)) #,
    #mousedown: $.proxy(this.mousedown, this)
    @isInput = @element.is("input")
    @component = (if @element.is(".date") then @element.find(".add-on") else false)
    if @isInput
      @element.on
        focus: $.proxy(@show, this)
        
        #blur: $.proxy(this.hide, this),
        keyup: $.proxy(@update, this)

    else
      if @component
        @component.on "click", $.proxy(@show, this)
      else
        @element.on "click", $.proxy(@show, this)
    @minViewMode = options.minViewMode or @element.data("date-minviewmode") or 0
    if typeof @minViewMode is "string"
      switch @minViewMode
        when "months"
          @minViewMode = 1
        when "years"
          @minViewMode = 2
        else
          @minViewMode = 0
    @viewMode = options.viewMode or @element.data("date-viewmode") or 0
    if typeof @viewMode is "string"
      switch @viewMode
        when "months"
          @viewMode = 1
        when "years"
          @viewMode = 2
        else
          @viewMode = 0
    @startViewMode = @viewMode
    @weekStart = options.weekStart or @element.data("date-weekstart") or 0
    @weekEnd = (if @weekStart is 0 then 6 else @weekStart - 1)
    @onRender = options.onRender
    @fillDow()
    @fillMonths()
    @update()
    @showMode()

  Datepicker:: =
    constructor: Datepicker
    show: (e) ->
      @picker.show()
      @height = (if @component then @component.outerHeight() else @element.outerHeight())
      @place()
      $(window).on "resize", $.proxy(@place, this)
      if e
        e.stopPropagation()
        e.preventDefault()
      @isInput
      that = this
      $(document).on "mousedown", (ev) ->
        that.hide()  if $(ev.target).closest(".datepicker").length is 0

      @element.trigger
        type: "show"
        date: @date


    hide: ->
      @picker.hide()
      $(window).off "resize", @place
      @viewMode = @startViewMode
      @showMode()
      $(document).off "mousedown", @hide  unless @isInput
      
      #this.set();
      @element.trigger
        type: "hide"
        date: @date


    set: ->
      formated = DPGlobal.formatDate(@date, @format)
      unless @isInput
        @element.find("input").prop "value", formated  if @component
        @element.data "date", formated
      else
        @element.prop "value", formated

    setValue: (newDate) ->
      if typeof newDate is "string"
        @date = DPGlobal.parseDate(newDate, @format)
      else
        @date = new Date(newDate)
      @set()
      @viewDate = new Date(@date.getFullYear(), @date.getMonth(), 1, 0, 0, 0, 0)
      @fill()

    place: ->
      offset = (if @component then @component.offset() else @element.offset())
      @picker.css
        top: offset.top + @height
        left: offset.left


    update: (newDate) ->
      @date = DPGlobal.parseDate((if typeof newDate is "string" then newDate else ((if @isInput then @element.prop("value") else @element.data("date")))), @format)
      @viewDate = new Date(@date.getFullYear(), @date.getMonth(), 1, 0, 0, 0, 0)
      @fill()

    fillDow: ->
      dowCnt = @weekStart
      html = "<tr>"
      html += "<th class=\"dow\">" + DPGlobal.dates.daysMin[(dowCnt++) % 7] + "</th>"  while dowCnt < @weekStart + 7
      html += "</tr>"
      @picker.find(".datepicker-days thead").append html

    fillMonths: ->
      html = ""
      i = 0
      html += "<span class=\"month\">" + DPGlobal.dates.monthsShort[i++] + "</span>"  while i < 12
      @picker.find(".datepicker-months td").append html

    fill: ->
      d = new Date(@viewDate)
      year = d.getFullYear()
      month = d.getMonth()
      currentDate = @date.valueOf()
      @picker.find(".datepicker-days th:eq(1)").text DPGlobal.dates.months[month] + " " + year
      prevMonth = new Date(year, month - 1, 28, 0, 0, 0, 0)
      day = DPGlobal.getDaysInMonth(prevMonth.getFullYear(), prevMonth.getMonth())
      prevMonth.setDate day
      prevMonth.setDate day - (prevMonth.getDay() - @weekStart + 7) % 7
      nextMonth = new Date(prevMonth)
      nextMonth.setDate nextMonth.getDate() + 42
      nextMonth = nextMonth.valueOf()
      html = []
      clsName = undefined
      prevY = undefined
      prevM = undefined
      while prevMonth.valueOf() < nextMonth
        html.push "<tr>"  if prevMonth.getDay() is @weekStart
        clsName = @onRender(prevMonth)
        prevY = prevMonth.getFullYear()
        prevM = prevMonth.getMonth()
        if (prevM < month and prevY is year) or prevY < year
          clsName += " old"
        else clsName += " new"  if (prevM > month and prevY is year) or prevY > year
        clsName += " active"  if prevMonth.valueOf() is currentDate
        html.push "<td class=\"day " + clsName + "\">" + prevMonth.getDate() + "</td>"
        html.push "</tr>"  if prevMonth.getDay() is @weekEnd
        prevMonth.setDate prevMonth.getDate() + 1
      @picker.find(".datepicker-days tbody").empty().append html.join("")
      currentYear = @date.getFullYear()
      months = @picker.find(".datepicker-months").find("th:eq(1)").text(year).end().find("span").removeClass("active")
      months.eq(@date.getMonth()).addClass "active"  if currentYear is year
      html = ""
      year = parseInt(year / 10, 10) * 10
      yearCont = @picker.find(".datepicker-years").find("th:eq(1)").text(year + "-" + (year + 9)).end().find("td")
      year -= 1
      i = -1

      while i < 11
        html += "<span class=\"year" + ((if i is -1 or i is 10 then " old" else "")) + ((if currentYear is year then " active" else "")) + "\">" + year + "</span>"
        year += 1
        i++
      yearCont.html html

    click: (e) ->
      e.stopPropagation()
      e.preventDefault()
      target = $(e.target).closest("span, td, th")
      if target.length is 1
        switch target[0].nodeName.toLowerCase()
          when "th"
            switch target[0].className
              when "switch"
                @showMode 1
              when "prev", "next"
                @viewDate["set" + DPGlobal.modes[@viewMode].navFnc].call @viewDate, @viewDate["get" + DPGlobal.modes[@viewMode].navFnc].call(@viewDate) + DPGlobal.modes[@viewMode].navStep * ((if target[0].className is "prev" then -1 else 1))
                @fill()
                @set()
          when "span"
            if target.is(".month")
              month = target.parent().find("span").index(target)
              @viewDate.setMonth month
            else
              year = parseInt(target.text(), 10) or 0
              @viewDate.setFullYear year
            if @viewMode isnt 0
              @date = new Date(@viewDate)
              @element.trigger
                type: "changeDate"
                date: @date
                viewMode: DPGlobal.modes[@viewMode].clsName

            @showMode -1
            @fill()
            @set()
          when "td"
            if target.is(".day") and not target.is(".disabled")
              day = parseInt(target.text(), 10) or 1
              month = @viewDate.getMonth()
              if target.is(".old")
                month -= 1
              else month += 1  if target.is(".new")
              year = @viewDate.getFullYear()
              @date = new Date(year, month, day, 0, 0, 0, 0)
              @viewDate = new Date(year, month, Math.min(28, day), 0, 0, 0, 0)
              @fill()
              @set()
              @element.trigger
                type: "changeDate"
                date: @date
                viewMode: DPGlobal.modes[@viewMode].clsName


    mousedown: (e) ->
      e.stopPropagation()
      e.preventDefault()

    showMode: (dir) ->
      @viewMode = Math.max(@minViewMode, Math.min(2, @viewMode + dir))  if dir
      @picker.find(">div").hide().filter(".datepicker-" + DPGlobal.modes[@viewMode].clsName).show()

  $.fn.datepicker = (option, val) ->
    @each ->
      $this = $(this)
      data = $this.data("datepicker")
      options = typeof option is "object" and option
      $this.data "datepicker", (data = new Datepicker(this, $.extend({}, $.fn.datepicker.defaults, options)))  unless data
      data[option] val  if typeof option is "string"


  $.fn.datepicker.defaults = onRender: (date) ->
    ""

  $.fn.datepicker.Constructor = Datepicker
  DPGlobal =
    modes: [
      clsName: "days"
      navFnc: "Month"
      navStep: 1
    ,
      clsName: "months"
      navFnc: "FullYear"
      navStep: 1
    ,
      clsName: "years"
      navFnc: "FullYear"
      navStep: 10
    ]
    dates:
      days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      daysShort: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
      daysMin: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
      months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
      monthsShort: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    isLeapYear: (year) ->
      ((year % 4 is 0) and (year % 100 isnt 0)) or (year % 400 is 0)

    getDaysInMonth: (year, month) ->
      [31, ((if DPGlobal.isLeapYear(year) then 29 else 28)), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month]

    parseFormat: (format) ->
      separator = format.match(/[.\/\-\s].*?/)
      parts = format.split(/\W+/)
      throw new Error("Invalid date format.")  if not separator or not parts or parts.length is 0
      separator: separator
      parts: parts

    parseDate: (date, format) ->
      parts = date.split(format.separator)
      date = new Date()
      val = undefined
      date.setHours 0
      date.setMinutes 0
      date.setSeconds 0
      date.setMilliseconds 0
      if parts.length is format.parts.length
        year = date.getFullYear()
        day = date.getDate()
        month = date.getMonth()
        i = 0
        cnt = format.parts.length

        while i < cnt
          val = parseInt(parts[i], 10) or 1
          switch format.parts[i]
            when "dd", "d"
              day = val
              date.setDate val
            when "mm", "m"
              month = val - 1
              date.setMonth val - 1
            when "yy"
              year = 2000 + val
              date.setFullYear 2000 + val
            when "yyyy"
              year = val
              date.setFullYear val
          i++
        date = new Date(year, month, day, 0, 0, 0)
      date

    formatDate: (date, format) ->
      val =
        d: date.getDate()
        m: date.getMonth() + 1
        yy: date.getFullYear().toString().substring(2)
        yyyy: date.getFullYear()

      val.dd = ((if val.d < 10 then "0" else "")) + val.d
      val.mm = ((if val.m < 10 then "0" else "")) + val.m
      date = []
      i = 0
      cnt = format.parts.length

      while i < cnt
        date.push val[format.parts[i]]
        i++
      date.join format.separator

    headTemplate: "<thead>" + "<tr>" + "<th class=\"prev\">&lsaquo;</th>" + "<th colspan=\"5\" class=\"switch\"></th>" + "<th class=\"next\">&rsaquo;</th>" + "</tr>" + "</thead>"
    contTemplate: "<tbody><tr><td colspan=\"7\"></td></tr></tbody>"

  DPGlobal.template = "<div class=\"datepicker dropdown-menu\">" + "<div class=\"datepicker-days\">" + "<table class=\" table-condensed\">" + DPGlobal.headTemplate + "<tbody></tbody>" + "</table>" + "</div>" + "<div class=\"datepicker-months\">" + "<table class=\"table-condensed\">" + DPGlobal.headTemplate + DPGlobal.contTemplate + "</table>" + "</div>" + "<div class=\"datepicker-years\">" + "<table class=\"table-condensed\">" + DPGlobal.headTemplate + DPGlobal.contTemplate + "</table>" + "</div>" + "</div>"
(window.jQuery)