;Target-oriënted particle-based slime mold-algorithm by F.S. Slijkhuis
;____________________________________________________________________

;Two different breeds: ants and foodpoints
breed [ants ant]
breed [foodpoints food]

;Global patches-variables
patches-own[pheromone foodpatch barricade sprayed]

;Global ants-variables
ants-own[blessed target prefangle]

;Other global variables
globals[maxpheromoneamount pheromoneinvisible number nopheromone]

;Before running the model, we run the following code:
to setup
  clear-all
  reset-ticks
  resize-world 0 size-of-world 0 size-of-world
  ;This determines the size of the patches, they are scaled according to the size of the world, keeping the frame exactly the same size.
  set-patch-size 600 * size-of-world ^(-1)
  create-food foodpatchamount
  ;The amount of ants can be based on coverage, but can also be added later.
  create-ant round((coverage / 100) * (size-of-world * size-of-world))
  set pheromoneinvisible false
  ask patches[set barricade false]
  ;Setpatches is used to set up the environment, making patches underneath foodpoints 'foodpatches'.
  setpatches
  ;Targets must be assigned first, before the ants can utilize them.
  if (enable-targets = true)[
    ask ants[settarget]
  ]
end

;'Run' runs this code continually, 'Step' runs this code once.
to go
  blessing
  if (enable-targets = true)[
    ;When enable-targets is enabled, we check if any ants have reached its target, if yes, these ants will get a new target.
    ask foodpoints[
      let randomfood one-of other foodpoints
      ask ants with [target = myself] in-radius (Size - (Size / 2))[
        set target randomfood
      ]
    ]
    ;After this, the ants will move. 'Movetargets' runs the Sensory stage and Movement stage for all ants, but the sensory stage is modified.
    movetargets
  ]
  ;
  if (enable-targets = false)[
    ;The normal 'move' does not have a modified sensory stage.
    move
  ]
  if not (pheromone-evaporation-rate = 0.00) [pheromoneevaporation]
  if not (pheromone-diffusion-rate = 0.00) [pheromonediffusion]
  pheromonecolors
  tick
end

;This code is used to create foodpoints.
to create-food [amount]
  create-foodpoints amount[
    set color red
    set size size-of-food-patches
    set shape "circle"
    setxy random-pxcor random-pycor
  ]
end

;Setpatches makes patches underneath foodpoints into foodpatches, which increase pheromone.
to setpatches
  ask patches [set foodpatch false]
  ask foodpoints[
    ask patches in-radius (Size - (Size / 2))[
      set foodpatch true
    ]
  ]
end

;This code is used to create ants.
to create-ant [amount]
  create-ants amount[
    set size 0.5
    set shape "circle"
    set color green
    set blessed false
    positionants
  ]
end

;Created ants will be placed somewhere on the field, depending on the settings used.
to positionants
  if starting-position = "On center"[
      setxy round(Size-of-world / 2) round(Size-of-world / 2)
    ]
    if starting-position = "Spread"[
      setxy random-pxcor random-pycor
    if [barricade = true] of patch-here [
      positionants
    ]
    ]
    if starting-position = "On food-patches"[
      if one-of foodpoints = nobody[
        set starting-position "On center"
        stop
      ]
      move-to one-of foodpoints
    ]
end

;The normal move-function asks all ants to go through the sensory stage and movement stage.
to move
  ask ants[ants-heading]
  ask ants[ants-move]
end

;The target move-function asks all ants to go through the modified sensory stage and movement stage.
to movetargets
  ask ants[ants-headingtargets]
  ask ants[ants-move]
end

;This code makes pheromone evaporate.
to pheromoneevaporation
  ask patches with [pheromone > 0][
    set pheromone floor(pheromone - (pheromone * (pheromone-evaporation-rate / 100)))
  ]
end

;This code makes pheromone diffuse.
to pheromonediffusion
  diffuse pheromone Pheromone-diffusion-rate ;diffusie commando van netlogo, met zelf in te stellen pheromoon-diffusie-ratio
end

;This code determines the color of each patch, depending on the settings.
to pheromonecolors
  ifelse nopheromone = false[
    ifelse pheromoneinvisible = false[
      ifelse manualmax = true[
        ask patches with [barricade = false][
        set pcolor scale-color yellow pheromone 0 pheromone-contrast
      ]
      ]
      [
        ask max-one-of patches with [foodpatch = false] [pheromone][
          set maxpheromoneamount pheromone
        ]
        ask patches with [barricade = false][
        set pcolor scale-color yellow pheromone 0 maxpheromoneamount
      ]
      ]
    ]
    [
      ask patches with [barricade = false][set pcolor black]
    ]
  ]
  [
    ask patches with [barricade = false] [
      set pcolor black
    ]
  ]
end

;The non-modified sensory stage is the same sensory stage as in Jones' Physarum model.
to ants-heading
  if patch-ahead Antenna-length = nobody or [barricade = true] of patch-ahead Antenna-length or patch-left-and-ahead Antenna-angle Antenna-length = nobody or [barricade = true] of patch-left-and-ahead Antenna-angle Antenna-length or patch-right-and-ahead Antenna-angle Antenna-length = nobody or [barricade = true] of patch-right-and-ahead Antenna-angle Antenna-length[
    face one-of patches in-radius Antenna-length with [barricade = false]
    stop
  ]

  let FF [pheromone] of patch-ahead Antenna-length
  let FL [pheromone] of patch-left-and-ahead Antenna-angle Antenna-length
  let FR [pheromone] of patch-right-and-ahead Antenna-angle Antenna-length

  if (FF > FL) and (FF > FR)[
    stop
  ]
  ifelse (FF < FL) and (FF < FR)[
    let randomnumber random 1
    ifelse randomnumber = 0[
      left Turn-angle
    ]
    [
      right Turn-angle
    ]
  ]
  [
    if (FL < FR)[
      right Turn-angle
      stop
    ]
    if (FL > FR)[
      left Turn-angle
      stop
    ]
  ]
end

;The modified sensory stage is used for the targets.
to ants-headingtargets
  if patch-ahead Antenna-length = nobody or [barricade = true] of patch-ahead Antenna-length or patch-left-and-ahead Antenna-angle Antenna-length = nobody or [barricade = true] of patch-left-and-ahead Antenna-angle Antenna-length or patch-right-and-ahead Antenna-angle Antenna-length = nobody or [barricade = true] of patch-right-and-ahead Antenna-angle Antenna-length[
    face one-of patches in-radius Antenna-length with [barricade = false]
    stop
  ]

  let FPa patch-ahead Antenna-length
  let LPa patch-left-and-ahead Antenna-angle Antenna-length
  let RPa patch-right-and-ahead Antenna-angle Antenna-length

  let FF [pheromone] of FPa
  let FL [pheromone] of LPa
  let FR [pheromone] of Rpa

  ;We increase the amount of perceived pheromone for the antenna which will guide us to the target.
  let headingfood towards target
  let FFheading towards patch-ahead Step-size

  let trueheadingfood (headingfood - FFheading)
  if trueheadingfood < 0[
    set trueheadingfood (360 + trueheadingfood)
  ]
  ifelse trueheadingfood > Turn-angle[
    if trueheadingfood > 180 and trueheadingfood < (360 - Turn-angle)[
      set prefangle "FL"
    ]
    ifelse trueheadingfood < (360 - Turn-angle)[
      set prefangle "FR"
    ]
    [
      set prefangle "FF"
    ]
  ]
  [
      set prefangle "FF"
  ]

  if prefangle = "FF"[
    set FF (FF * Targetfactor)
  ]

  if prefangle = "FL"[
    set FL (FL * Targetfactor)
  ]

  if prefangle = "FR"[
    set FR (FR * Targetfactor)
  ]

  ;We run the normal sensory stage with the increased pheromone for one antenna.
  if (FF > FL) and (FF > FR)[
    stop
  ]
  ifelse (FF < FL) and (FF < FR)[
    let randomnumber random 1
    ifelse randomnumber = 0[
      left Turn-angle
    ]
    [
      right Turn-angle
    ]
  ]
  [
    if (FL < FR)[
      right Turn-angle
      stop
    ]
    if (FL > FR)[
      left Turn-angle
      stop
    ]
  ]
end

;The movement stage for ants.
to ants-move
  ;When there is an ant on the patch where we want to move, we give the ant a random heading.
  ifelse co-location = true and any? ants-on patch-ahead Step-size[
    set heading random-float 360
  ]
  [
  fd Step-size
  ]
  if blessed = true[
    ask patch-here[
      ;Pheromone-deposition is done here.
      ifelse foodpatch = true [
        set pheromone pheromone + (pheromone-deposit-ratio * pheromone-intensity-foodpatches)
      ][
        set pheromone pheromone + pheromone-deposit-ratio
        set nopheromone false
      ]
    ]
  ]
end

;Blessed ants can drop pheromone, this code turns ants on foodpatches into blessed ants.
to blessing
  ask ants-on patches with [foodpatch = true][
    if blessed = false[
      set blessed true
    ]
  ]
end

;A simple function to toggle ant-visibility.
to make-ants-invisible
  ask ants[
    ifelse hidden? [st][ht]
  ]
end

;A simple function to toggle pheromone-visibility.
to make-pheromone-invisible
  ifelse pheromoneinvisible = true [set pheromoneinvisible false][set pheromoneinvisible true]
end

;A simple function to toggle food-visibility.
to make-food-invisible
  ask foodpoints[
    ifelse hidden? [st][ht]
  ]
end

;This code resets the location of all ants, depending on the settings. It also sets the targets again.
to reset-location
  ask ants[
    positionants
  ]
  if (enable-targets = true)[
    ask ants[settarget]
  ]
end

;This code removes all pheromone from the field.
to remove-pheromone
  ask patches[
    set pheromone 0
  ]
  set nopheromone true
  pheromonecolors
end

;This code adds X amount of ants, X can be modified in the settings.
to add-x
  create-ant Amount-X
  if (enable-targets = true)[
    ask ants[settarget]
  ]
end

;This code removes X amount of ants, X can be modified in the settings.
to remove-x
  ask n-of Amount-X ants [die]
end

;This function imports an existing scenario (world in Netlogo) from the computer.
to import-scenario
  import-world Scenario-name
end

;This function exports an existing scenario (world in Netlogo) from the computer.
to export-scenario
  export-world Scenario-name
end

;This function imports an image from the computer, which is scaled to fit inside the view-panel.
to import-image
  import-pcolors image-name
end

;This function can add one foodpoint where the mousepointer is, when clicked. It also resets the targets.
to add-food
  ifelse mouse-down?[
    if number = 1[
      create-foodpoints 1[
        set color red
        set size Size-of-food-patches
        set shape "circle"
        setxy mouse-xcor mouse-ycor
      ]
      set number 0
    ]
  ]
  [setpatches
    set number 1]
  if (enable-targets = true)[
    ask ants[settarget]
  ]
end

;This function removes the foodpoint where the mousepointer is, when clicked. It also resets the targets.
to remove-food
  ifelse mouse-down?[
    ask patch mouse-xcor mouse-ycor[
      if any? foodpoints in-radius Size-of-food-patches [
        ask foodpoints in-radius Size-of-food-patches [
          die
        ]
      ]
    ]
  ]
  [setpatches]
  if (enable-targets = true)[
    ask ants[settarget]
  ]
end

;This function moves food around, when clicking and holding on a foodpoint.
to move-food
  ifelse mouse-down?[
    ask patch mouse-xcor mouse-ycor[
      if any? foodpoints in-radius Size-of-food-patches[
        ask foodpoints in-radius Size-of-food-patches[
          setxy mouse-xcor mouse-ycor
        ]
      ]
    ]
  ]
  [setpatches]
end

;This function increases the size of a foodpoint, when clicked on a foodpoint.
to enlarge-food
  ifelse mouse-down?[
    if number = 1[
      ask patch mouse-xcor mouse-ycor[
        if any? foodpoints in-radius Size-of-food-patches[
          ask foodpoints in-radius Size-of-food-patches[
            set size (size + 0.5)
            set number 0
          ]
        ]
      ]
    ]
  ]
  [setpatches
    set number 1]
end

;This function decreases the size of a foodpoint, when clicked on a foodpoint.
to shrink-food
  ifelse mouse-down?[
    if number = 1[
      ask patch mouse-xcor mouse-ycor[
        if any? foodpoints in-radius Size-of-food-patches[
          ask foodpoints in-radius Size-of-food-patches[
            set size (size - 0.5)
            set number 0
          ]
        ]
      ]
    ]
  ]
  [setpatches
    set number 1]
end

;This function makes it possible to spray pheromone at the mousepointer, when clicked.
to spray-pheromone
  ifelse mouse-down?[
    ask patch mouse-xcor mouse-ycor[
      ask patches in-radius (Brush-size - 1)[
        if sprayed = false[
          set Pheromone (pheromone + (Pheromone-deposit-ratio * Brush-intensity))
          set pcolor white
          set sprayed true
        ]
      ]
    ]
  ]
  [ask patches[set sprayed false]]
end

;This function makes it possible to erase pheromone at the mousepointer, when clicked.
to erase-pheromone
  ifelse mouse-down?[
    ask patch mouse-xcor mouse-ycor[
      ask patches in-radius (Brush-size - 1)[
        if sprayed = false[
          set pcolor black
          set pheromone (pheromone - (Pheromone-deposit-ratio * Brush-intensity))
          set sprayed true
          if pheromone < 0[
            set pheromone 0
          ]
        ]
      ]
    ]
  ]
  [ask patches[set sprayed false]]
  pheromonecolors
end

;This function adds barricades, when enabled and when the mouse clicks. It acts like a brush.
to add-barricade
  if mouse-down?[
    ask patch mouse-xcor mouse-ycor[
      ask patches in-radius (Brush-size - 1)[
        if Color-of-barricade = "blue"[
          set pcolor blue
        ]
        if Color-of-barricade = "red"[
          set pcolor red
        ]
        if Color-of-barricade = "yellow"[
          set pcolor yellow
        ]
        if Color-of-barricade = "green"[
          set pcolor green
        ]
        if Color-of-barricade = "black"[
          set pcolor black
        ]
        if Color-of-barricade = "grey"[
          set pcolor grey
        ]
        if Color-of-barricade = "white"[
          set pcolor white
        ]
        set barricade true
      ]
    ]
  ]
  ask ants-on patches with [barricade = true][
    move-to one-of patches with [barricade = false]
  ]
end

;This function removes barricades, when enabled and when the mouse clicks. It acts like a brush.
to remove-barricade
  if mouse-down?[
    ask patch mouse-xcor mouse-ycor[
      ask patches in-radius (Brush-size - 1)[
        set pcolor black
        set barricade false
      ]
    ]
  ]
end

;This function can be used to add a foodpoint at very specific coordinates.
to add-foodpoint-xy
  create-foodpoints 1[
        set color red
        set size Size-of-food-patches
        set shape "circle"
        setxy X Y
      ]
  setpatches
end

;This function blesses all ants instantly.
to bless
  ask ants[
    set blessed true
  ]
end

;This function assigns a random target to an ant.
to settarget
  set target one-of foodpoints
end

;This function resets ticks ant unblesses all ants.
to unbless-and-reset
  ask ants[
    set blessed false
  ]
  reset-ticks
end
@#$#@#$#@
GRAPHICS-WINDOW
209
10
819
621
-1
-1
2.0
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
300
0
300
0
0
1
ticks
30.0

BUTTON
36
173
92
206
Setup
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

INPUTBOX
136
10
208
70
Size-of-world
300.0
1
0
Number

SLIDER
36
139
208
172
Size-of-food-patches
Size-of-food-patches
1
20
4.5
0.5
1
NIL
HORIZONTAL

SLIDER
36
105
208
138
Foodpatchamount
Foodpatchamount
0
50
0.0
1
1
NIL
HORIZONTAL

SLIDER
36
71
208
104
Coverage
Coverage
0
15
0.0
1
1
NIL
HORIZONTAL

BUTTON
93
173
150
206
Run
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
151
173
208
206
Step
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

SLIDER
36
343
208
376
Pheromone-deposit-ratio
Pheromone-deposit-ratio
1
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
36
411
208
444
Pheromone-intensity-foodpatches
Pheromone-intensity-foodpatches
1
1000
50.0
1
1
NIL
HORIZONTAL

SLIDER
36
207
208
240
Step-size
Step-size
0
5
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
36
241
208
274
Antenna-length
Antenna-length
0.5
20
9.0
0.5
1
NIL
HORIZONTAL

SLIDER
36
275
208
308
Antenna-angle
Antenna-angle
5
70
45.0
2.5
1
NIL
HORIZONTAL

SLIDER
36
309
208
342
Turn-angle
Turn-angle
5
90
45.0
5
1
NIL
HORIZONTAL

SLIDER
36
377
208
410
Pheromone-evaporation-rate
Pheromone-evaporation-rate
0
2
0.4
0.01
1
NIL
HORIZONTAL

CHOOSER
36
25
135
70
Starting-position
Starting-position
"On center" "Spread" "On food-patches"
2

BUTTON
36
479
101
512
Toggle ants
make-ants-invisible
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
102
479
208
512
Toggle pheromone
make-pheromone-invisible
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
36
513
101
546
Toggle food
make-food-invisible
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
102
513
208
546
Reset location
reset-location
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
821
10
883
77
Amount-X
1000.0
1
0
Number

BUTTON
36
547
208
580
Remove Pheromone
remove-pheromone
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
36
582
208
615
Reset location and pheromone
reset-location\nremove-pheromone
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
884
10
993
43
Add X ants
add-x
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
884
44
993
77
Remove X ants
remove-x
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
821
173
907
206
Import scenario
import-scenario
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
821
207
993
267
Scenario-name
Nederland2510k
1
0
String

BUTTON
908
173
993
206
Export scenario
export-scenario
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
821
268
993
301
Import image
import-image
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
821
302
993
362
Image-name
nederland25.png
1
0
String

BUTTON
821
363
907
396
Add foodpoint
add-food
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
908
363
993
396
Remove foodpoint
remove-food
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
821
397
993
430
Move foodpoint
move-food
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
821
431
907
464
Enlarge foodpoint
enlarge-food
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
908
431
993
464
Shrink foodpoint
shrink-food
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
821
465
907
498
Spray pheromone
spray-pheromone
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
908
465
993
498
Erase pheromone
erase-pheromone
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
821
567
907
600
Draw barricade
add-barricade
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
908
567
993
600
Erase berricade
remove-barricade
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
821
499
993
532
Brush-size
Brush-size
0
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
821
533
993
566
Brush-intensity
Brush-intensity
1
50
5.0
1
1
NIL
HORIZONTAL

CHOOSER
821
601
993
646
Color-of-barricade
Color-of-barricade
"blue" "yellow" "red" "green" "black" "grey" "white"
0

BUTTON
821
78
993
111
Add foodpoint on X,Y
add-foodpoint-xy
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
821
112
907
172
X
100.0
1
0
Number

INPUTBOX
908
112
993
172
Y
150.0
1
0
Number

SLIDER
36
445
208
478
pheromone-diffusion-rate
pheromone-diffusion-rate
0
0.3
0.02
0.01
1
NIL
HORIZONTAL

BUTTON
36
616
208
656
Bless all ants
bless
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
209
623
326
656
Enable-targets
Enable-targets
0
1
-1000

SLIDER
327
623
499
656
TargetFactor
TargetFactor
0
50
5.0
1
1
NIL
HORIZONTAL

SWITCH
500
623
605
656
Co-location
Co-location
0
1
-1000

SWITCH
606
623
706
656
ManualMax
ManualMax
0
1
-1000

SLIDER
707
623
820
656
Pheromone-contrast
Pheromone-contrast
1
1000
381.0
10
1
NIL
HORIZONTAL

BUTTON
36
657
208
690
Unbless all ants and reset ticks
unbless-and-reset
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
209
657
273
690
Set targets
ask ants[settarget]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is an adaptation to Jones' regular particle-based slime mold-algorithm, by F.S. Slijkhuis. It can run both the regular model, and a model which implements target-orientation for each individual ant. This model is used in 'Transport network creation of target-oriented particle-based models of Physarum Polycephalum' by F.S. Slijkhuis (2018).

## HOW IT WORKS

Agents, in this model called 'ants', drop pheromone on a field, which they also use to traverse the field. They move inbetween red dots, which resemble food points. For further details, please view 'Influences on the formation and evolution of Physarum polycephalum inspired emergent transport networks' by J. Jones (2011), or 'Transport network creation of target-oriented particle-based models of Physarum Polycephalum' by F.S. Slijkhuis (2018).

## HOW TO USE IT

* To setup the model, click 'Setup'. This will create ants, depending on the specified coverage. It also creates food points, which is determined by the 'Foodpatchamount'-slider. The created food points have a size determined by 'Size-of-food-patches'. The created ants will start somewhere on the field, determined by 'Starting-position'. The size of the field can be altered with 'Size-of-world'. The size of patches is not adjustable, this is determined by the size of the world, keeping the field the exact same size. For further details on this, please visti the 'code' section of this model. 

* To run the model, click 'Run'. To run this model for only one step, click 'Step'. 

* Some basic parameters of the model are 'Step-size', which determines the step size of the ants, 'Antenna-length', which determines the length of the antennas of the ants, 'Antenna-angle', which determines the angle between the antennas, 'Turn-angle', which determines the rotation angle of the ants, 'Pheromone-deposit-ratio', which determines the amount of pheromone that is dropped, 'Pheromone-evaporation-rate', which determines the amount of pheromone which evaporates every tick, 'Pheromone-intensity-foodpatches', which determines the factor by which pheromone is intensified on food points, 'Pheromone-diffusion-rate', which determines the amount of pheromone which is diffused every tick. 

* 'Toggle ants', 'Toggle pheromone' and 'Toggle food' are for visual use. Toggling them will turn the specified object invisible.

* 'Reset location' will move all ants to the location specified in 'Starting-position'.

* 'Remove pheromone' will remove all pheromone from the field instantly.

* 'Bless all ants' will turn the blessed-status of all ants to true instantly. Normally, when 'Setup' is run, ants will not be blessed, which does not allow them to drop pheromone before reaching a food point. 

* 'Unbless all ants and reset ticks' is practical for resetting the model, without clearing the field.

* 'Set targets' manually sets the targets for all ants.

* To make the field into a torus or other shape, right click the field, and change the way it wraps. 

* 'Enable-targets' enables target-orientation for all ants, which uses 'Targetfactor'. To enable targets, targets must be set first, which can be done by resetting the location of all ants, or manually click 'Set targets'. 

* 'Co-location' toggles co-location, allowing more than one ant to be on the same patch. 

* 'ManualMax' and 'Pheromone-contrast' are visual parameters. 'ManualMax' toggles manual color intensity, which can be changed with the 'Pheromone-contrast'-slider. 

* A specific amount of ants can be added or removed with 'Add X ants' and 'Remove X ants'. The amount X is determined by 'Amount-X'. 

* A food point can be placed at a very specific coordinate, by choosing coordinates in 'X' and 'Y', and clicking 'Add foodpoint on X,Y'.

* Scenarios can be imported and exported easily, with 'Import scenario' and 'Export scenario'. The scenario name must be specified in 'Scenario-name', and must exist in the same location as this .nlogo-file. 

* Images can be easily imported with 'Import image' and 'Image-name'. The image must be in the same location as this .nlogo-file. The image is automatically scaled and will not be stretched. 

* Foodpoints can be added and removed with a mouseclick with 'Add foodpoint' and 'Remove foodpoint'. They can be moved with 'Move foodpoint'. They can be enlarged with 'Enlarge foodpoint', and shrunk with 'Shrink foodpoint'. All of these actions utilize the mousepointer and the left mouse button. Please only enable one of these buttons at the time.

* Pheromone can be sprayed, like a brush, with 'Spray pheromone'. The same way pheromone can be sprayed, it can be erased, with 'Erase pheromone'. The size of the brush is determined by 'Brush-size'. The intensity, useful for spraying pheromone, is determined by 'Brush-intensity'. 

* Barricade can be drawn and erased with 'Draw barricade' and 'Erase barricade'. The amount of barricade which is drawn is specified by 'Brush-size'. The color of the barricade is determined by 'Color-of-barricade'. 


## THINGS TO TRY

The scenarios used in 'Transport network creation of target-oriented particle-based models of Physarum Polycephalum' are available in the 'Scenarios'-folder on Github. To import these scenarios, copy them to the same location as this .nlogo-file, and import them using 'Import scenario' and the filename in 'Scenario-name'. 

## EXTENDING THE MODEL

The model can be extended, for possible extensions, please refer to 'Transport network creation of target-oriented particle-based models of Physarum Polycephalum'. 


## CREDITS AND REFERENCES

All references can be found in the references-section of 'Transport network creation of target-oriented particle-based models of Physarum Polycephalum' by F.S. Slijkhuis (2018). Please do not hesitate to contact the author for further information, on the following email-adress: filip8250@gmail.com
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Generic1Prima1ZonderTargets" repetitions="1" runMetricsEveryStep="true">
    <setup>reset-location
remove-pheromone
unbless-and-reset</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Co-location">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turn-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scenario-name">
      <value value="&quot;Generic1Prima1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Size-of-world">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-contrast">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="X">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Step-size">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-deposit-ratio">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TargetFactor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Y">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coverage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ManualMax">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Size-of-food-patches">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Color-of-barricade">
      <value value="&quot;blue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-evaporation-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Amount-X">
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Enable-targets">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Antenna-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Brush-intensity">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-diffusion-rate">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Image-name">
      <value value="&quot;nederland25.png&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Starting-position">
      <value value="&quot;On center&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Foodpatchamount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-intensity-foodpatches">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Brush-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Antenna-length">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <go>go</go>
    <timeLimit steps="10000"/>
    <enumeratedValueSet variable="Co-location">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turn-angle">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Scenario-name">
      <value value="&quot;Nederland2510k&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Size-of-world">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-contrast">
      <value value="381"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="X">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Step-size">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-deposit-ratio">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TargetFactor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Coverage">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Y">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ManualMax">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Size-of-food-patches">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Color-of-barricade">
      <value value="&quot;black&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-evaporation-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Amount-X">
      <value value="1800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Enable-targets">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Antenna-angle">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Brush-intensity">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-diffusion-rate">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Starting-position">
      <value value="&quot;On food-patches&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Image-name">
      <value value="&quot;nederland25.png&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Foodpatchamount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pheromone-intensity-foodpatches">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Brush-size">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Antenna-length">
      <value value="10"/>
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
0
@#$#@#$#@
