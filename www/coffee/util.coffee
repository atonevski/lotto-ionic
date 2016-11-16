angular.module 'app.util', []

# About controller
.controller 'About', ($scope) ->
  # log app version number
  console.log $scope.appVersion

angular.module 'app.util'
  .factory 'util', () ->
    
    GS_KEY ='1R5S3ZZg1ypygf_fpRoWnsYmeqnNI2ZVosQh2nJ3Aqm0'
    GS_URL = "https://spreadsheets.google.com/"
    RES_RE =  /^([^(]+?\()(.*)\);$/g

    fac =
      GS_KEY:   GS_KEY
      GS_URL:   GS_URL
      RES_RE:   RES_RE
      thou_sep: (n) -> # use second argument = 'mk' if mkd notation
        n = n.toString()
        n = n.replace /(\d+?)(?=(\d{3})+(\D|$))/g, '$1,'
        return n unless arguments.length > 1
        if arguments[1] is 'mk'
          n = n.replace /\./g, ';'
          n = n.replace /,/g, '.'
          n = n.replace /;/g, ','
        n # return this value

      # res.table.row[i]; string/text values are not eval-ed
      eval_row: (r) ->
          r.c.map (c)->
            if c.f?
              if typeof(c.v) == 'string' && c.v.match /^Date/
                eval 'new ' + c.v
              else
                eval c.v
            else
              c.v

      yesterday: () -> # day before current day (today)
        y = new Date
        y.setDate(y.getDate() - 1)
        y.setHours 0
        y.setMinutes 0
        y.setSeconds 0
        y

      nextDraw: (d) ->
        throw "nextDraw(); argument error" unless d
        throw "Not a valid draw: #{ d }" unless d.draw? or d.date?
        date = new Date d.date
        switch date.getDay()
          when 3 then date.setDate(date.getDate() + 3)
          when 6 then date.setDate(date.getDate() + 4)
          else throw "Invalid draw date: #{ d.date }"
        if date.getFullYear() == d.date.getFullYear()
          { draw: d.draw + 1, date: date }
        else
          { draw: 1, date: date }
