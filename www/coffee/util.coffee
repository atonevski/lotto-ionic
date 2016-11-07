angular.module 'app.util', []

.controller 'About', ($scope, $http) ->
  $scope.URL = "http://test.lotarija.mk/Results/WebService.asmx/GetDetailedReport"
  $scope.appendURL = "https://script.google.com/macros/s/AKfycbxaWBE3ePWUdQSyRRtHgJ8lxk7xX2YH-TbqQJQUvwMFEk7XTGo/exec"
  $scope.getDraw = (year, draw) ->
    req =
      url:    $scope.URL
      method: 'POST'
      data:
         godStr: year.toString()
         koloStr: draw.toString()
      headers:
        'Content-Type': 'application/json'
        'Accept':       'application/json'
    $http req
      .success (data, status) ->
        # console.log data.d
        res = $scope.parseDraw data.d
        console.log res
      .error (data, status) ->
        console.log "Error: #{ status }"
 
  # remove this after testing
  $scope.getDraw 2016, 83
  req =
    url:    $scope.appendURL
    method: 'POST'
    data:
      draw: 83
      date: '2016-12-12'
    headers:
      'Content-Type': 'application/json'
      'Accept':       'application/json'

  $http  req
        .success (data, status) -> console.log "Success: #{ data }"
        .error (data, status) -> console.log "Error: #{ status }"
  console.log "Should append row..."
  
  # dd.mm.yyyy to yyyy-mm-dd
  $scope.toYMD = (s) ->
    re = /^(\d\d).(\d\d).(\d\d\d\d)$/
    match = re.exec s
    throw "toYMD(): invalid format #{ s }" unless match
    match[1..3].reverse().join '-'

  # strip '.' and leave \d only
  $scope.strip = (s) ->
    re = /([\d.]*)/
    match = re.exec s
    match[1].replace /\./g, ''

  $scope.parseDraw = (text) ->
    res = { }

    # extract draw date
    re = /<th>Датум на извлекување:<\/th>\s*<td[^>]*>([^>]*)\s*<\/td>/m
    match = re.exec text
    res.date = $scope.toYMD match[1]
  
    # extract winning columns
    re = /<p>Редослед на извлекување:\s*([\d,]+)\.?\s*<\/p>/m
    match = re.exec text
    throw "can't extract lotto winning column!" unless match
    res.lwcol = match[1].split /\s*,\s*/
                        .map (e) -> parseInt e
    # .
    re = /<div\s+id="joker">\s*(\d+)\s*<\/div>/m
    match = re.exec text
    throw "can't extract joker winning column!" unless match
    res.jwcol = match[1]

    # extract lotto sales
    re = /<th>Уплата:<\/th>\s*<td[^>]*>([^>]*)\s*<\/td>(.*)/m
    match = re.exec text
    throw "can't extract lotto sales!" unless match
    res.lsales = parseInt $scope.strip match[1]
    
    t = match[2] # rest of.. (post-match)

    # extract joker sales
    re = /<th>Уплата:<\/th>\s*<td[^>]*>([^>]*)\s*<\/td>/m
    match = re.exec t
    throw "can't extract joker sales!" unless match
    res.jsales = parseInt $scope.strip match[1]

    # extract lotto winners
    re = /<table\s+class="nl734"\s*>(.*?)<\/table>/gm
    tab = text.match re
    raise "can't extract lotto winners!" unless tab
    tab = tab[1] # 2nd table is with winners
    
    re = /<tbody>\s*(.*?)\s*<\/tbody>/m
    tab = re.exec tab

    
    re = ///
      <tr>\s*<th>\s*(.*?)\s*<\/th>\s*
      <td>\s*(.*?)\s*<\/td>\s*<td>\s*
      (.*?)\s*<\/td>\s*<\/tr>(.*)
    ///m
    match = re.exec tab[1]
    while match
      switch match[1]
        when "7 погодоци"   then res.x7  = parseInt match[2]
        when "6+1 погодоци" then res.x6p = parseInt match[2]
        when "6 погодоци"   then res.x6  = parseInt match[2]
        when "5 погодоци"   then res.x5  = parseInt match[2]
        when "4 погодоци"   then res.x4  = parseInt match[2]
      tab = match[4]
      match = re.exec tab

    # extract joker winners
    re = /<table\s+class="j734"\s*>(.*?)<\/table>/gm
    tab = text.match re
    raise "can't extract joker winners!" unless tab
    tab = tab[1] # 2nd table is with winners
    
    re = /<tbody>\s*(.*?)\s*<\/tbody>/m
    tab = re.exec tab

    
    re = ///
      <tr>\s*<th>\s*(.*?)\s*<\/th>\s*
      <td>\s*.*?\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>\s*
      <td>\s*(.*?)\s*<\/td>\s*<\/tr>(.*)
    ///m
    match = re.exec tab[1]
    while match
      console.log match[1..3]
      switch match[1]
        when "6 погодоци" then res.jx6 = parseInt match[2]
        when "5 погодоци" then res.jx5 = parseInt match[2]
        when "4 погодоци" then res.jx4 = parseInt match[2]
        when "3 погодоци" then res.jx3 = parseInt match[2]
        when "2 погодоци" then res.jx2 = parseInt match[2]
        when "1 погодок"  then res.jx1 = parseInt match[2]
      tab = match[4]
      match = re.exec tab

    res # return result
