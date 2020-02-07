;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Variable & Breed Declarations ::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

globals [
  allele-types ; list of alleles used for this simulation
  generation-number ; current generation
  population-radius ; size that the population occupies in the world
  initial-population-size ; the population-size upon initialization
]

breed [ phenotypes phenotype ]
breed [ students student ]
breed [ alleles allele ]

students-own [
  hubnet-client? ; true = hubnet client user ; false = npc student
  user-id ; id that connects each student to the hubnet control center
  phenotype-population ; collection of phenotypes of student
  gene-flow-student ; adjacent student for gene flow during reproduction
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
  ask patches [ set pcolor grey + 2 ]
  ask students [ setup-student ]
  ;update-allele-frequency-plot
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
  if red-allele-on? [ set allele-types lput "red" allele-types ]
  if blue-allele-on? [ set allele-types lput "blue" allele-types ]
  if yellow-allele-on? [ set allele-types lput "yellow" allele-types ]
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
  create-students 1 [ ; NOTE: the space after Wu is important because the code requires names to have a minimum length of 3 characters
    set user-id one-of [ "Walker" "McCann" "Bennett" "Kieper" "Driver" "Rowe" "Smith" "Hollenbeck" "Chang" "Moore" "Wu " "McEwan" "Ortner" "Kennedy" "Anderson" "Roeder" "Paulsen" ]
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
  set shape "clown"
  set gene-flow-student nobody
  create-phenotype-population
  set label user-id
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:       CREATE A PHENOTYPE INDIVIDUALS OF STUDENT AND SET PARAMETERS         ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-phenotype-population
  let parent self
  foreach allele-types [ atype ->
    let number-of-phenotypes floor (population-size / length allele-types)
    hatch-phenotypes number-of-phenotypes
    [
      set first-allele initialize-allele atype
      set second-allele initialize-allele atype
      set parent-student parent
      setup-phenotype
      ask parent [ set phenotype-population lput myself phenotype-population ] ; LINE USED TWICE
    ]
  ]
  if (count phenotypes < population-size) [
    hatch-phenotypes (population-size - count phenotypes)
    [
      let my-atype one-of allele-types
      set first-allele initialize-allele  my-atype
      set second-allele initialize-allele  my-atype
      set parent-student parent
      setup-phenotype
      ask parent [ set phenotype-population lput myself phenotype-population ] ; LINE USED TWICE
    ]
  ]
end

to setup-phenotype
  set size 3
  set label ""
  set hidden? show-alleles
  move-to parent-student move-to one-of patches in-radius ( population-radius * 0.75 )
  set-phenotype-shape-and-color
end

; set the shape and color of phenotype based on alleles
to set-phenotype-shape-and-color
  let allele1 [allele-type] of first-allele
  let allele2 [allele-type] of second-allele
  set shape "clown"
  if allele1 = "red" and allele2 = "red" [ set color red ]
  if ( allele1 = "red" and allele2 = "blue" ) or ( allele2 = "red" and allele1 = "blue" ) [ set color red ]
  if allele1 = "blue" and allele2 = "blue" [ set color blue ]
  if allele1 = "yellow" and allele2 = "yellow" [ set color yellow ]
  if ( allele1 = "yellow" and allele2 = "blue" ) or ( allele2 = "yellow" and allele1 = "blue" ) [ set color yellow ]
  if ( allele1 = "yellow" and allele2 = "red" ) or ( allele2 = "yellow" and allele1 = "red" ) [
    set shape (word "clown " [color] of second-allele)
    set color [color] of first-allele ]
end


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:              CREATE ALLELES OF PHENOTYPE AND SET PARAMETERS                ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; create random allele, add to phenotype, and report
to-report initialize-allele [ atype ]
  let parent self
  let allele-to-report nobody
  hatch-alleles 1 [
    set allele-type atype
    setup-allele
    set parent-phenotype parent
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
  report read-from-string type-input
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Runtime Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to go
  listen-clients
  ask students with [ hubnet-client? = false ] [ student-wander ]
  ask students [ set gene-flow-student get-adjacent-population ]
  ask phenotypes [ phenotype-wander ]
  update-visibility-settings
  update-phenotype-shape-and-color
  update-allele-types-list
  ask students with [ hubnet-client? = true ] [ send-info-to-clients ]
  tick
end

; obsever command to update whether phenotypes or alleles are visible
to update-visibility-settings
  ask alleles [ set hidden? not show-alleles ]
  ask phenotypes [ set hidden? show-alleles ]
end

; observer command to update the "phenotype" of all phenotypes
to update-phenotype-shape-and-color
  ask phenotypes [ set-phenotype-shape-and-color ]
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
  repeat population-size [ ask one-of old-phenotype-population [ reproduce ( one-of total-phenotype-population ) ] ]
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
  let number-of-offspring ( floor rate-of-selection ) + ifelse-value ( random-float 1.0 < ( rate-of-selection - floor rate-of-selection ) ) [ 1 ] [ 0 ]
  hatch-phenotypes ifelse-value (read-from-string selection-on-phenotype = color) [ number-of-offspring ] [ 1 ] [ ; natural selection
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
    set first-allele initialize-allele one-of allele-types ]
  if random-float 1.0 < mutation-rate [
    ask second-allele [ remove-allele ]
    set second-allele initialize-allele one-of allele-types ]
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
to execute-command [command]
  if command = "Up"
  [ execute-move 0 stop ]
  if command = "Down"
  [ execute-move 180 stop ]
  if command = "Right"
  [ execute-move 90 stop ]
  if command = "Left"
  [ execute-move 270 stop ]
end

; student command to send information to corresponding client gui
to send-info-to-clients
  hubnet-send user-id "YOU ARE POPULATION:" user-id
  hubnet-send user-id "LOCATED AT:" (word "(" pxcor "," pycor ")")
  hubnet-send user-id "GENERATION:" generation-number
  hubnet-send user-id "ADJACENT POPULATION:" (word gene-flow-student)
  hubnet-send user-id "Red (R) count" count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "red" ]
  hubnet-send user-id "Blue (b) count" count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "blue" ]
  hubnet-send user-id "Yellow (Y) count" count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "yellow" ]
  hubnet-send user-id "Red (R) %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "red" ]) / (count alleles with [ member? parent-phenotype [phenotype-population] of myself] + .0001)) 3
  hubnet-send user-id "Blue (b) %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "blue" ]) / (count alleles with [ member? parent-phenotype [phenotype-population] of myself] + .0001)) 3
  hubnet-send user-id "Yellow (Y) %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-population] of myself and allele-type = "yellow" ]) / (count alleles with [ member? parent-phenotype [phenotype-population] of myself] + .0001)) 3
  hubnet-send user-id "genotype Rb" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "red" and [allele-type] of second-allele = "blue" ) or ( [allele-type] of first-allele = "blue" and [allele-type] of second-allele = "red" ))]
  hubnet-send user-id "genotype RY" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "red" and [allele-type] of second-allele = "yellow" ) or ( [allele-type] of first-allele = "yellow" and [allele-type] of second-allele = "red" ))]
  hubnet-send user-id "genotype Yb" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "blue" and [allele-type] of second-allele = "yellow" ) or ( [allele-type] of first-allele = "yellow" and [allele-type] of second-allele = "blue" ))]
  hubnet-send user-id "genotype RR" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "red" and [allele-type] of second-allele = "red" ) or ( [allele-type] of first-allele = "red" and [allele-type] of second-allele = "red" ))]
  hubnet-send user-id "genotype bb" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "blue" and [allele-type] of second-allele = "blue" ) or ( [allele-type] of first-allele = "blue" and [allele-type] of second-allele = "blue" ))]
  hubnet-send user-id "genotype YY" count phenotypes with [ member? self [phenotype-population] of myself and (( [allele-type] of first-allele = "yellow" and [allele-type] of second-allele = "yellow" ) or ( [allele-type] of first-allele = "yellow" and [allele-type] of second-allele = "yellow" ))]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Plots ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to update-allele-frequency-plot

  set-current-plot "Simpson's Diversity per Population"
  clear-plot

  let index 0
  foreach sort students [ s ->
    let this-current-student s
    let sum-of-squares 0

    foreach allele-types [ atype ->
      set sum-of-squares sum-of-squares + (( count alleles with [ color = read-from-string atype and [parent-student] of parent-phenotype = this-current-student ] / ( 2 * population-size )) ^ 2)
    ]

    set-current-plot-pen "default"
    plot-pen-down
    plotxy ( index + 0.1 ) ( 1 - sum-of-squares )
    plot-pen-up

    set index index + 1
  ]

  set-current-plot "Proportion of Alleles Per Population"
  clear-plot

  set index 0
  foreach sort students [ s ->
    let this-current-student s
    let allele-frequency-so-far 1

    foreach allele-types [ atype ->

      set-current-plot-pen atype
      plot-pen-down
      plotxy ( index + 0.1 ) allele-frequency-so-far
      plot-pen-up

      set allele-frequency-so-far allele-frequency-so-far - ( count alleles with [ color = read-from-string atype and [parent-student] of parent-phenotype = this-current-student ] / ( 2 * population-size ))
      if allele-frequency-so-far < 0 [ set allele-frequency-so-far 0 ]

    ]
    set index index + 1
  ]

  set-current-plot "Proportion of Alleles Over Generations"
  let allele-frequency-so-far 1
  foreach allele-types [ t ->
    set-current-plot-pen t
    plot-pen-down
    let space-index 0
    repeat 100 [
      plotxy ( generation-number - 1 + space-index ) allele-frequency-so-far
      set space-index space-index + 0.01
    ]
    plot-pen-up
    set allele-frequency-so-far ( allele-frequency-so-far - ((count alleles with [ allele-type = t ] / (count alleles + 0.00001))))
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
207
10
919
723
-1
-1
17.171
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
1061
10
1179
43
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
934
10
1050
43
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
17
507
195
540
allow-gene-flow?
allow-gene-flow?
0
1
-1000

TEXTBOX
17
433
210
451
--------- Mutation -----------
11
0.0
1

TEXTBOX
17
490
210
508
-------- Gene Flow -----------
11
0.0
1

TEXTBOX
18
548
210
566
------ Natural Selection -------
11
0.0
1

SLIDER
17
452
194
485
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
17
566
195
611
selection-on-phenotype
selection-on-phenotype
"red" "blue" "yellow"
0

SLIDER
17
616
195
649
rate-of-selection
rate-of-selection
0
5
1.5
.1
1
NIL
HORIZONTAL

TEXTBOX
34
40
177
61
---- red (R) allele ----
12
0.0
1

TEXTBOX
31
154
179
184
---- blue (b) allele ----\n
12
0.0
1

SWITCH
1160
56
1334
89
show-alleles
show-alleles
1
1
-1000

SWITCH
20
60
192
93
red-allele-on?
red-allele-on?
0
1
-1000

SWITCH
20
175
192
208
blue-allele-on?
blue-allele-on?
0
1
-1000

SWITCH
20
289
192
322
yellow-allele-on?
yellow-allele-on?
0
1
-1000

TEXTBOX
28
268
184
298
---- yellow (Y) allele ----
12
0.0
1

TEXTBOX
31
405
181
423
EVOLUTION SETTINGS
14
0.0
1

MONITOR
20
98
192
143
red allele count
count alleles with [ allele-type = \"red\" ]
17
1
11

MONITOR
20
213
192
258
blue allele count
count alleles with [ allele-type = \"blue\" ]
17
1
11

MONITOR
20
327
192
372
yellow allele count
count alleles with [ allele-type = \"yellow\" ]
17
1
11

TEXTBOX
59
10
158
28
ALLELE TYPES
14
0.0
1

BUTTON
1188
10
1334
43
reproduce
set generation-number generation-number + 1\nask students [ execute-reproduce ]\nask students [ if ( length phenotype-population > population-size ) [foreach n-of (length phenotype-population - population-size) phenotype-population [ [?1] -> ask ?1 [remove-phenotype] ]]]\nupdate-allele-frequency-plot
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
934
49
1015
94
Generation
generation-number
17
1
11

MONITOR
1023
49
1149
94
Total Population
count phenotypes
17
1
11

BUTTON
1188
101
1334
134
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
934
101
1178
134
population-size
population-size
0
100
10.0
5
1
NIL
HORIZONTAL

PLOT
934
268
1334
490
Proportion of Alleles per Population
population
proportion of alleles
0.0
6.0
0.0
1.0
true
false
"" ""
PENS
"red" 0.9 1 -2674135 true "" ""
"blue" 0.9 1 -13345367 true "" ""
"yellow" 0.9 1 -4079321 true "" ""

PLOT
934
496
1334
718
Proportion of Alleles Over Generations
generation
proportion of alleles
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"red" 0.5 1 -2674135 true "" ""
"blue" 0.5 1 -13345367 true "" ""
"yellow" 0.5 1 -4079321 true "" ""

PLOT
934
143
1334
263
Simpson's Diversity per Population
population
D
0.0
6.0
0.0
1.0
true
false
"" ""
PENS
"default" 0.9 1 -16777216 true "" ""

@#$#@#$#@
# Population Genetics 1.5.0

## WHAT IS IT?

This model simulates the mechanisms of evolution, or how allele frequencies change in a population over time. Here, you can choose to have up to three different types of alleles for some arbitrary locus. The phenotypes of these alleles can also be displayed and are based on their allele relationships (i.e. dominant or recessive). In the 1001 version of Population Genetics, the alleles and their relationships are predetermined: red is dominant over blue, and codominant with yellow.

During the simulation, "students" control populations of alleles/phenotypes via a HubNet Client and a "teacher" controls the environment via the HubNet Control Center. The "Allele Frequencies" plot shows how the allele frequencies are changing over time.

## HOW IT WORKS

### TEACHER: HubNet Control Center

STARTUP: The HubNet Control Center should start upon opening this model. Change any of the paramater settings depending on what aspect of evolution you want to simulate. Press the GO button.

INSTRUCTIONS FOR STUDENTS: Instruct your students to open the NetLogo HubNet Client application, type their user name, select this activity and press ENTER. Make sure they choose the correct port number and server address for this simulation. Instruct your students to move their populations around to acquaint themselves with the interface. If you would like the students to input specific initial allele counts, instruct them to do so now. Instructors can also press the ADD POPULATION button to produce another "non-playable" population in the world.

SIMULATION: Press the REPRODUCE button to cause each population to reproduce. Investigate how the allele frequencies have changed and instruct your students to record the specifics for their population. Continue to press the REPRODUCE button and record how the EVOLUTION SETTINGS affect how the populations change over time. Modify the EVOLUTION SETTINGS as need to change the environmental factors altering allele frequencies.

### STUDENT: HubNet Client

STARTUP: Students should open the NetLogo HubNet Client application, type their user name, select this activity and press ENTER. Make sure to choose the correct port number and server address for this simulation.

After logging in, the client interface will appear for the students, and if GO is pressed in NetLogo they will be assigned a population of alleles/phenotypes. The YOU ARE GROUP: monitor will display the name entered upon startup and will also appear on the simulation to label the appropriate population. The current location will be shown in the LOCATED AT: monitor.

SIMULATION: Students are able to control the movement of their population with the UP, DOWN, LEFT, and RIGHT buttons. They can also input values for the initial allele configuration, if they desire different starting values then the ones given. Monitors show the current allele frequency count and percentage, genotype counts and phenotype colors, as well as the current generation and closest adjacent population.

## HOW TO USE IT

### GENERAL

SETUP: returns the model to the starting state.
GO: runs the simulation.
ADD POPULATION: when pressed, a new "non-playable" allele/phenotype population is added to the world. It wanders randomly and its phenotypes can reproduce and share alleles with adjacent populations.
REPRODUCE: when pressed, all individual phenotypes reproduce with someone else in their gene pool.
SHOW-ALLELES: when on, the alleles of the population are shown, otherwise the individual phenotypes are shown, which are based on the relationships between allele pairs.

### ALLELE SETTINGS

X-ALLELE-ON: allows the given allele type to be part of the allele population.

### EVOLUTION SETTINGS

MUTATION-RATE: the rate at which alleles mutate to a random allele upon reproduction.
ALLOW-GENE-FLOW?: when on, allows populations that are close enough to an ADJACENT POPULATION to share alleles upon reproduction.
SELECTION-ON-PHENOTYPE: selects the phenotype color that natural selection can act upon during the simulation.
RATE-OF-SELECTION: for a phenotype that matches the currently set SELECTION-ON-PHENOTYPE this sets the average number of offspring that phenotype will have when they reproduce.

### MONITORS & PLOTS

X ALLELE COUNT: the total allele count for the given allele type, or for a given student.
GENOTYPE X: the count of a certain genotype
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

## POPULATION NAMES

The names generated during ADD POPULATION are taken from Huerta-Sánchez, Rohlfs and collegues' work on revealing the hidden female contributions to population genetics:

Dung, S. K., López, A., Barragan, E. L., Reyes, R. J., Thu, R., Castellanos, E., Catalan, F., Huerta-Sánchez, E. & Rohlfs, R. V. (2019). Illuminating Women’s Hidden Contribution to Historical Theoretical Population Genetics. Genetics, 211(2), 363-366.

## COPYRIGHT AND LICENSE

 © 2020 K N Crouse

This model was created at the University of Minnesota as part of a series of models to illustrate principles in biological evolution.

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

clown
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121

clown 15
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -2674135 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -2674135 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -2674135 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 45
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1184463 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1184463 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1184463 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 95
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -13791810 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -13791810 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -13791810 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

fish 2
false
0
Polygon -1 true false 56 133 34 127 12 105 21 126 23 146 16 163 10 194 32 177 55 173
Polygon -7500403 true true 156 229 118 242 67 248 37 248 51 222 49 168
Polygon -7500403 true true 30 60 45 75 60 105 50 136 150 53 89 56
Polygon -7500403 true true 50 132 146 52 241 72 268 119 291 147 271 156 291 164 264 208 211 239 148 231 48 177
Circle -1 true false 237 116 30
Circle -16777216 true false 241 127 12
Polygon -1 true false 159 228 160 294 182 281 206 236
Polygon -7500403 true true 102 189 109 203
Polygon -1 true false 215 182 181 192 171 177 169 164 152 142 154 123 170 119 223 163
Line -16777216 false 240 77 162 71
Line -16777216 false 164 71 98 78
Line -16777216 false 96 79 62 105
Line -16777216 false 50 179 88 217
Line -16777216 false 88 217 149 230

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
519
10
1132
621
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
349
25
411
58
Up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
348
91
410
124
Down
NIL
NIL
1
T
OBSERVER
NIL
K

BUTTON
410
58
472
91
Right
NIL
NIL
1
T
OBSERVER
NIL
L

BUTTON
286
58
348
91
Left
NIL
NIL
1
T
OBSERVER
NIL
J

MONITOR
167
23
262
72
LOCATED AT:
NIL
3
1

MONITOR
17
23
162
72
YOU ARE POPULATION:
NIL
3
1

MONITOR
17
76
162
125
ADJACENT POPULATION:
NIL
3
1

MONITOR
168
76
263
125
GENERATION:
NIL
3
1

MONITOR
119
180
209
229
Red (R) %
NIL
3
1

MONITOR
19
180
114
229
Red (R) count
NIL
3
1

MONITOR
120
234
210
283
Blue (b) %
NIL
3
1

MONITOR
19
234
115
283
Blue (b) count
NIL
3
1

MONITOR
122
289
211
338
Yellow (Y) %
NIL
3
1

MONITOR
19
289
116
338
Yellow (Y) count
NIL
3
1

TEXTBOX
167
665
317
683
NIL
11
0.0
1

TEXTBOX
88
156
152
174
ALLELES
14
0.0
1

MONITOR
372
181
495
230
genotype Rb
NIL
3
1

MONITOR
372
235
497
284
genotype RY
NIL
3
1

MONITOR
238
290
368
339
genotype Yb
NIL
3
1

MONITOR
237
181
367
230
genotype RR
NIL
3
1

MONITOR
238
235
368
284
genotype bb
NIL
3
1

MONITOR
373
290
498
339
genotype YY
NIL
3
1

TEXTBOX
327
154
420
172
GENOTYPES
14
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
