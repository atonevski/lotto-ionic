# Ionic Starter App

# angular.module is a global place for creating, registering and retrieving Angular modules
# 'starter' is the name of this angular module example (also set in a <body> attribute in index.html)
# the 2nd parameter is an array of 'requires'
angular.module 'app', ['ionic', 'app.util', 'app.upload', 'app.annual',
        'app.weekly', 'app.stats']
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
           .state 'stats', {
             url:          '/stats'
             templateUrl:  'views/stats/home.html'
           }
           .state 'lotto-stats', {
             url:          '/stats/lotto'
             templateUrl:  'views/stats/lfreqs.html'
             controller:   'LottoStats'
           }
           .state 'joker-stats', {
             url:          '/stats/joker'
             templateUrl:  'views/stats/jfreqs.html'
             controller:   'JokerStats'
           }
           .state 'winners-stats', {
             url:          '/stats/winners'
             templateUrl:  'views/stats/winners.html'
             controller:   'WinnersStats'
           }
           .state 'upload', {
             url:          '/upload'
             templateUrl:  'views/upload/upload.html'
             controller:   'Upload'
           }
           .state 'about', {
             url:          '/about'
             templateUrl:  'views/about/about.html'
             controller:   'About'
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

.controller 'Main', ($scope, $rootScope, $http, util) ->
  $scope.thou_sep = util.thou_sep # export to all child conotrollers

  to_json = (d) -> # convert google query response to json
    re =  /^([^(]+?\()(.*)\);$/g
    match = re.exec d
    JSON.parse match[2]

  # some global vars, and functions
  $scope.to_json      = to_json
  $scope.uploadNeeded = no
  $scope.GS_KEY       = util.GS_KEY
  $scope.GS_URL       = util.GS_URL
  $scope.RES_RE       = util.RES_RE
  $scope.eval_row     = util.eval_row
  $scope.yesterday    = util.yesterday
  $scope.nextDraw     = util.nextDraw

  # get last year
  $scope.qurl = (q) -> "#{ $scope.GS_URL }tq?tqx=out:json&key=#{ $scope.GS_KEY }" +
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

  # check for upload
  $scope.checkUpload = () ->
    unless $scope.lastDraw?
      # $scope.uploadNeeded = no # since we can't know 
      $scope.uploadNeeded = no # since we can't know 
      return no
    
    nextd = $scope.nextDraw $scope.lastDraw
    $scope.uploadNeeded = (nextd.date <= $scope.yesterday())
  
  # we watch on lastDraw
  $rootScope.$watch 'lastDraw', (n, o) -> # old and new values
    if n
      if $rootScope.uploadNeeded?
        $scope.uploadNeeded = $rootScope.uploadNeeded
      else
        $scope.checkUpload()

  # get last draw number & date
  q = 'SELECT A, B ORDER BY B DESC LIMIT 1'
  $http.get $scope.qurl(q)
    .success (data, status) ->
      res = $scope.to_json data
      r = $scope.eval_row res.table.rows[0]
      $scope.lastDraw =
        draw: r[0]
        date: new Date r[1]
      $rootScope.lastDraw =
        draw: r[0]
        date: new Date r[1]
      $scope.checkUpload()
          
# .controller 'LottoStats', ($scope, $http, $ionicLoading) ->
#   $scope.hideChart = true
#   $scope.sbarChart = { }
#   $scope.sbarChart.title  = 'Bar chart title'
#   $scope.sbarChart.width  = $scope.width
#   $scope.sbarChart.height = $scope.height
# 
#   # A: draw #, B: date, P..W: winning column lotto, X: winning column joker
#   query = """SELECT A, B, P, Q, R, S, T, U, V, W
#              ORDER BY B"""
#   $ionicLoading.show()
#   $http.get $scope.qurl(query)
#     .success (data, status) ->
#       res = $scope.to_json data
#       $scope.winColumns = res.table.rows.map (r) ->
#         a = $scope.eval_row r
#         {
#           draw:   a[0]
#           date:   a[1]
#           lotto:  [ a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9] ]
#         }
#       $buildLottoFreqs()
#       $ionicLoading.hide()
#     .error (err) ->
#       $ionicLoading.show({
#         template: "Не може да се вчитаат добитните комбинации. Пробај подоцна."
#         duration: 3000
#       })
# 
#   # change this method to have a parameter 'all', 'stresa', 'venus'
#   # and to produce different tables
#   $buildLottoFreqs = () ->
#     arr = [0..34].map (e) -> ([0..7].map () -> 0)
#     for row in $scope.winColumns
#       for i, n of row.lotto
#         arr[n][i]++
#     for i, a of arr
#       arr[i].push a.reduce (t, e) -> t + e
#     $scope.freqs = arr[1..-1].map (a, i) ->
#         {
#           number: (i + 1)
#           '1ви':  a[0]
#           '2ри':  a[1]
#           '3ти':  a[2]
#           '4ти':  a[3]
#           '5ти':  a[4]
#           '6ти':  a[5]
#           '7ми':  a[6]
#           'доп.': a[7]
#           total:  a[8]
#         }
#     $scope.sbarChart.data   = $scope.freqs
#     $scope.sbarChart.labels = 'number'
#     $scope.sbarChart.labVals = [1..34].filter (v) -> v%2 isnt 0
#     $scope.sbarChart.categories = [
#       '1ви', '2ри', '3ти', '4ти', '5ти', '6ти', '7ми', 'доп.'
#     ]
# 
# .controller 'JokerStats', ($scope, $http, $ionicLoading) ->
#   $scope.hideChart = true
#   $scope.sbarChart = { }
#   $scope.sbarChart.title  = 'Bar chart title'
#   $scope.sbarChart.width  = $scope.width
#   $scope.sbarChart.height = $scope.height
# 
#   # A: draw #, B: date, P..W: winning column lotto, X: winning column joker
#   query = """SELECT A, B, X
#              ORDER BY B"""
#   $ionicLoading.show()
#   $http.get $scope.qurl(query)
#     .success (data, status) ->
#       res = $scope.to_json data
#       $scope.winColumns = res.table.rows.map (r) ->
#         a = $scope.eval_row r
#         {
#           draw:   a[0]
#           date:   a[1]
#           joker:  a[2].split ''
#         }
#       $buildJokerFreqs()
#       $ionicLoading.hide()
#     .error (err) ->
#       $ionicLoading.show({
#         template: "Не може да се вчитаат добитните комбинации. Пробај подоцна."
#         duration: 3000
#       })
# 
#   # change this method to have a parameter 'all', 'stresa', 'venus'
#   # and to produce different tables
#   $buildJokerFreqs = () ->
#     arr = [0..9].map (e) -> ([0..5].map () -> 0)
#     for row in $scope.winColumns
#       for i, n of row.joker
#         arr[n][i]++
#     for i, a of arr
#       arr[i].push a.reduce (t, e) -> t + e
#     $scope.freqs = arr.map (a, i) ->
#         {
#           number: i
#           '1ви':  a[0]
#           '2ри':  a[1]
#           '3ти':  a[2]
#           '4ти':  a[3]
#           '5ти':  a[4]
#           '6ти':  a[5]
#           total:  a[6]
#         }
#     $scope.sbarChart.data   = $scope.freqs
#     $scope.sbarChart.labels = 'number'
#     # $scope.sbarChart.labVals = [1..34].filter (v) -> v%2 isnt 0
#     $scope.sbarChart.categories = [
#       '1ви', '2ри', '3ти', '4ти', '5ти', '6ти' ]
# 
# .controller 'WinnersStats', ($scope, $http, $ionicLoading, $ionicPosition, $ionicScrollDelegate) ->
#   $scope.bubbleVisible = no
#   $scope.bubble = d3.select '#stats-list'
#                     .append 'div'
#                     .attr 'class', 'bubble bubble-left'
#                     .attr 'id', 'winners-bubble'
#                     .on('click', ()->
#                       $scope.bubble.transition().duration 1000
#                             .style 'opacity', 0
#                       $scope.bubbleVisible = no
#                     )
#                     .style 'opacity', 0
# 
#   $scope.showBubble = (event, idx) ->
# 
#     return if $scope.bubbleVisible
#     event.stopPropagation()
#     $scope.bubbleVisible = yes
# 
#     t = """
#       <div class='row row-no-padding'>
#         <div class='col col-offset-80 text-right positive'>
#           <small><i class='ion-close-round'></i></small>
#         </div>
#       </div>
#       <dl class='dl-horizontal'>
#         <dt>Година:</dt>
#         <dd>#{ $scope.winners[idx].year }</dd>
#         <dt>Вкупно кола:</dt>
#         <dd>#{ $scope.winners[idx].draws }</dd>
#         <hr />
#         <dt>Лото:</dt><dd></dd>
#         <hr />
#         <dt>Најмала уплата:</dt>
#         <dd>#{ $scope.thou_sep $scope.winners[idx].min }</dd>
#         <dt>Просечна уплата:</dt>
#         <dd>#{ $scope.thou_sep $scope.winners[idx].avg }</dd>
#         <dt>Најголема уплата:</dt>
#         <dd>#{ $scope.thou_sep $scope.winners[idx].max }</dd>
#         <hr />
#         <dt>Џокер:</dt><dd></dd>
#         <hr />
#         <dt>Најмала уплата:</dt>
#         <dd>#{ $scope.thou_sep $scope.winners[idx].jmin }</dd>
#         <dt>Просечна уплата:</dt>
#         <dd>#{ $scope.thou_sep $scope.winners[idx].javg }</dd>
#         <dt>Најголема уплата:</dt>
#         <dd>#{ $scope.thou_sep $scope.winners[idx].jmax }</dd>
#       </dl>
#     """
# 
#     el = angular.element document.querySelector "\#winners-#{$scope.winners[idx].year}"
#     offset = $ionicPosition.offset el
#     new_top = offset.top + $ionicScrollDelegate.getScrollPosition().top
#     $scope.bubble.html t
#           .style 'left', (event.pageX + 10) + 'px'
#           .style 'top', (new_top - 60) + 'px'
#           .style 'opacity', 1
#     
# 
#   # load data
#   $ionicLoading.show()
#   # count x7
#   qx7 = """
#       SELECT
#         YEAR(B), COUNT(D)
#       WHERE D > 0
#       GROUP BY YEAR(B)
#       ORDER BY YEAR(B)
#     """
#   $http.get $scope.qurl(qx7)
#     .success (data, status) ->
#       res = $scope.to_json data
#       $scope.winX7 = { }
#       res.table.rows.forEach (r) ->
#         a = $scope.eval_row r
#         $scope.winX7[a[0]] = a[1]
#     .error (err) ->
#       $ionicLoading.show({
#         template: "Не може да се вчитаат добитници x7. Пробај подоцна."
#         duration: 3000
#       })
# 
#   # count x6p
#   qx6p= """
#       SELECT
#         YEAR(B), COUNT(E)
#       WHERE E > 0
#       GROUP BY YEAR(B)
#       ORDER BY YEAR(B)
#     """
#   $http.get $scope.qurl(qx6p)
#     .success (data, status) ->
#       res = $scope.to_json data
#       $scope.winX6p = { }
#       res.table.rows.forEach (r) ->
#         a = $scope.eval_row r
#         $scope.winX6p[a[0]] = a[1]
#     .error (err) ->
#       $ionicLoading.show({
#         template: "Не може да се вчитаат добитници x6+1. Пробај подоцна."
#         duration: 3000
#       })
# 
#   # count x6
#   qx6 = """
#       SELECT
#         YEAR(B), COUNT(F)
#       WHERE F > 0
#       GROUP BY YEAR(B)
#       ORDER BY YEAR(B)
#     """
#   $http.get $scope.qurl(qx6)
#     .success (data, status) ->
#       res = $scope.to_json data
#       $scope.winX6 = { }
#       res.table.rows.forEach (r) ->
#         a = $scope.eval_row r
#         $scope.winX6[a[0]] = a[1]
#     .error (err) ->
#       $ionicLoading.show({
#         template: "Не може да се вчитаат добитници x6. Пробај подоцна."
#         duration: 3000
#       })
# 
#   # A: draw #, B: date, P..W: winning column lotto, X: winning column joker
#   query = """
#       SELECT 
#         YEAR(B), COUNT(A), MIN(C), MAX(C), AVG(C),
#         SUM(D), SUM(E), AVG(F), AVG(G), AVG(H),
#         MIN(I), MAX(I), AVG(I)
#       GROUP BY YEAR(B)
#       ORDER BY YEAR(B)
#     """
#   $http.get $scope.qurl(query)
#     .success (data, status) ->
#       res = $scope.to_json data
#       $scope.winners = res.table.rows.map (r) ->
#         a = $scope.eval_row r
#         {
#           year:   a[0]
#           draws:  a[1]
# 
#           min:    a[2]
#           max:    a[3]
#           avg:    Math.round a[4]
#           jmin:   a[10]
#           jmax:   a[11]
#           javg:   Math.round a[12]
# 
#           x7:     a[5]
#           'x6+1': a[6]
#           x6:     Math.round a[7]
#           x5:     Math.round a[8]
#           x4:     Math.round a[9]
#         }
#       $ionicLoading.hide()
#     .error (err) ->
#       $ionicLoading.show({
#         template: "Не може да се вчита статистика на добитници. Пробај подоцна."
#         duration: 3000
#       })

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
      margin = { top: 35, right: 120, bottom: 30, left: 40 }

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
                 .tickFormat((d) ->
                    if d > 100000.0
                      Math.round(d/10000)/100 + " M"
                    else
                      scope.thou_sep d
                   )
                 .orient 'left'

      x = d3.scale.ordinal().rangeRoundBands [0, scope.sbarChart.width], 0.3, 0.2
      xAxis = d3.svg.axis().scale(x).orient 'bottom'
      xAxis.tickValues scope.sbarChart.labVals if scope.sbarChart.labVals?

      x.domain stacked[0].map (d) -> d.x
      svg.append 'g'
         .attr 'class', 'x axis'
         .attr 'transform', "translate(0, #{scope.sbarChart.height})"
         .call xAxis

      y.domain [0, d3.max(stacked[-1..][0], (d) -> return d.y0 + d.y)]
      svg.append 'g'
         .attr 'class', 'y axis'
         .transition().duration 1000
         .call yAxis
         .selectAll('line')
         .style "stroke-dasharray", "3, 3"

      color = d3.scale.category20()
      
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
           # d3.select "\##{ d.cat }-#{ d.x }"
           #    .style 'opacity', 0.85
           #    .transition().duration(1500).ease 'exp'
           #    .style 'opacity', 1

           t = """
              <p style='text-align: center;'>
                <b>#{ d.cat }/#{ d.x }</b>
                <hr /></p>
              <p style='text-align: center'>  
                #{ scope.thou_sep(d.y) }
              </p>
           """
           tooltip.html ''
           tooltip.transition().duration 1000
                  .style 'opacity', 0.75
           tooltip.html t
                  .style 'left', (d3.event.pageX + 10) + 'px'
                  .style 'top', (d3.event.pageY - 75) + 'px'
                  .style 'opacity', 1
           tooltip.transition().duration 3000
                  .style 'opacity', 0
           )
         .append 'title'
         .html (d) -> "<strong>#{ d.cat }/#{ d.x }</strong>: #{ scope.thou_sep(d.y) }"

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
      margin = { top: 35, right: 120, bottom: 30, left: 40 }

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
      ymax = d3.max scope.series.map (s) -> d3.max(s.data.map (d) -> d.y)
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
      
      svg.append 'text'
         .attr 'x', scope.lineChart.width/2
         .attr 'y', y(20 + ymax)
         .attr 'dy', '-0.35em'
         .attr 'text-anchor', 'middle'
         .attr 'class', 'line-chart-title'
         .text scope.lineChart.title

      line = d3.svg.line()
               .interpolate("monotone")
               .x (d) -> x(d.x)
               .y (d) -> y(d.y)

      win = []
      for i, s of scope.series
        svg.append 'path'
          .datum s.data
          .attr 'class', 'line'
          .attr 'stroke', d3.scale.category10().range()[i]
          .attr 'd', line
        win[i] = s.data.filter (d) ->d.lx7 > 0

      for i, w of win
        for ww in w
          d = [ { x: ww.x, y: 0, draw: ww.draw }, ww ]
          svg.append 'path'
             .datum d
             .attr 'id', "draw-#{ ww.draw }"
             .attr 'class', 'line'
             # .attr 'stroke-dasharray', "3, 3"
             .attr 'stroke', d3.scale.category10().range()[i]
             .attr 'stroke-dasharray', '0.8 1.6'
             .on 'click', (d, i) ->
                t = """
                  <p style='text-align: center;'>
                    <b>коло: #{ d[1].draw }</b><br />
                  </p>
                """
                tooltip.html t
                tooltip.transition().duration 1000
                        .style 'opacity', 0.75
                tooltip.html t
                        .style 'left', (d3.event.pageX) + 'px'
                        .style 'top', (d3.event.pageY-60) + 'px'
                        .style 'opacity', 1
                tooltip.transition().duration 3500
                        .style 'opacity', 0
             .attr 'd', line
             .append 'title'
             .html (d, i) -> "<strong>коло: #{ d[1].draw }</strong>"

      # hints for x7, 1st prize winners

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
