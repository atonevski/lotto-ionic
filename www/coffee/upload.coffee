#
# upload.coffee
# lotto-ionic
# v0.0.2
# Copyright 2016 Andreja Tonevski, https://github.com/atonevski/lotto-ionic
# For license information see LICENSE in the repository
#

angular.module 'app.upload', []

.controller 'Upload', ($scope, $rootScope, $ionicPopup, $state, $timeout, $ionicLoading, $http) ->
  # scope var: next draw
  $scope.nextd = $scope.nextDraw $rootScope.lastDraw
  console.log "Upload: next draw date: #{ $scope.dateToDMY $scope.nextd.date }"
 
  $scope.URL = "http://test.lotarija.mk/Results/" +
              "WebService.asmx/GetDetailedReport"
  $scope.appendURL = "https://script.google.com/macros/s/" +
              "AKfycbxn66xXetBH2YV1WI0FnvdqFPL6Jpkvx6xzmnCBGhGz-_BGFHw/exec"
  $scope.getDraw = (year, draw, fn) ->
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
        res = $scope.parseDraw data.d
        res.draw = draw
        console.log res
        fn res if fn
      .error (data, status) ->
        console.log "Error: #{ status }"
 
  $scope.serialize = (rec) ->
    "draw=#{ rec.draw }" +
    "&date=#{ rec.date }" +
    "&lsales=#{ rec.lsales }" +
    "&x7=#{ rec.x7 }&x6p=#{ rec.x6p }&x6=#{ rec.x6 }" +
    "&x5=#{ rec.x5 }&x4=#{ rec.x4 }" +
    "&jsales=#{ rec.jsales }" +
    "&jx6=#{ rec.jx6 }&jx5=#{ rec.jx5 }&jx4=#{ rec.jx4 }" +
    "&jx3=#{ rec.jx3 }&jx2=#{ rec.jx2 }&jx1=#{ rec.jx1 }" +
    "&l1=#{ rec.lwcol[0] }&l2=#{ rec.lwcol[1] }" +
    "&l3=#{ rec.lwcol[2] }&l4=#{ rec.lwcol[3] }" +
    "&l5=#{ rec.lwcol[4] }&l6=#{ rec.lwcol[5] }" +
    "&l7=#{ rec.lwcol[6] }&lp=#{ rec.lwcol[7] }" +
    "&jwcol=#{ rec.jwcol }"

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

  # the popup
  popup =
    title:      'Освежи'
    cssClass:   'upload'
    template:   """Додади податоци за <strong>#{ $scope.nextd.draw }</strong>
        коло од #{ $scope.dateToDMY $scope.nextd.date }
    """
    cancelText: 'Откажи'
    cancelType: 'button-assertive'
    okText:     'Додади'
    okType:     'button-positive'

  $ionicPopup.confirm popup
    .then (res) ->
      console.log "Confirmed, res = #{ res }"
      if res
        $ionicLoading.show()
        draw = $scope.nextd.draw
        year = $scope.nextd.date.getFullYear()
        $scope.getDraw year, draw, (rec) ->
          req =
            url:    $scope.appendURL
            method: 'POST'
            data:    $scope.serialize rec
            headers:
              'Content-Type': 'application/x-www-form-urlencoded'
              'Accept':       'application/json'
          $http  req
              .success (data, status) ->
                console.log "Success: #{ data }"
                $ionicLoading.hide()
                $rootScope.lastDraw = $scope.nextd
                nd = $scope.nextDraw $scope.nextd
                yesterday = $scope.yesterday()

                $rootScope.uploadNeeded = nd.date <= yesterday
                console.log "Comparing: ", nd.date, " with: ", yesterday
                $rootScope.$apply
                $state.go 'home'
              .error (err) ->
                console.log "Error: #{ err }"
                $ionicLoading.show({
                  template: "Не може да се вчитаат податоци"
                  duration: 3000
                })
                $state.go 'home'
      else
        $state.go 'home'
