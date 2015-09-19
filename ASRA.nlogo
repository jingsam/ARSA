extensions [gis]

globals [time]

patches-own [village-type village-id suit forbid]

breed [urbanization-villagers urbanization-villager]
breed [priority-villagers priority-villager]
breed [restricted-villagers restricted-villager]
breed [relocation-villagers relocation-villager]

turtles-own [ox oy]

to setup
  clear-all
  reset-timer
  
  import-village-data
  import-id-data
  import-suit-data
  import-forbid-data
  
  ;Display background
  ask patches [
    set pcolor white    
    if village-type >= 0 [set pcolor yellow]
  ]  
  
  ;Intialize urbanization-villagers
  ask patches with [village-type = 1] [
    sprout-urbanization-villagers 1 [
      set ox pxcor
      set oy pycor
      set color green
      set shape "square"
      set size 1
    ]
  ]
  
  ;Intialize priority-villagers
  ask patches with [village-type = 2] [
    sprout-priority-villagers 1 [
      set ox pxcor
      set oy pycor
      set color red
      set shape "square"
      set size 1
    ]
  ]
  
  ;Intialize restricted-villagers
  ask patches with [village-type = 3] [
    sprout-restricted-villagers 1 [
      set ox pxcor
      set oy pycor
      set color blue
      set shape "square"
      set size 1
    ]
    
    set pcolor yellow
  ]
  
  ;Intialize relocation-villagers
  ask patches with [village-type = 4] [
    ifelse (random-float 1) <= save-ratio
    [sprout-relocation-villagers 1 [
      set ox pxcor
      set oy pycor
      set color black
      set shape "square"
      set size 1
      ]
    ]
    [set village-type 0]
  ]  
  
  
  reset-ticks
end

to go
  if ticks > max-iteration [stop]
  
  ask urbanization-villagers [
    set village-type 0
    set village-id -9999
    die
  ]  
 
  ask priority-villagers with [not all? neighbors4 [village-type = 2]] [
    let target [one-of patches in-radius max-distance with [forbid = 0 and not any? turtles-on self and not any? neighbors4 with [village-type = 3]]] of patch ox oy
    let id village-id
    
    if target != nobody and any? [neighbors4 with [id = village-id]] of target and [utility] of target > utility [
      set village-type 0
      set village-id -9999
      move-to target
      set village-type 2
      set village-id id
    ]
  ]
  
  ;restricted-villagers stay put
  
  ask relocation-villagers [
    let target [one-of patches in-radius max-distance with [forbid = 0 and not any? turtles-on self and not any? neighbors4 with [village-type = 3]]] of patch ox oy
    
    if target != nobody and any? [neighbors4 with [village-type = 2]] of target [
      set village-type 0
      set village-id -9999
      move-to target
      set village-type 2
      set village-id [village-id] of [one-of neighbors4 with [village-type = 2]] of target
      hatch-priority-villagers 1 [set shape "square"]
      die
    ]
    
    if target != nobody and [utility] of target > utility [
      set village-type 0
      set village-id -9999
      move-to target
      set village-type 4
    ]
  ]
  
  set time timer
  tick

end


;Import data---------------------------------------------
to-report import-data [file]
  ;gis:load-coordinate-system (word projection ".prj")
  let data gis:load-dataset file
  gis:set-world-envelope (gis:envelope-of data)
  
  report data
end

to import-village-data
  let data import-data village-type-data
  gis:apply-raster data village-type
end

to import-id-data
  let data import-data village-id-data
  gis:apply-raster data village-id
end

to import-suit-data
  let data import-data suit-data
  gis:apply-raster data suit
end

to import-forbid-data
  let data import-data forbid-data
  gis:apply-raster data forbid
end

to display-village-data
  import-village-data
  
  ask patches[
    set pcolor white
    
    if village-type = 0 [set pcolor yellow]
    if village-type = 1 [set pcolor green]
    if village-type = 2 [set pcolor red]
    if village-type = 3 [set pcolor blue]
    if village-type = 4 [set pcolor black]
  ]
end


;Display data---------------------------------------------
to display-id-data
  import-id-data
  
  ask patches[
    set pcolor white    
    
    if village-id >= 0 [set pcolor village-id]
  ]
end

to display-suit-data
  import-suit-data
  
  ask patches[
    set pcolor white
    
    if suit >= 0 [set pcolor scale-color black suit 0 1]
  ]  
end

to display-forbid-data
  import-forbid-data
  
  ask patches[
    set pcolor white
    
    if forbid = 0 [set pcolor yellow]
    if forbid = 1 [set pcolor blue]
  ]
end


;Evaluation---------------------------------------------
to-report compact
  report count neighbors with [village-type > 0] / count neighbors 
end

to-report utility
  report suit * suit-weight + compact * compact-weight
end
@#$#@#$#@
GRAPHICS-WINDOW
680
10
1309
1117
-1
-1
0.7
1
10
1
1
1
0
0
0
1
0
884
0
1537
0
0
1
迭代次数
30.0

BUTTON
17
35
98
68
初始化
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
201
36
281
69
运行
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
111
35
191
68
运行
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
310
75
670
390
效用评价
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"适宜性" 1.0 0 -2674135 true "" "plot mean [suit] of turtles"
"紧凑度" 1.0 0 -10899396 true "" "plot mean [compact] of turtles"
"综合效用值" 1.0 0 -13345367 true "" "plot mean [utility] of turtles"

TEXTBOX
18
10
168
28
控制面板
16
0.0
1

TEXTBOX
15
85
165
103
参数
16
0.0
1

SLIDER
14
128
279
161
suit-weight
suit-weight
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
13
190
278
223
compact-weight
compact-weight
0
1
0.5
0.1
1
NIL
HORIZONTAL

TEXTBOX
15
109
165
127
适宜性权重
14
0.0
1

TEXTBOX
14
172
164
190
紧凑度权重
14
0.0
1

TEXTBOX
14
438
164
456
数据
18
0.0
1

BUTTON
10
755
210
788
导入适宜性数据
set suit-data user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
10
790
280
850
suit-data
data\\HP\\suit.asc
1
0
String

BUTTON
220
755
280
788
查看
display-suit-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
860
207
893
导入禁止开发区
set forbid-data user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
220
860
280
893
查看
display-forbid-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
10
895
280
955
forbid-data
data\\HP\\forbid.asc
1
0
String

INPUTBOX
10
580
280
640
village-type-data
data\\HP\\village-type.asc
1
0
String

INPUTBOX
10
685
280
745
village-id-data
data\\HP\\village-id.asc
1
0
String

BUTTON
11
545
211
578
导入农村居民点分类图
set village-type-data user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
220
545
279
578
查看
display-village-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
650
208
683
导入居民点编号数据
set village-id-data user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
220
650
280
683
查看
display-id-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
14
235
164
253
出地率
14
0.0
1

SLIDER
13
256
279
289
save-ratio
save-ratio
0
1
0.8
0.1
1
NIL
HORIZONTAL

TEXTBOX
15
985
165
1003
结果输出
16
0.0
1

CHOOSER
11
485
281
530
projection
projection
"WGS_84_Geographic" "Xian 1980 3 Degree GK Zone 38"
0

TEXTBOX
13
463
163
481
坐标系
14
0.0
1

TEXTBOX
12
300
162
318
最大搬迁距离
14
0.0
1

SLIDER
13
319
279
352
max-distance
max-distance
0
50
10
1
1
NIL
HORIZONTAL

MONITOR
310
890
670
939
城镇转化型村庄面积
count urbanization-villagers
17
1
12

MONITOR
310
945
670
994
重点发展型村庄面积
count priority-villagers
17
1
12

BUTTON
10
1015
280
1048
输出布局方案
gis:store-dataset gis:patch-dataset village-type user-new-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
310
395
670
444
适宜性
mean [suit] of turtles
6
1
12

MONITOR
310
505
670
554
综合效用值
mean [utility] of turtles
6
1
12

MONITOR
310
450
670
499
紧凑度
mean [compact] of turtles
6
1
12

MONITOR
310
1000
670
1049
限制发展型村庄面积
count restricted-villagers
17
1
12

MONITOR
310
1055
670
1104
迁弃型村庄面积
count relocation-villagers
17
1
12

BUTTON
10
1060
280
1093
输出搬迁方案
NIL
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
310
10
670
59
运行时间（S）
time
17
1
12

PLOT
310
575
670
885
数量结构
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"城镇转化型村庄" 1.0 1 -10899396 true "" "histogram [village-type] of urbanization-villagers"
"重点发展型村庄" 1.0 1 -2674135 true "" "histogram [village-type] of priority-villagers"
"限制发展型村庄" 1.0 1 -13345367 true "" "histogram [village-type] of restricted-villagers"
"迁弃型村庄" 1.0 1 -16777216 true "" "histogram [village-type] of relocation-villagers"

SLIDER
15
385
280
418
max-iteration
max-iteration
0
1000
400
1
1
NIL
HORIZONTAL

TEXTBOX
15
365
165
383
最大迭代次数
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="max-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compact-weight">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="village-data">
      <value value="&quot;data\\HP\\village.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suit-weight">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="projection">
      <value value="&quot;WGS_84_Geographic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forbid-data">
      <value value="&quot;data\\HP\\forbid.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="save-ratio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="id-data">
      <value value="&quot;data\\HP\\id.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suit-data">
      <value value="&quot;data\\HP\\suit.asc&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
