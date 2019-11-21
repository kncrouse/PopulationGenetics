;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Variable & Breed Declarations ::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

globals [
  allele-types ; list of alleles used for this simulation
  generation-number ; current generation
  initial-individuals-per-group
  group-radius
]

breed [ phenotypes phenotype ]
breed [ students student ]
breed [ alleles allele ]

students-own [
  user-id ; id that connects each student to the hubnet control center
  shape-choice ; chosen shape by student for phenotype
  phenotype-group ; collection of phenotypes of student
  gene-flow-student ; adjacent student for gene flow during reproduction
]

phenotypes-own [
  parent-student
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

to setup
  hubnet-reset
  clear-all
  ask patches [ set pcolor green ]
  update-allele-types-list
  set initial-individuals-per-group 10
  set group-radius 5
  reset-ticks
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
to create-new-student
  create-students 1
  [
    setup-student-client
    send-info-to-clients
  ]
end

to setup-student-client
  set user-id hubnet-message-source
  move-to one-of patches
  face one-of neighbors4
  set phenotype-group []
  set color pcolor
  set size 0.1
  set label user-id
  set shape-choice "spade"
  set generation-number 0
  set gene-flow-student nobody
  create-phenotype-group
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:       CREATE A PHENOTYPE INDIVIDUALS OF STUDENT AND SET PARAMETERS         ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-phenotype-group
  let parent self
  hatch-phenotypes initial-individuals-per-group
  [
    set first-allele initialize-allele
    set second-allele initialize-allele
    set parent-student parent
    setup-phenotype
    ask parent [ set phenotype-group lput myself phenotype-group ] ; LINE USED TWICE
  ]
end

to setup-phenotype
  set size 2
  set label ""
  move-to parent-student move-to one-of patches in-radius ( group-radius * 0.75 )
  set-shape-and-color
end

; set the shape and color of phenotype based on alleles
to set-shape-and-color
  let dominance get-allele-dominance
  set shape get-phenotype-shape
  if dominance = "recessive-dominant" [ set color [color] of second-allele ]
  if dominance = "dominant-recessive" [ set color [color] of first-allele ]
  if dominance = "identical" [ set color [color] of first-allele ]
  if dominance = "codominant" [
    set shape word get-phenotype-shape word " " [color] of second-allele
    set color [color] of first-allele ]
end

; reports the dominance status of the two alleles of a phenotype based on gui settings
to-report get-allele-dominance
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "one" [ report "identical" ]
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "two" [ report allele-one-two-relationship ]
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "three" [ report allele-one-three-relationship ]
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "four" [ report allele-one-four-relationship ]

  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "one" [
    let d allele-one-two-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "two" [ report "identical" ]
  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "three" [ report allele-two-three-relationship ]
  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "four" [ report allele-two-four-relationship ]

  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "one" [
    let d allele-one-three-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "two" [
    let d allele-two-three-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "three" [ report "identical" ]
  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "four" [ report allele-three-four-relationship ]

  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "one" [
    let d allele-one-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "two" [
    let d allele-two-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "three" [
    let d allele-three-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "four" [ report "identical" ]
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
  set color get-allele-color allele-type
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
  ask phenotypes [ wander ]
  ask students [ send-info-to-clients ]
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

; student command to ask each phenotype to reproduce
to execute-reproduce
  let old-phenotype-group phenotype-group
  let total-phenotype-group []
  ifelse gene-flow-student = nobody [
    set total-phenotype-group phenotype-group
  ][
    set total-phenotype-group sentence phenotype-group [phenotype-group] of gene-flow-student
  ]
  foreach old-phenotype-group [ ask ? [ reproduce ( one-of total-phenotype-group ) ]]
  foreach old-phenotype-group [ ask ? [ remove-phenotype ]]
end

; student command to update allele frequencies based on input number count
to update-alleles [ one two three four ]

  foreach phenotype-group [ ask ? [remove-phenotype ]]
  let parent self
  let allele-list []

  if allele-one-on? [ repeat one [ hatch-alleles 1 [
      set allele-type "one"
      setup-allele
      set allele-list lput self allele-list ]]]

  if allele-two-on? [ repeat two [ hatch-alleles 1 [
      set allele-type "two"
      setup-allele
      set allele-list lput self allele-list ]]]

  if allele-three-on? [ repeat three [ hatch-alleles 1 [
      set allele-type "three"
      setup-allele
      set allele-list lput self allele-list ]]]

  if allele-four-on? [ repeat four [ hatch-alleles 1 [
      set allele-type "four"
      setup-allele
      set allele-list lput self allele-list ]]]

  while [length allele-list > 1 ] [
    hatch-phenotypes 1
    [
      let pPhenotype self
      let fall one-of allele-list
      set first-allele fall
      ask first-allele [ set parent-phenotype pPhenotype ]
      set allele-list remove fall allele-list

      let sall one-of allele-list
      set second-allele sall
      ask second-allele [ set parent-phenotype pPhenotype ]
      set allele-list remove sall allele-list

      set parent-student parent
      ask parent [ set phenotype-group lput myself phenotype-group ]
      setup-phenotype
    ]
  ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                     Phenotype & Allele Procedures                          ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; phenotype command to move position
to wander
  let patchy one-of patches in-cone group-radius 60 with [ distance [parent-student] of myself <= group-radius ]
  ifelse patchy = nobody [ face parent-student ] [ face patchy ]
  fd 0.2
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
  hatch-phenotypes ifelse-value (read-from-string selection-on-phenotype = color) [ offspring-per-parent * rate-of-selection ] [offspring-per-parent] [ ; natural selection
    let me self
    ask parent-student [ set phenotype-group lput myself phenotype-group ]

    ask one-of ( sentence first-allele [first-allele] of mate ) [ hatch-alleles 1 [
      set parent-phenotype me
      ask me [set first-allele myself ]]]

    ask one-of ( sentence second-allele [second-allele] of mate ) [ hatch-alleles 1 [
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
  ask parent-student [ set phenotype-group remove myself phenotype-group ]
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
    [ create-new-student ]
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
    foreach phenotype-group [ ask ? [ remove-phenotype ]]
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
  let one count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "one" ]
  let two count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "two" ]
  let three count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "three" ]
  let four count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "four" ]

  ; change allele counts of student phenotype-group based on hubnet update
  if command = "initial-count-one"
  [ update-alleles hubnet-message two three four ]
  if command = "initial-count-two"
  [ update-alleles one hubnet-message three four ]
  if command = "initial-count-three"
  [ update-alleles one two hubnet-message four ]
  if command = "initial-count-four"
  [ update-alleles one two three hubnet-message ]

end

; student command to move in given direction
to execute-move [new-heading]
  set heading new-heading
  fd 1
end

; student command to send information to corresponding client gui
to send-info-to-clients

  hubnet-send user-id "YOU ARE GROUP:" user-id
  hubnet-send user-id "LOCATED AT:" (word "(" pxcor "," pycor ")")
  hubnet-send user-id "GENERATION:" generation-number

  if allow-gene-flow? [
    ifelse any? other students in-radius ( group-radius * 1.5 )  [
      set gene-flow-student one-of other students in-radius ( group-radius * 1.5 )
      hubnet-send user-id "ADJACENT GROUP:" [user-id] of gene-flow-student
    ][
      set gene-flow-student nobody
      hubnet-send user-id "ADJACENT GROUP:" ""
    ]
  ]

  if generation-number = 0 [
    hubnet-send user-id "initial-count-one" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "one" ]
    hubnet-send user-id "initial-count-two" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "two" ]
    hubnet-send user-id "initial-count-three" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "three" ]
    hubnet-send user-id "initial-count-four" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "four" ]
  ]

  hubnet-send user-id "allele one count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "one" ]
  hubnet-send user-id "allele two count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "two" ]
  hubnet-send user-id "allele three count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "three" ]
  hubnet-send user-id "allele four count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "four" ]

  hubnet-send user-id "allele one %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "one" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3
  hubnet-send user-id "allele two %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "two" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3
  hubnet-send user-id "allele three %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "three" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3
  hubnet-send user-id "allele four %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "four" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3
end
@#$#@#$#@
GRAPHICS-WINDOW
497
58
968
550
-1
-1
11.244
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
584
18
662
51
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
499
18
576
51
NIL
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
297
183
478
216
allow-gene-flow?
allow-gene-flow?
0
1
-1000

TEXTBOX
294
102
487
120
---------- Mutation ------------
11
0.0
1

TEXTBOX
294
165
487
183
--------- Gene Flow ------------
11
0.0
1

TEXTBOX
295
224
487
242
------- Natural Selection --------
11
0.0
1

TEXTBOX
294
43
489
61
--------- Reproduction ---------
11
0.0
1

CHOOSER
151
61
280
106
allele-two-color
allele-two-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
8

SLIDER
296
120
480
153
mutation-rate
mutation-rate
0
1.0
0.05
.01
1
NIL
HORIZONTAL

CHOOSER
297
242
477
287
selection-on-phenotype
selection-on-phenotype
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
0

SLIDER
297
292
477
325
rate-of-selection
rate-of-selection
0
10
0
.1
1
NIL
HORIZONTAL

TEXTBOX
15
40
140
58
---- allele one ----
12
0.0
1

TEXTBOX
157
41
282
59
---- allele two ----\n
12
0.0
1

CHOOSER
8
59
139
104
allele-one-color
allele-one-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
0

SWITCH
820
17
967
50
show-alleles
show-alleles
0
1
-1000

SLIDER
296
63
480
96
offspring-per-parent
offspring-per-parent
0
10
1
1
1
NIL
HORIZONTAL

CHOOSER
69
391
237
436
allele-one-two-relationship
allele-one-two-relationship
"dominant-recessive" "recessive-dominant" "codominant"
0

CHOOSER
69
443
237
488
allele-one-three-relationship
allele-one-three-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

CHOOSER
69
496
237
541
allele-one-four-relationship
allele-one-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
0

CHOOSER
248
391
416
436
allele-two-three-relationship
allele-two-three-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

CHOOSER
247
444
415
489
allele-two-four-relationship
allele-two-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

CHOOSER
247
497
415
542
allele-three-four-relationship
allele-three-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

SWITCH
8
109
139
142
allele-one-on?
allele-one-on?
0
1
-1000

SWITCH
152
110
280
143
allele-two-on?
allele-two-on?
0
1
-1000

SWITCH
8
269
141
302
allele-three-on?
allele-three-on?
0
1
-1000

SWITCH
152
269
280
302
allele-four-on?
allele-four-on?
0
1
-1000

CHOOSER
7
220
141
265
allele-three-color
allele-three-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
3

CHOOSER
152
220
280
265
allele-four-color
allele-four-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
11

TEXTBOX
11
200
145
218
---- allele three ----
12
0.0
1

TEXTBOX
157
200
295
218
---- allele four ----
12
0.0
1

TEXTBOX
159
365
319
383
ALLELE RELATIONSHIPS
14
0.0
1

TEXTBOX
311
16
461
34
EVOLUTION SETTINGS
14
0.0
1

PLOT
984
68
1268
544
Allele Frequencies
time
allele %
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"allele one" 1.0 0 -16777216 true "" "set-plot-pen-color read-from-string allele-one-color plot 100 * (count alleles with [ allele-type = \"one\" ] / (count alleles + 1))"
"allele two" 1.0 0 -14737633 true "" "set-plot-pen-color read-from-string allele-two-color plot 100 * (count alleles with [ allele-type = \"two\" ] / (count alleles + 1))"
"allele three" 1.0 0 -12895429 true "" "set-plot-pen-color read-from-string allele-three-color plot 100 * (count alleles with [ allele-type = \"three\" ] / (count alleles + 1))"
"allele four" 1.0 0 -11053225 true "" "set-plot-pen-color read-from-string allele-four-color plot 100 * (count alleles with [ allele-type = \"four\" ] / (count alleles + 1))"

MONITOR
8
147
138
192
allele one count
count alleles with [ allele-type = \"one\" ]
17
1
11

MONITOR
152
148
280
193
allele two count
count alleles with [ allele-type = \"two\" ]
17
1
11

MONITOR
8
307
141
352
allele three count
count alleles with [ allele-type = \"three\" ]
17
1
11

MONITOR
152
307
280
352
allele four count
count alleles with [ allele-type = \"four\" ]
17
1
11

TEXTBOX
100
16
199
34
ALLELE TYPES
14
0.0
1

BUTTON
669
18
813
51
reproduce now
set generation-number generation-number + 1\nask students [ execute-reproduce ]
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
984
14
1129
59
generation:
generation-number
17
1
11

MONITOR
1138
14
1266
59
population size:
count phenotypes
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model simulates the spread of a disease through a population.  This population can consist of either students, which are turtles controlled by individual students via the HubNet Client, or turtles that are generated and controlled by NetLogo, called androids, or both androids and students.

Turtles move around, possibly catching an infection.  Healthy turtles on the same patch as sick turtles have a INFECTION-CHANCE chance of becoming ill.  A plot shows the number of sick turtles at each time tick, and if SHOW-ILL? is on, sick turtles have a red circle attached to their shape.

Initially, all turtles are healthy.  A number of turtles equal to INITIAL-NUMBER-SICK become ill when the INFECT button is depressed.

## HOW TO USE IT

Quickstart Instructions:

Teacher: Follow these directions to run the HubNet activity.
Optional: Zoom In (see Tools in the Menu Bar)
Optional: Change any of the settings. If you want to add androids press the CREATE ANDROIDS button.  Press the GO button.
Everyone: Open up a HubNet client on your machine and type your user name, select this activity and press ENTER.
Teacher: Have the students move their turtles around to acquaint themselves with the interface. Press the INFECT button to start the simulation.
Everyone: Watch the plot of the number infected.
Teacher: To run the activity again with the same group, stop the model by pressing the NetLogo GO button, if it is on. Change any of the settings that you would like.  Press the CURE-ALL button to keep the androids, or SETUP to clear them
Teacher: Restart the simulation by pressing the NetLogo GO button again. Infect some turtles and continue.
Teacher: To start the simulation over with a new group, stop the model by pressing the GO button, if it is on, have all the students log out or press the RESET button in the Control Center, and start these instructions from the beginning

Buttons:

SETUP - returns the model to the starting state, all student turtles are cured and androids are killed.  The plot is advanced to start a new run but it is not cleared.
CURE-ALL - cures all turtles, androids are kept.  The plot is advanced to start a new run but it is not cleared.
GO - runs the simulation
CREATE ANDROIDS - adds randomly moving turtles to the simulation
INFECT - infects INITIAL-NUMBER-SICK turtles in the simulation
NEXT >>> - shows the next quick start instruction
<<< PREVIOUS - shows the previous quick start instruction
RESET INSTRUCTIONS - shows the first quick start instruction

Sliders:

NUMBER - determines how many androids are created by the CREATE ANDROIDS button
ANDROID-DELAY - the delay time, in seconds, for android movement - the higher the number, the slower the androids move
INITIAL-NUMBER-SICK - the number of turtles that become infected spontaneously when the INFECT button is pressed
INFECTION-CHANCE - sets the percentage chance that every tenth of a second a healthy turtle will become sick if it is on the same patch as an infected turtle

Switches:

WANDER? - when on, the androids wander randomly.  When off, they sit still
SHOW-SICK? - when on, sick turtles add to their original shape a red circle.  When off, they can move through the populace unnoticed
SHOW-SICK-ON-CLIENTS? - when on, the clients will be told if their turtle is sick or not.

Monitors:

TURTLES - the number of turtles in the simulation
NUMBER SICK - the number of turtles that are infected

Plots:

NUMBER SICK - shows the number of sick turtles versus time

Client Information

After logging in, the client interface will appear for the students, and if GO is pressed in NetLogo they will be assigned a turtle which will be described in the YOU ARE A: monitor.  And their current location will be shown in the LOCATED AT: monitor.  If the student doesn't like their assigned shape and/or color they can hit the CHANGE APPEARANCE button at any time to change to another random appearance.

The SICK? monitor will show one of three values: "true" "false" or "N/A".  "N/A" will be shown if the NetLogo SHOW-ILL-ON-CLIENTS? switch is off, otherwise "true" will be shown if your turtle is infected, or "false" will be shown if your turtle is not infected.

The student controls the movement of their turtle with the UP, DOWN, LEFT, and RIGHT buttons and the STEP-SIZE slider.  Clicking any of the directional buttons will cause their turtle to move in the respective direction a distance of STEP-SIZE.

## THINGS TO NOTICE

No matter how you change the various parameters, the same basic plot shape emerges.  After using the model once with the students, ask them how they think the plot will change if you alter a parameter.  Altering the initial percentage sick and the infection chance will have different effects on the plot.

## THINGS TO TRY

Use the model with the entire class to serve as an introduction to the topic.  Then have students use the NetLogo model individually, in a computer lab, to explore the effects of the various parameters.  Discuss what they find, observe, and can conclude from this model.

## EXTENDING THE MODEL

Currently, the turtles remain sick once they're infected.  How would the shape of the plot change if turtles eventually healed?  If, after healing, they were immune to the disease, or could still spread the disease, how would the dynamics be altered?

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. and Stroup, W. (1999).  NetLogo HubNet Disease HubNet model.  http://ccl.northwestern.edu/netlogo/models/HubNetDiseaseHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1999 Uri Wilensky and Walter Stroup.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This activity and associated models and materials were created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 1999 Stroup -->
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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
507
12
925
404
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
138
15
235
64
LOCATED AT:
NIL
3
1

MONITOR
9
15
128
64
YOU ARE GROUP:
NIL
3
1

MONITOR
353
15
495
64
ADJACENT GROUP:
NIL
3
1

MONITOR
245
15
342
64
GENERATION:
NIL
3
1

MONITOR
35
345
138
394
allele one %
NIL
3
1

MONITOR
35
291
138
340
allele one count
NIL
3
1

MONITOR
146
345
248
394
allele two %
NIL
3
1

MONITOR
145
291
247
340
allele two count
NIL
3
1

MONITOR
254
345
360
394
allele three %
NIL
3
1

MONITOR
253
290
359
339
allele three count
NIL
3
1

MONITOR
366
345
472
394
allele four %
NIL
3
1

MONITOR
365
290
471
339
allele four count
NIL
3
1

TEXTBOX
183
405
333
423
NIL
11
0.0
1

INPUTBOX
35
226
137
286
initial-count-one
0
1
0
Number

INPUTBOX
144
226
246
286
initial-count-two
0
1
0
Number

INPUTBOX
252
226
358
286
initial-count-three
0
1
0
Number

INPUTBOX
364
226
470
286
initial-count-four
0
1
0
Number

CHOOSER
67
112
214
157
choose-shape
choose-shape
"spade" "heart" "club"
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
