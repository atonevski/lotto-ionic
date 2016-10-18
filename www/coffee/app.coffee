# Ionic Starter App

# angular.module is a global place for creating, registering and retrieving Angular modules
# 'starter' is the name of this angular module example (also set in a <body> attribute in index.html)
# the 2nd parameter is an array of 'requires'
angular.module 'app', ['ionic']
.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state 'home', {
      url:          '/home'
      templateUrl:  'views/home/home.html'
    }
    .state 'root', {
      url:          '/'
      templateUrl:  'views/home/home.html'
    }
    .state 'annual', {
      url:          '/annual'
      templateUrl:  'views/annual/annual.html'
      controller:   'Annual'
    }
    .state 'weekly', {
      url:          '/weekly/:year'
      templateUrl:  'views/weekly/weekly.html'
      controller:   'Weekly'
    }
  $urlRouterProvider.otherwise '/home'
.run ($ionicPlatform) ->
  $ionicPlatform.ready () ->
    if window.cordova && window.cordova.plugins.Keyboard
      # Hide the accessory bar by default (remove this to
      # show the accessory bar above the keyboard
      # for form inputs)g
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar true

      # Don't remove this line unless you know what you are doing. It stops the viewport
      # from snapping when text inputs are focused. Ionic handles this internally for
      # a much nicer keyboard experience.
      cordova.plugins.Keyboard.disableScroll true
    if window.StatusBar
      StatusBar.styleDefault()

.controller 'Main', ($scope, $http) ->
  $scope.thou_sep = (n) ->
    n = n.toString()
    n = n.replace /(\d+?)(?=(\d{3})+(\D|$))/g, '$1,'
    return n unless arguments.length > 1
    if arguments[1] is 'mk'
      n = n.replace /\./g, ';'
      n = n.replace /,/g, '.'
      n = n.replace /;/g, ','
    n # return this value

  to_json = (d) -> # convert google query response to json
    re =  /^([^(]+?\()(.*)\);$/g
    match = re.exec d
    JSON.parse match[2]

  # res.table.row[i]; string/text values are not eval-ed
  eval_row = (r) -> r.c.map (c)->
                      if c.f?
                        if typeof(c.v) == 'string' && c.v.match /^Date/
                          eval 'new ' + c.v
                        else
                          eval c.v
                      else
                        c.v

  $scope.KEY ='1R5S3ZZg1ypygf_fpRoWnsYmeqnNI2ZVosQh2nJ3Aqm0'
  $scope.URL = "https://spreadsheets.google.com/"
  $scope.RE  =  /^([^(]+?\()(.*)\);$/g
  $scope.to_json  = to_json
  $scope.eval_row = eval_row
  $scope.qurl = (q) -> "#{ $scope.URL }tq?tqx=out:json&key=#{ $scope.KEY }" +
                "&tq=#{ encodeURI q }"
  query = 'SELECT YEAR(B) ORDER BY YEAR(B) DESC LIMIT 1'
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.lastYear = ($scope.eval_row res.table.rows[0])[0]

  # device width/height
  $scope.width  = window.innerWidth
  $scope.height = window.innerHeight
  console.log "WxH: #{ window.innerWidth }x#{ window.innerHeight }"

.controller 'Annual', ($scope, $http, $ionicPopup, $timeout) ->
  # bar chart
  $scope.hideChart = true
  $scope.sbarChart = { }
  $scope.sbarChart.title  = 'Bar chart title'
  $scope.sbarChart.width  = $scope.width
  $scope.sbarChart.height = $scope.height
  
  query = 'SELECT YEAR(B), COUNT(A), SUM(C), SUM(I) GROUP BY YEAR(B) ORDER BY YEAR(B)'
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.sales = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          year:     a[0]
          draws:    a[1]
          'лото':   a[2]
          'џокер':  a[3]
        }
      $scope.sbarChart.data   = $scope.sales
      $scope.sbarChart.labels = 'year'
      $scope.sbarChart.categories = ['лото', 'џокер']
          
.controller 'Weekly', ($scope, $http, $stateParams) ->
  # line chart
  $scope.hideChart = true
  $scope.lineChart = { }
  $scope.lineChart.width  = $scope.width
  $scope.lineChart.height = $scope.height

  # since ng-if not working
  $scope.lineChart.hide = true

  $scope.dow_to_mk = (d) ->
    switch Math.floor d
      when 1 then 'недела'
      when 2 then 'понеделник'
      when 3 then 'вторник'
      when 4 then 'среда'
      when 5 then 'четврток'
      when 6 then 'петок'
      when 7 then 'сабота'
      else ''

  $scope.dow_to_en = (d) ->
    switch Math.floor d
      when 1 then 'Sunday'
      when 2 then 'Monday'
      when 3 then 'Tuesday'
      when 4 then 'Wednesday'
      when 5 then 'Thursday'
      when 6 then 'Friday'
      when 7 then 'Saturday'
      else "*#{ d }*"

  $scope.year = parseInt $stateParams.year
  # A: draw #, B: date, C: lotto sales, D: x7 (lotto), I: joker sales, J: x6 (joker)
  queryYear = """SELECT A, dayOfWeek(B), 
                        C, I, B, D, J
                 WHERE YEAR(B) = #{ $scope.year }
                 ORDER BY A"""
  $http.get $scope.qurl(queryYear)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.sales = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          draw:   a[0]
          dow:    a[1]
          lotto:  a[2]
          joker:  a[3]
          date:   a[4]
          lx7:    a[5]
          jx6:    a[6]
        }
      $scope.buildSeries()

  # build line chart series (only lotto sales)
  $scope.buildSeries = () ->
    arr = [[], [],  [], [], [], [], [], [] ]
    for sale in $scope.sales
      arr[sale.dow].push { x: sale.date, y: sale.lotto }
    series = [ ]
    for i, a of arr
      if arr[i].length > 0
        series.push { name: $scope.dow_to_mk(i), data: arr[i] }
    $scope.series = series
        


  query = "SELECT YEAR(B), COUNT(A) GROUP BY YEAR(B) ORDER BY YEAR(B)"
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.years = res.table.rows.map (r) ->
        a = $scope.eval_row r
        { year: a[0], draws: a[1] }
      $scope.select = ($scope.years.filter (x) -> x.year is $scope.year)[0]
  $scope.newSelection = (v) ->
    $scope.lineChart.hide = true
    $scope.select = v
    $scope.year   = $scope.select.year
    queryYear = """SELECT A, dayOfWeek(B),
                          C, I, B, D, J
                   WHERE YEAR(B) = #{ $scope.year }
                   ORDER BY A"""
    # update scope.sales and scope.series
    $http.get $scope.qurl(queryYear)
      .success (data, status) ->
        res = $scope.to_json data
        $scope.sales = res.table.rows.map (r) ->
          a = $scope.eval_row r
          {
            draw:   a[0]
            dow:    a[1]
            lotto:  a[2]
            joker:  a[3]
            date:   a[4]
            lx7:    a[5]
            jx6:    a[6]
          }
        $scope.buildSeries()
        $scope.lineChart.hide = true

.directive 'barChart', () ->
  {
    restrict: 'A'
    replace:  false
    link:     (scope, el, attrs) ->
      scope.barChart.title   = attrs.title   if attrs.title?
      scope.barChart.width   = parseInt(attrs.width)   if attrs.width?
      scope.barChart.height  = parseInt(attrs.height)  if attrs.height?
      margin = { top: 15, right: 10, bottom: 40, left: 60 }
      
      svg = d3.select el[0]
              .append 'svg'
              .attr 'width', scope.barChart.width + margin.left + margin.right
              .attr 'height', scope.barChart.height + margin.top + margin.bottom
              .append 'g'
              .attr 'transform', "translate(#{margin.left}, #{margin.top})"

      y = d3.scale.linear().rangeRound [scope.barChart.height, 0]
      yAxis = d3.svg.axis().scale(y)
                 .tickFormat (d) -> Math.round(d/10000)/100 + " M"
                 .orient 'left'

      x = d3.scale.ordinal().rangeRoundBands [0, scope.barChart.width], 0.1
      xAxis = d3.svg.axis().scale(x).orient 'bottom'

      y.domain [0, d3.max(scope.barChart.data)]
      svg.append 'g'
         .attr 'class', 'y axis'
         .transition().duration 1000
         .call yAxis

      x.domain scope.barChart.labels
      svg.append 'g'
         .attr 'class', 'x axis'
         .attr 'transform', "translate(0, #{scope.barChart.height})"
         .call xAxis
     
      svg.append 'text'
         .attr 'x', x(scope.barChart.labels[Math.floor scope.barChart.labels.length/2])
         .attr 'y', y(20 + d3.max(scope.barChart.data))
         .attr 'dy', '-0.35em'
         .attr 'text-anchor', 'middle'
         .attr 'class', 'bar-chart-title'
         .text scope.barChart.title

      r = svg.selectAll '.bar'
         .data scope.barChart.data.map (d) -> Math.floor Math.random()*d
         .enter().append 'rect'
         .attr 'class', 'bar'
         .attr 'x', (d, i) -> x(scope.barChart.labels[i])
         .attr 'y', (d) -> y(d)
         .attr 'height', (d) -> scope.barChart.height - y(d)
         .attr 'width', x.rangeBand()
         .attr 'title', (d, i) -> scope.thou_sep(scope.barChart.data[i])

      r.transition().duration 1000
         .ease 'elastic'
         .attr 'y', (d, i) -> y(scope.barChart.data[i])
         .attr 'height', (d, i) -> scope.barChart.height - y(scope.barChart.data[i])
  }

.directive 'stackedBarChart', () ->
  {
    restrict: 'A'
    replace:  false
    link:     (scope, el, attrs) ->
      scope.sbarChart.title   = attrs.title             if attrs.title?
      scope.sbarChart.width   = parseInt(attrs.width)   if attrs.width?
      scope.sbarChart.height  = parseInt(attrs.height)  if attrs.height?
      margin = { top: 15, right: 120, bottom: 40, left: 40 }

      tooltip = d3.select el[0]
                  .append 'div'
                  .attr 'class', 'tooltip'
                  .style 'opacity', 0

      svg = d3.select el[0]
              .append 'svg'
              .attr 'width', scope.sbarChart.width + margin.left + margin.right
              .attr 'height', scope.sbarChart.height + margin.top + margin.bottom
              .append 'g'
              .attr 'transform', "translate(#{margin.left}, #{margin.top})"
      
      lab = scope.sbarChart.labels
      remapped = scope.sbarChart.categories.map (cat) ->
        scope.sbarChart.data.map (d, i) ->
          { x: d[lab], y: d[cat], cat: cat }

      stacked  = d3.layout.stack()(remapped)

      y = d3.scale.linear().rangeRound [scope.sbarChart.height, 0]
      yAxis = d3.svg.axis().scale(y)
                 .tickFormat (d) -> Math.round(d/10000)/100 + " M"
                 .orient 'left'

      x = d3.scale.ordinal().rangeRoundBands [0, scope.sbarChart.width], 0.1
      xAxis = d3.svg.axis().scale(x).orient 'bottom'

      x.domain stacked[0].map (d) -> d.x
      svg.append 'g'
         .attr 'class', 'x axis'
         .attr 'transform', "translate(0, #{scope.sbarChart.height})"
         .call xAxis

      y.domain [0, d3.max(stacked[-1..][0], (d) -> return d.y0 + d.y)]
      xa = svg.append 'g'
         .attr 'class', 'y axis'
         .transition().duration 1000
         .call yAxis
         .selectAll('line')
         .style("stroke-dasharray", ("3, 3"))

      # svg.append 'g'
      #    .attr 'class', 'grid'
      #    .call xa.tickSize(-scope.sbarChart.width, 0, 0).tickFormat ''

      color = d3.scale.category20c()
      
      svg.append 'text'
         .attr 'x', x(stacked[0][Math.floor stacked[0].length/2].x)
         .attr 'y', y(20 + d3.max(stacked[-1..][0], ((d) -> d.y0 + d.y)))
         .attr 'dy', '-0.35em'
         .attr 'text-anchor', 'middle'
         .attr 'class', 'bar-chart-title'
         .text scope.sbarChart.title

      g = svg.selectAll 'g.vgroup'
             .data stacked
             .enter()
             .append 'g'
             .attr 'class', 'vgroup'
             .style 'fill', (d, i) -> d3.rgb(color(i)).brighter(1.2)
             .style 'stroke', (d, i) -> d3.rgb(color(i)).darker()

      r = g.selectAll 'rect'
         .data (d) -> d
         .enter()
         .append 'rect'
         .attr 'id', (d) -> "#{ d.cat }-#{ d.x }"
         .attr 'x', (d) -> x(d.x)
         .attr 'y', (d) -> y(d.y + d.y0)
         .attr 'height', (d) -> y(d.y0) - y(d.y + d.y0)
         .attr 'width', x.rangeBand()
         .on('click', (d, i) ->
           d3.select "\##{ d.cat }-#{ d.x }"
              .style 'opacity', 0.85
              .transition().duration(1500).ease 'exp'
              .style 'opacity', 1

           t = """
            <p style='text-align: center;'>
              <b>#{ d.cat }</b><br />
              <hr />
              #{ scope.thou_sep(d.y) }
            </p>
           """
           tooltip.html ''
           tooltip.transition().duration 1000
                  .style 'opacity', 0.75
           tooltip.html t
                  .style 'left', (d3.event.pageX) + 'px'
                  .style 'top', (d3.event.pageY-60) + 'px'
                  .style 'opacity', 1
           tooltip.transition().duration 3000
                  .style 'opacity', 0
           )
         .append 'title'
         .html (d) -> "<strong>#{ d.cat }</strong>: #{ scope.thou_sep(d.y) }"

      legend = svg.append('g').attr 'class', 'legend'
      legend.selectAll '.legend-rect'
          .data scope.sbarChart.categories
          .enter()
          .append 'rect'
          .attr 'class', '.legend-rect'
          .attr('width', 16)
          .attr 'height', 16
          .attr 'x', scope.sbarChart.width + 2
          .attr 'y', (d, i) -> 20*i
          .style 'stroke', (d, i) -> d3.rgb(color(i)).darker()
          .style 'fill', (d, i) -> d3.rgb(color(i)).brighter(1.2)

      legend.selectAll 'text'
          .data scope.sbarChart.categories
          .enter()
          .append 'text'
          .attr 'class', 'legend'
          .attr 'x', scope.sbarChart.width + 24
          .attr 'y', (d, i) -> 20*i + 8
          .attr 'dy', 4
          .text (d) -> d
  }

.directive 'lineChart', () ->
  {
    restrict: 'A'
    replace:  false
    link:     (scope, el, attrs) ->
      scope.lineChart.title   = attrs.title             if attrs.title?
      scope.lineChart.width   = parseInt(attrs.width)   if attrs.width?
      scope.lineChart.height  = parseInt(attrs.height)  if attrs.height?
      margin = { top: 15, right: 120, bottom: 40, left: 40 }

      tooltip = d3.select el[0]
                  .append 'div'
                  .attr 'class', 'tooltip'
                  .style 'opacity', 0

      svg = d3.select el[0]
              .append 'svg'
              .attr 'width',  scope.lineChart.width + margin.left + margin.right
              .attr 'height', scope.lineChart.height + margin.top + margin.bottom
              .append 'g'
              .attr 'transform', "translate(#{margin.left}, #{margin.top})"
      
      y = d3.scale.linear().rangeRound [scope.lineChart.height, 0]
      yAxis = d3.svg.axis()
                .scale(y)
                .orient 'left'
      y.domain [0, d3.max scope.series.map (s) -> d3.max(s.data.map (d) -> d.y) ]
      svg.append 'g'
         .attr 'class', 'y axis'
         .transition().duration 1000
         .call yAxis

      x = d3.time.scale().range [0, scope.lineChart.width]
      xAxis = d3.svg.axis().scale(x)
                .orient 'bottom'
                .tickFormat d3.time.format("%W")

      x.domain [
        d3.min(scope.series.map((s) -> s.data[0].x)),
        d3.max(scope.series.map((s) -> s.data[-1..][0].x)),
      ]

      svg.append 'g'
         .attr 'class', 'x axis'
         .attr 'transform', "translate(0, #{scope.lineChart.height})"
         .call xAxis

      line = d3.svg.line()
               .x (d) -> x(d.x)
               .y (d) -> y(d.y)

      for i, s of scope.series
        svg.append 'path'
          .datum s.data
          .attr 'class', 'line'
          .attr 'stroke', d3.scale.category10().range()[i]
          .attr 'd', line

      legend = svg.append('g').attr 'class', 'legend'

      legend.selectAll 'text'
            .data scope.series.map (s) -> s.name
            .enter()
            .append 'text'
            .attr 'class', 'legend'
            .attr 'x', scope.lineChart.width + 4
            .attr 'y', (d, i) -> 20*i + 8
            .attr 'dy', 4
            .style 'fill', (d, i) ->d3.rgb(d3.scale.category10().range()[i]).darker(0.5)
            .text (d) -> d
  }
