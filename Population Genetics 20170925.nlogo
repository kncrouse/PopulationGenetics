;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Variable & Breed Declarations ::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

globals [
  allele-types ; list of alleles used for this simulation
  generation-number ; current generation
  population-radius ; size that the population occupies in the world
]

breed [ phenotypes phenotype ]
breed [ students student ]
breed [ alleles allele ]

students-own [
  hubnet-client? ; true = hubnet client user ; false = npc student
  user-id ; id that connects each student to the hubnet control center
  shape-choice ; chosen shape by student for phenotype
  phenotype-population ; collection of phenotypes of student
  gene-flow-student ; adjacent student for gene flow during reproduction
  report-phenotypes
]

phenotypes-own [
  parent-student ; student that contains this phenotype
  first-allele
  second-allele
]

alleles-own [
  parent-phenotype ; the phenotype to which this allele belongs
  allele-type ; type of allele based on gui settings
]

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Setup ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to startup
  hubnet-reset
  setup
end

to setup
  clear-all-plots
  setup-parameters
  ask patches [ set pcolor green ]
  ask students [ setup-student ]
  update-allele-frequency-plot
  reset-ticks
end

to setup-parameters
  update-allele-types-list
  set population-radius sqrt ( 3 * population-size )
  set generation-number 0
end

; create a list based on which alleles are turned on? in gui settings
to update-allele-types-list
  set allele-types []
  if allele-one-on? [ set allele-types lput "one" allele-types ]
  if allele-two-on? [ set allele-types lput "two" allele-types ]
  if allele-three-on? [ set allele-types lput "three" allele-types ]
  if allele-four-on? [ set allele-types lput "four" allele-types ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:            CREATE A STUDENT CLIENT AND SET PARAMETERS                      ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; create a new student and connect to hubnet
to create-new-hubnet-student
  create-students 1 [
    set user-id hubnet-message-source
    set hubnet-client? true
    setup-student
    send-info-to-clients
  ]
end

to create-new-student
  create-students 1 [
    set user-id one-of [ "Isler" "Ostner" "Pusey" "Goodall" "Smuts" "Isbell" "Sterck" "Silk" "Cords"  ]
    if any? other students with [ substring user-id 0 3 = substring [user-id] of myself 0 3 ]
       [ set user-id (word user-id " " count students with [ substring user-id 0 3 = substring [user-id] of myself 0 3 ])]
    set hubnet-client? false
    setup-student
  ]
end

to setup-student
  move-to one-of patches
  face one-of neighbors4
  set phenotype-population []
  ask phenotypes with [ parent-student = myself ] [ remove-phenotype ]
  set color pcolor
  set size 0.1
  set shape-choice "spade"
  set gene-flow-student nobody
  create-phenotype-population
  set label user-id
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:       CREATE A PHENOTYPE INDIVIDUALS OF STUDENT AND SET PARAMETERS         ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-phenotype-population
  let parent self
  hatch-phenotypes population-size
  [
    set first-allele initialize-allele
    set second-allele initialize-allele
    set parent-student parent
    setup-phenotype
    ask parent [ set phenotype-population lput myself phenotype-population ] ; LINE USED TWICE
  ]
end

to setup-phenotype
  set size 3
  set label ""
  set hidden? show-alleles
  move-to parent-student move-to one-of patches in-radius ( population-radius * 0.75 )
  set-shape-and-color
end

; set the shape and color of phenotype based on alleles
to set-shape-and-color
  let dominance get-allele-dominance [allele-type] of first-allele [allele-type] of second-allele
  set shape get-phenotype-shape
  if dominance = "recessive-dominant" [ set color [color] of second-allele ]
  if dominance = "dominant-recessive" [ set color [color] of first-allele ]
  if dominance = "identical" [ set color [color] of first-allele ]
  if dominance = "codominant" [
    set shape word get-phenotype-shape word " " [color] of second-allele
    set color [color] of first-allele ]
end

; gets the color of the phenotype based on alleles and dominance
to-report get-color [ color1 color2 ]
  let report-color white
  let dominance get-allele-dominance color1 color2
  if dominance = "recessive-dominant" [ set report-color get-allele-color color2  ]
  if dominance = "dominant-recessive" [ set report-color get-allele-color color1 ]
  if dominance = "identical" [ set report-color get-allele-color color1 ]
  if dominance = "codominant" [ set report-color (word get-allele-color color1 "-" get-allele-color color2) ]
  report report-color
end

; reports the dominance status of the two alleles of a phenotype based on gui settings
to-report get-allele-dominance [ allele1 allele2 ]
  if allele1 = "one" and allele2 = "one" [ report "identical" ]
  if allele1 = "one" and allele2 = "two" [ report allele-one-two-relationship ]
  if allele1 = "one" and allele2 = "three" [ report allele-one-three-relationship ]
  if allele1 = "one" and allele2 = "four" [ report allele-one-four-relationship ]

  if allele1 = "two" and allele2 = "one" [
    let d allele-one-two-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if allele1 = "two" and allele2 = "two" [ report "identical" ]
  if allele1 = "two" and allele2 = "three" [ report allele-two-three-relationship ]
  if allele1 = "two" and allele2 = "four" [ report allele-two-four-relationship ]

  if allele1 = "three" and allele2 = "one" [
    let d allele-one-three-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if allele1 = "three" and allele2 = "two" [
    let d allele-two-three-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if allele1 = "three" and allele2 = "three" [ report "identical" ]
  if allele1 = "three" and allele2 = "four" [ report allele-three-four-relationship ]

  if allele1 = "four" and allele2 = "one" [
    let d allele-one-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if allele1 = "four" and allele2 = "two" [
    let d allele-two-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if allele1 = "four" and allele2 = "three" [
    let d allele-three-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if allele1 = "four" and allele2 = "four" [ report "identical" ]
end

; report shape to set phenotype based on student settings
to-report get-phenotype-shape
  ifelse [shape-choice] of parent-student = nobody [ report "spade" ] [ report [shape-choice] of parent-student ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:              CREATE ALLELES OF PHENOTYPE AND SET PARAMETERS                ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; create random allele, add to phenotype, and report
to-report initialize-allele
  let parent self
  let allele-to-report nobody
  hatch-alleles 1 [
    set allele-type one-of allele-types
    set parent-phenotype parent
    setup-allele
    set allele-to-report self
  ]
  report allele-to-report
end

to setup-allele
  set size 1
  set label ""
  set shape "circle"
  set parent-phenotype nobody
  set color get-allele-color allele-type
  set hidden? not show-alleles
end

; get the color of given allele based on gui settings
to-report get-allele-color [ type-input ]
  if type-input = "one" [ report read-from-string allele-one-color ]
  if type-input = "two" [ report read-from-string allele-two-color ]
  if type-input = "three" [ report read-from-string allele-three-color ]
  if type-input = "four" [ report read-from-string allele-four-color ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Runtime Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to go
  listen-clients
  ask students with [ hubnet-client? = false ] [ student-wander ]
  ask students [ set gene-flow-student get-adjacent-population ]
  ask phenotypes [ phenotype-wander ]
  ask students with [ hubnet-client? = true ] [ send-info-to-clients ]
  update-visibility-settings
  update-phenotype-shape-and-color
  update-allele-types-list
  tick
end

; obsever command to update whether phenotypes or alleles are visible
to update-visibility-settings
  ask alleles [ set hidden? not show-alleles ]
  ask phenotypes [ set hidden? show-alleles ]
end

; observer command to update the "phenotype" of all phenotypes
to update-phenotype-shape-and-color
  ask phenotypes [ set-shape-and-color ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                          Student Procedures                                ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to student-wander
  face one-of neighbors
  fd 0.5
end

; student command to move in given direction
to execute-move [new-heading]
  set heading new-heading
  fd 1
  ask phenotypes with [ parent-student = myself ] [ set heading new-heading fd 1 ]
end

; student command to ask each phenotype to reproduce
to execute-reproduce
  let old-phenotype-population phenotype-population
  let total-phenotype-population []
  ifelse gene-flow-student = nobody [
    set total-phenotype-population phenotype-population
  ][
    set total-phenotype-population sentence phenotype-population [phenotype-population] of gene-flow-student
  ]
  foreach old-phenotype-population [ [?1] -> ask ?1 [ reproduce ( one-of total-phenotype-population ) ] ]
  foreach old-phenotype-population [ [?1] -> ask ?1 [ remove-phenotype ] ]
end

to-report get-adjacent-population
  let reporter nobody
  if allow-gene-flow? [
    if any? other students in-radius ( population-radius * 1.5 )  [
      set reporter one-of other students in-radius ( population-radius * 1.5 ) ]
  ]
  report reporter
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                     Phenotype & Allele Procedures                          ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; phenotype command to move position
to phenotype-wander
  let patchy one-of patches in-cone population-radius 30 with [ distance [parent-student] of myself <= population-radius ]
  ifelse patchy = nobody [ face parent-student ] [ face patchy ]
  fd 0.05
  update-allele-positions
end

; phenotype command to update both allele positions
to update-allele-positions
  ask first-allele [ move-to myself set heading [heading] of myself rt 45 fd 0.5 ]
  ask second-allele [ move-to myself set heading [heading] of myself lt 135 fd 0.5 ]
end

; phenotype command to create offspring from alleles of self and mate
to reproduce [ mate ]
  ; not quite working for fractional offspring
  hatch-phenotypes ifelse-value (read-from-string selection-on-phenotype = color) [ rate-of-selection * rate-of-selection ] [ 1 ] [ ; natural selection
    let me self
    ask parent-student [ set phenotype-population lput myself phenotype-population ]
    let possible-alleles ( sentence first-allele [first-allele] of mate sentence second-allele [second-allele] of mate )

    ask one-of possible-alleles [ hatch-alleles 1 [
      set parent-phenotype me
      ask me [set first-allele myself ]]]

    ask one-of possible-alleles [ hatch-alleles 1 [
      set parent-phenotype me
      ask me [set second-allele myself ]]]

    update-for-mutation
    setup-phenotype
  ]
end

; phenotype command to mutate alleles based on given gui rate
to update-for-mutation
  if random-float 1.0 < mutation-rate [
    ask first-allele [ remove-allele ]
    set first-allele initialize-allele ]
  if random-float 1.0 < mutation-rate [
    ask second-allele [ remove-allele ]
    set second-allele initialize-allele ]
end

; remove phenotype from the world
to remove-phenotype
  ask parent-student [ set phenotype-population remove myself phenotype-population ]
  ask first-allele [ remove-allele ]
  ask second-allele [ remove-allele ]
  die
end

; remove allele from the world
to remove-allele
  die
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                            HubNet Procedures                               ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; DETERMINES WHICH CLIENT SENT A COMMAND AND WHAT THE COMMAND WAS
to listen-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ create-new-hubnet-student ]
    [
      ifelse hubnet-exit-message?
      [ remove-student ]
      [
        ask students with [ user-id = hubnet-message-source ]
          [ execute-command hubnet-message-tag ]
      ]
    ]
  ]
end

; REMOVE ALL AGENTS WHEN YOU CLOSE CLIENT WINDOW
to remove-student
  ask students with [user-id = hubnet-message-source]
  [
    foreach phenotype-population [ [?1] -> ask ?1 [ remove-phenotype ] ]
    die
  ]
end

; NETLOGO EXECUTES COMMANDS OF CLIENTS
;; Up    - make the turtle move up by 1 patch
;; Down  - make the turtle move down by 1 patch
;; Right - make the turtle move right by 1 patch
;; Left  - make the turtle move left by 1 patch
;; choose-shape - update student shape-choice
to execute-command [command]

  if command = "Up"
  [ execute-move 0 stop ]
  if command = "Down"
  [ execute-move 180 stop ]
  if command = "Right"
  [ execute-move 90 stop ]
  if command = "Left"
  [ execute-move 270 stop ]
  if command = "choose-shape"
  [ set shape-choice hubnet-message ]

  ; count number of alleles of each type
  let one count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "one" ]
  let two count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "two" ]
  let three count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "three" ]
  let four count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "four" ]

end

; student command to send information to corresponding client gui
to send-info-to-clients

  hubnet-send user-id "YOU ARE POPULATION:" user-id
  hubnet-send user-id "LOCATED AT:" (word "(" pxcor "," pycor ")")
  hubnet-send user-id "GENERATION:" generation-number

  hubnet-send user-id "ADJACENT POPULATION:" (word gene-flow-student)

  hubnet-send user-id "allele one count" count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "one" ]
  hubnet-send user-id "allele two count" count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "two" ]
  hubnet-send user-id "allele three count" count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "three" ]
  hubnet-send user-id "allele four count" count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "four" ]

  hubnet-send user-id "allele one %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "one" ]) / (count alleles with [ member? parent-phenotype [phenotype-population] of myself] + .0001)) 3
  hubnet-send user-id "allele two %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "two" ]) / (count alleles with [ member? parent-phenotype [phenotype-population] of myself] + .0001)) 3
  hubnet-send user-id "allele three %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "three" ]) / (count alleles with [ member? parent-phenotype [phenotype-population] of myself] + .0001)) 3
  hubnet-send user-id "allele four %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "four" ]) / (count alleles with [ member? parent-phenotype [phenotype-population] of myself] + .0001)) 3

  hubnet-send user-id "genotype one-two" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "one" and [allele-type] of second-allele = "two" ) or ( [allele-type] of first-allele = "two" and [allele-type] of second-allele = "one" ))]
  hubnet-send user-id "genotype one-three" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "one" and [allele-type] of second-allele = "three" ) or ( [allele-type] of first-allele = "three" and [allele-type] of second-allele = "one" ))]
  hubnet-send user-id "genotype one-four" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "one" and [allele-type] of second-allele = "four" ) or ( [allele-type] of first-allele = "four" and [allele-type] of second-allele = "one" ))]
  hubnet-send user-id "genotype two-three" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "two" and [allele-type] of second-allele = "three" ) or ( [allele-type] of first-allele = "three" and [allele-type] of second-allele = "two" ))]
  hubnet-send user-id "genotype two-four" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "two" and [allele-type] of second-allele = "four" ) or ( [allele-type] of first-allele = "four" and [allele-type] of second-allele = "two" ))]
  hubnet-send user-id "genotype three-four" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "three" and [allele-type] of second-allele = "four" ) or ( [allele-type] of first-allele = "four" and [allele-type] of second-allele = "three" ))]
  hubnet-send user-id "genotype one-one" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "one" and [allele-type] of second-allele = "one" ) or ( [allele-type] of first-allele = "one" and [allele-type] of second-allele = "one" ))]
  hubnet-send user-id "genotype two-two" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "two" and [allele-type] of second-allele = "two" ) or ( [allele-type] of first-allele = "two" and [allele-type] of second-allele = "two" ))]
  hubnet-send user-id "genotype three-three" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "three" and [allele-type] of second-allele = "three" ) or ( [allele-type] of first-allele = "three" and [allele-type] of second-allele = "three" ))]
  hubnet-send user-id "genotype four-four" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "four" and [allele-type] of second-allele = "four" ) or ( [allele-type] of first-allele = "four" and [allele-type] of second-allele = "four" ))]

  hubnet-send user-id "phenotype one-two" ;one-of base-colors ;get-color "one" "two"
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Plots ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to update-allele-frequency-plot
  foreach allele-types [ [?1] ->
    set-current-plot "Allele Frequencies"
    set-current-plot-pen (word "allele " ?1)
    set-plot-pen-color get-allele-color ?1
    plot-pen-down
    plotxy generation-number (100 * (count alleles with [ allele-type = ?1 ] / (count alleles + 0.00001)))
    plot-pen-up
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
432
10
1125
704
-1
-1
16.71
1
10
1
1
1
0
1
1
1
0
40
0
40
1
1
1
ticks
30.0

BUTTON
1232
11
1310
44
NIL
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

BUTTON
1147
11
1224
44
reset
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

SWITCH
226
118
415
151
allow-gene-flow?
allow-gene-flow?
1
1
-1000

TEXTBOX
223
43
416
61
---------- Mutation ------------
11
0.0
1

TEXTBOX
223
100
416
118
--------- Gene Flow ------------
11
0.0
1

TEXTBOX
224
158
416
176
------- Natural Selection --------
11
0.0
1

CHOOSER
30
229
198
274
allele-two-color
allele-two-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black"
0

SLIDER
225
61
416
94
mutation-rate
mutation-rate
0
1.0
0.0
.01
1
NIL
HORIZONTAL

CHOOSER
226
176
415
221
selection-on-phenotype
selection-on-phenotype
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black"
3

SLIDER
226
226
415
259
rate-of-selection
rate-of-selection
1
10
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
57
46
182
64
---- allele one ----
12
0.0
1

TEXTBOX
56
209
181
227
---- allele two ----\n
12
0.0
1

CHOOSER
31
66
196
111
allele-one-color
allele-one-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black"
6

SWITCH
1436
61
1583
94
show-alleles
show-alleles
0
1
-1000

CHOOSER
226
314
419
359
allele-one-two-relationship
allele-one-two-relationship
"dominant-recessive" "recessive-dominant" "codominant"
0

CHOOSER
226
366
418
411
allele-one-three-relationship
allele-one-three-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

CHOOSER
226
419
418
464
allele-one-four-relationship
allele-one-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

CHOOSER
224
470
418
515
allele-two-three-relationship
allele-two-three-relationship
"dominant-recessive" "recessive-dominant" "codominant"
1

CHOOSER
225
523
418
568
allele-two-four-relationship
allele-two-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

CHOOSER
225
576
418
621
allele-three-four-relationship
allele-three-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

SWITCH
31
116
196
149
allele-one-on?
allele-one-on?
0
1
-1000

SWITCH
31
278
198
311
allele-two-on?
allele-two-on?
0
1
-1000

SWITCH
29
443
199
476
allele-three-on?
allele-three-on?
1
1
-1000

SWITCH
32
605
201
638
allele-four-on?
allele-four-on?
1
1
-1000

CHOOSER
28
394
199
439
allele-three-color
allele-three-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black"
3

CHOOSER
32
556
201
601
allele-four-color
allele-four-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black"
1

TEXTBOX
52
373
186
391
---- allele three ----
12
0.0
1

TEXTBOX
54
535
192
553
---- allele four ----
12
0.0
1

TEXTBOX
243
290
403
308
ALLELE RELATIONSHIPS
14
0.0
1

TEXTBOX
245
15
395
33
EVOLUTION SETTINGS
14
0.0
1

PLOT
1148
151
1570
627
Allele Frequencies
generation
allele %
0.0
20.0
0.0
100.0
true
true
"" ""
PENS
"allele one" 1.0 0 -1 true "" ";set-plot-pen-color read-from-string allele-one-color plot 100 * (count alleles with [ allele-type = \"one\" ] / (count alleles + 1))"
"allele two" 1.0 0 -1 true "" ";set-plot-pen-color read-from-string allele-two-color plot 100 * (count alleles with [ allele-type = \"two\" ] / (count alleles + 1))"
"allele three" 1.0 0 -1 true "" ";set-plot-pen-color read-from-string allele-three-color plot 100 * (count alleles with [ allele-type = \"three\" ] / (count alleles + 1))"
"allele four" 1.0 0 -1 true "" "; set-plot-pen-color read-from-string allele-four-color plot 100 * (count alleles with [ allele-type = \"four\" ] / (count alleles + 1))"

MONITOR
31
154
196
199
allele one count
count alleles with [ allele-type = \"one\" ]
17
1
11

MONITOR
31
316
198
361
allele two count
count alleles with [ allele-type = \"two\" ]
17
1
11

MONITOR
29
481
199
526
allele three count
count alleles with [ allele-type = \"three\" ]
17
1
11

MONITOR
32
643
199
688
allele four count
count alleles with [ allele-type = \"four\" ]
17
1
11

TEXTBOX
69
16
168
34
ALLELE TYPES
14
0.0
1

BUTTON
1317
11
1461
44
reproduce
set generation-number generation-number + 1\nask students [ execute-reproduce ]\nask students [ foreach n-of (length phenotype-population - population-size) phenotype-population [ [?1] -> ask ?1 [remove-phenotype] ]]\nupdate-allele-frequency-plot
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
1147
54
1292
99
Generation
generation-number
17
1
11

MONITOR
1301
54
1429
99
Total Population
count phenotypes
17
1
11

BUTTON
1327
108
1468
141
add population
create-new-student
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1148
108
1320
141
population-size
population-size
0
100
10.0
5
1
NIL
HORIZONTAL

@#$#@#$#@
Compatible with NetLogo 6.0

## WHAT IS IT?

This model simulates the mechanisms of evolution, or how allele frequencies change in a population over time. Here, you can choose to have up to four different types of alleles for some arbitrary locus. The phenotypes of these alleles can also be displayed and are based on their ALLELE RELATIONSHIPS (i.e. dominant or recessive).

During the simulation, "students" control populations of alleles/phenotypes via a HubNet Client and a "teacher" controls the environment via the HubNet Control Center. The "Allele Frequencies" plot shows how the allele frequencies are changing over time.

## HOW IT WORKS

### TEACHER: HubNet Control Center

STARTUP: The HubNet Control Center should start upon opening this model. Change any of the settings depending on what aspect of evolution you want to simulate. Press the GO button.

INSTRUCTIONS FOR STUDENTS: Instruct your students to open the NetLogo HubNet Client application, type your user name, select this activity and press ENTER. Make sure they choose the correct port number and server address for this simulation. Instruct your students to move their populations around to acquaint themselves with the interface. If you would like the students to input specific initial allele counts, instruct them to do so now. Instructors can also press the ADD POPULATION button to produce another "non-playable" population in the world.

SIMULATION: Press the REPRODUCE NOW button to cause each population to reproduce. Investigate how the allele frequencies have changed and instruct your students to record the specifics for their population. Continue to press the REPRODUCE NOW button and record how the EVOLUTION SETTINGS affect how the populations change over time. Modify the EVOLUTION SETTINGS as need to change the environmental factors altering allele frequencies.

### STUDENT: HubNet Client

STARTUP: Students should open the NetLogo HubNet Client application, type their user name, select this activity and press ENTER. Make sure to choose the correct port number and server address for this simulation.

After logging in, the client interface will appear for the students, and if GO is pressed in NetLogo they will be assigned a population of alleles/phenotypes. The YOU ARE GROUP: monitor will display the name entered upon startup and will also appear on the simulation to label the appropriate population. The current location will be shown in the LOCATED AT: monitor.  If a student doesn't like their assigned phenotype shape they can select other shapes from the CHOOSE-SHAPE dropdown menu.

SIMULATION: Students are able to control the movement of their population with the UP, DOWN, LEFT, and RIGHT buttons. They can also input values for the initial allele configuration, if they desire different starting values then the ones given. Monitors show the current allele frequency count and percentage, as well as the current generation and closest adjacent population.

## HOW TO USE IT

### GENERAL

SETUP: returns the model to the starting state.
GO: runs the simulation.
ADD POPULATION: when pressed, a new "non-playable" allele/phenotype population is added to the world. It wanders randomly and its phenotypes can reproduce and share alleles with adjacent populations.
REPRODUCE NOW: when pressed, all individual phenotypes reproduce with someone else in their gene pool.
SHOW-ALLELES: when on, the alleles of the population are shown, otherwise the individual phenotypes are shown, which are based on the relationships between allele pairs.

### ALLELE SETTINGS

ALLELE-X-ON: allows the given allele type to be part of the allele population.
ALLELE-X-COLOR: sets the color of the given allele type.
ALLELE-X-Y-RELATIONSHIP: sets the relationship (i.e. dominant, recessive) between two alleles, which dictates the phenotype that is displayed from each allele pair.

### EVOLUTION SETTINGS

MUTATION-RATE: the rate at which alleles mutate to a random allele upon reproduction.
ALLOW-GENE-FLOW?: when on, allows populations that are close enough to an ADJACENT POPULATION to share alleles upon reproduction.
SELECTION-ON-PHENOTYPE: selects the phenotype color that natural selection can act upon during the simulation.
RATE-OF-SELECTION: for a phenotype that matches the currently set SELECTION-ON-PHENOTYPE this sets the average number of offspring that phenotype will have when they reproduce.

### MONITORS & PLOTS

ALLELE-X-COUNT: the total allele count for the given allele type.
GENERATION: the current generation of the populations in the simulation.
TOTAL POPULATION: the number of phenotypes from all populations in the simulation.
ALLELE FREQUENCIES: shows the allele counts for each allele type over generations.

## THINGS TO NOTICE

MUTATION RATE: How does the MUTATION-RATE setting change the alleles? How does it change within population and between population variation?

GENE FLOW: How does the ALLOW-GENE-FLOW? setting change the alleles? How does it change within population and between population variation?

NATURAL SELECTION: How do the SELECTION-ON-PHENOTYPE and RATE-OF-SELECTION settings change the alleles? How do they change within population and between population variation?

GENETIC DRIFT: Notice that there are no settings for genetic drift, the fourth mechanism of evolution. Unlike the other mechanisms, genetic drift can never be turned off!

## THINGS TO TRY

Use the model with the entire class to serve as an introduction to population genetics. Be sure to modify the EVOLUTION SETTINGS to simulate how different mechanisms can affect the allele frequencies and variation both within and between populations.

## COPYRIGHT AND LICENSE

Copyright 2017 K N Crouse

This model was created at the University of Minnesota as part of a series of applets to illustrate principles in biological evolution.

The model may be freely used, modified and redistributed provided this copyright is included and the resulting models are not used for profit.

Contact K N Crouse at crou0048@umn.edu if you have questions about its use.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

club
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122

club 0
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -16777216 true false 88 103 124

club 105
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13345367 true false 88 103 124

club 115
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -8630108 true false 88 103 124

club 125
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -5825686 true false 88 103 124

club 135
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -2064490 true false 88 103 124

club 15
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -2674135 true false 88 103 124

club 25
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -955883 true false 88 103 124

club 35
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -6459832 true false 88 103 124

club 45
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -1184463 true false 88 103 124

club 55
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -10899396 true false 88 103 124

club 65
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13840069 true false 88 103 124

club 75
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -14835848 true false 88 103 124

club 85
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -11221820 true false 88 103 124

club 9.9
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -1 true false 88 103 124

club 95
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13791810 true false 88 103 124

heart
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135

heart 0
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -16777216 true false 86 71 127

heart 105
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13345367 true false 86 71 127

heart 115
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -8630108 true false 86 71 127

heart 125
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -5825686 true false 86 71 127

heart 135
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -2064490 true false 86 71 127

heart 15
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -2674135 true false 86 71 127

heart 25
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -955883 true false 86 71 127

heart 35
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -6459832 true false 86 71 127

heart 45
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -1184463 true false 86 71 127

heart 55
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -10899396 true false 86 71 127

heart 65
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13840069 true false 86 71 127

heart 75
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -14835848 true false 86 71 127

heart 85
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -11221820 true false 86 71 127

heart 9.9
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -1 true false 86 71 127

heart 95
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13791810 true false 86 71 127

spade
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210

spade 0
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -16777216 true false 83 98 134

spade 105
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13345367 true false 83 98 134

spade 115
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -8630108 true false 83 98 134

spade 125
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -5825686 true false 83 98 134

spade 135
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -2064490 true false 83 98 134

spade 15
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -2674135 true false 83 98 134

spade 25
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -955883 true false 83 98 134

spade 35
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -6459832 true false 83 98 134

spade 45
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -1184463 true false 83 98 134

spade 55
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -10899396 true false 83 98 134

spade 65
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13840069 true false 83 98 134

spade 75
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -14835848 true false 83 98 134

spade 85
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -11221820 true false 83 98 134

spade 9.9
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -1 true false 83 98 134

spade 95
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13791810 true false 83 98 134
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
507
12
1107
612
0
0
0
1
1
1
1
1
0
1
1
1
0
40
0
40

BUTTON
330
84
392
117
Up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
330
150
392
183
Down
NIL
NIL
1
T
OBSERVER
NIL
K

BUTTON
392
117
454
150
Right
NIL
NIL
1
T
OBSERVER
NIL
L

BUTTON
268
117
330
150
Left
NIL
NIL
1
T
OBSERVER
NIL
J

MONITOR
149
15
246
64
LOCATED AT:
NIL
3
1

MONITOR
9
15
144
64
YOU ARE POPULATION:
NIL
3
1

MONITOR
353
15
498
64
ADJACENT POPULATION:
NIL
3
1

MONITOR
252
15
349
64
GENERATION:
NIL
3
1

MONITOR
38
284
141
333
allele one %
NIL
3
1

MONITOR
38
230
141
279
allele one count
NIL
3
1

MONITOR
149
284
251
333
allele two %
NIL
3
1

MONITOR
148
230
250
279
allele two count
NIL
3
1

MONITOR
257
284
363
333
allele three %
NIL
3
1

MONITOR
256
229
362
278
allele three count
NIL
3
1

MONITOR
369
284
475
333
allele four %
NIL
3
1

MONITOR
368
229
474
278
allele four count
NIL
3
1

TEXTBOX
169
671
319
689
NIL
11
0.0
1

CHOOSER
67
112
214
157
choose-shape
choose-shape
\"spade\" \"heart\" \"club\"
0

TEXTBOX
59
206
145
224
allele one
12
0.0
1

TEXTBOX
168
206
229
224
allele two
12
0.0
1

TEXTBOX
275
206
347
224
allele three
12
0.0
1

TEXTBOX
388
206
452
224
allele four
12
0.0
1

MONITOR
256
373
369
422
genotype one-two
NIL
3
1

MONITOR
38
427
160
476
genotype one-three
NIL
3
1

MONITOR
256
427
374
476
genotype one-four
NIL
3
1

MONITOR
256
481
379
530
genotype two-three
NIL
3
1

MONITOR
39
538
168
587
genotype two-four
NIL
3
1

MONITOR
39
593
166
642
genotype three-four
NIL
3
1

MONITOR
373
373
496
422
phenotype one-two
NIL
3
1

MONITOR
38
373
154
422
genotype one-one
NIL
3
1

MONITOR
39
483
156
532
genotype two-two
NIL
3
1

MONITOR
255
536
386
585
genotype three-three
NIL
3
1

MONITOR
255
592
389
641
genotype four-four
NIL
3
1

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
0
@#$#@#$#@
