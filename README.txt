RANDOMINATOR is a random sentence generator.

- give him an input data and a template, and he will produce a random outcome based on the two given things

Tips:
 - if -d flag is not used, the randominator will use "data.json" file, which should be in the same directory
 - if you don't want to tipe the same template each time you want a random idea you can put it into "templates" part of your database
 - if no template is given as an argument it will try to search and get a random template (if there are multiple) from the database
 - if you specifiy template as an argument, surround them with "#" simbols ("#<template_string>#")
 - names of non data layers should be named without spaces in their names, as this would make it really hard for cli argument templates to be parsed
 - each layer of data should have a "data" attribute, which specifies if the layer is "data", or if the layer is "label"
   |-> this should always be the first attribute in the data layer (because the random selector chooses between 1 .. end attributes in that layer, 1, because it jumps over "data" attribute)
   |-> "data": false ... layer is a label layer
   |-> "data": true  ... layer is a data layer
 - by allowing the user to precisely label data, it gives much more control over how random the outcome they want to get
   |-> but this does not hinder the overall randomness, as you can still specify the topmost data layer, and the random generator will take care of the random selection

Flags:
  -h                    ... prints instructions to the cmd (same as this flags instructions)
  -desc                 ... describes the given (if -d flag is used) database (a hierarchy of which data layers are available - NOT DATA)
  -n:<num_of_outputs>   ... produces <num_of_outputs> random sentences
  -o:<output_dir>       ... the generated sentence/s is/are writen into <output_dir> file
  -d:<name_of_database> ... use the <name_of_database> directory for its data
  -t:<template_name>    ... use this template from the database

Example:
  IMPORTANT: compile the script with: "nim c randominator.nim"

  1. .\randominator -o:output.txt
  |- generates a random idea using a random template (if there are any) and outputs the idea to |-"output.txt" file (it creates the file if there is none)

  2. .\randominator #A <!genre> where you <!action> <?special> <!object> <?hook># -d:game.json
  |- generates a random idea, where 

Bad use of data layers ("data.json" file):
 - here, many random outcomes will make no sense, as some actions/adjectives are not meant to be used with non human entities
 - and because of badly divided data set, we have no control over this
 - "<!entity> always <!action> with <?adjective> <!entity>" can generate:
    |-> bad generations
        |-> Jon always mocks smelly moon
        |-> Wolfs always sleeps with pumpkins
        |-> Plants always breeds with moon (plants, breeds? really?)
    |-> good generations
        |-> Bob always hunts huge wolfs
        |-> Jon always sleeps with plants
{
  "data": false
  "entity": {
    "data": true
    "points": ["Jon", "Bob", "wolfs", "plants", "seeds", "pumpkins", "moon"]
  },
  "adjective": {
    "data": true
    "points": ["huge", "tiny", "smelly", "dumb", "fast growing"]
  },
  "action": {
    "data": true
    "points": ["sleeps", "breeds", "hunts", "mocks"]
  }
}

Good use of data layers: 
 - lets now divide our previous data into more specific groups, to have more control over sane outcomes
 - now we can imagine some scenarion which we want to make it random
  |-> for example we want an animal which does something to a non living thing. This was not possible beforehand, as the data was all mixed up
 - "<!entity:animal> is hungry and wants to <!action:live_being> a <?adjective:universal> <!entity:plant>
    |-> this is very specific randomness!!!
    |-> if you want less specific, as before, you can still go that way
 - "<!entity> is hungry and wants to <!action> a <?adjective> <!entity>
{
  "data": false,
  "entity": {
    "data": false
    "human": {
      "data": true
      "points": ["Jon", "Bob"]
    },
    "astral object" : {
      "data": true
      "points": ["moon"]
    },
    "animal": {
      "data" true
      "points: ["woolfs"]
    },
    "plant": {
      "data": true
      "points": ["plants", "seeds", "pumpkins"]
    }
  },
  "adjective": {
    "data": false,
    "universal": {
      "data": true,
      "points": ["huge", "tiny"]
    }
    "human": {
      "data": true,
      "points": ["dumb"]
    },
    "animal": {
      "data": true,
      "points": ["smelly"]
    },
    "plant": {
      "data": true,
      "points": ["fast growing"]
    }
  },
  "action": {
    data: false,
    "live_being": {
      data: true,
      "points": ["sleeps", "breeds", "hunts", "mocks"],
    },
    "other": {
      data: true,
      "points": ["grows", "shrinks"]
    }
  }
}





Template instructions:
  - use "<" and ">" to specify which random data point should be placed there
  - if you have nested data points (if you have "game" and "music" sets, which contains further nested data) use ":" divider
  - there must always be a "!" or "?" simbol in front of the data point name, which specifies whether the data point should always be present ("!" - always generate) or if there is a chance that it will not be in the final outcome ("?" - maybe generate)
  - "/" symbol specifies if there are multiple choices for the given data set

  - examples of template are:
    |-> we have all the game data in a game.json file, we have objects in "object" section ("label" data layer), which further contains division into "animals" and "people" ("people are further divided into "bad" and "good") and "physical object" which contains all sorts of further label data layers.
    |-> we also have a "adjective" and "action" data layer (very shallow data, not organised), which contains our data
    
    <!object:people> is a <adjective> looking human, who likes to <action> for fun
    |- this will generate a random string, but because the people data has further nested datapoints it will randomly choose one of them ("good" or "bad" it will choose one of the nested points until it gets to the data)