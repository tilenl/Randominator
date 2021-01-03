
import json, os, random, strutils, tables, sequtils, sugar

const DEFAULT_TEMPLATE_DIR = "templates.json"
const DEFAULT_DATA_DIR = "data.json"
const HELP_STRING = """-h                    ... prints instructions to the cmd
-desc                 ... describes the given (if -d flag is used) database (a hierarchy of which data layers are available - NOT DATA)
-n:<num_of_outputs>   ... produces <num_of_outputs> random sentences
-o:<output_dir>       ... the generated sentence/s is/are writen into <output_dir> file
-d:<name_of_database> ... use the <name_of_database> directory for its data
-t:<template_name>    ... use this template from the database"""

# debug template for debuging flags in the main procedure
template debug(x: bool | int | string) = echo(x.astToStr() & " = " & $x)


# a hidden function, for convenience of use with desc
# it creates a string, representing the json file, starting at the j_node node, and indenting for indentation, and shifting each deeper layer (down) to the right for shift spaces
# global settings for this function
let indent_string: string = " "
proc desc(j_node: JsonNode, indentation, shift: int): string =
  for attrib in j_node.getFields.keys:
    # if attrib is meta, we don't parse it
    if not ["points", "data"].contains(attrib):
      result.add(indent(attrib, indentation, indent_string))
      result.add("\n")
      result.add(desc(j_node[attrib], indentation + shift, shift))

# creates a hierarhical representation of all posible options to use in templates
proc desc(json_file: string): string = 
  let json = parseFile(json_file)
  # we start at the root node, with 0 indentation and we shift each level for 2 spacebars
  return desc(json, 0, 2)


proc readInt(numStr: string): int =
  try: result = parseInt(numStr)
  except ValueError: 
    echo numStr & " is not a number. Exiting ..."
    quit(1)


# chooses a random attribute (does not include "data") from json_node
#TODO look into getting a better (prealocate the right amount of storage)
proc pickRandomAttrib(j_node: JsonNode): string =
  # because sample only works on openArray, we need to transform OrderedTable to array
  var keys = newSeq[string]()

  for key in j_node.getFields.keys:
    if key != "data":
      keys.add(key)
  
  return sample(keys)


# picks a random data point from root JsonNode, downwards
# if the given j_node is not at the bottom level (data = false), it picks a random attribute, and goes searching for data in him
 # recursively picks a path to data points and picks a random from the
proc pickRandomFrom(j_node: JsonNode): string =
  # we stop at the data level, from where we return a random data point
  if j_node["data"].getBool:
    # getElems returns a seq[JsonNode], but we must return a string, so we convert it to a string
    return sample(j_node["points"].getElems).getStr

  # if we are not at the data level, we choose a random node nad go into it
  return pickRandomFrom(j_node[pickRandomAttrib(j_node)])

# Return JsonNode, that is nested in j_node by sequentially using parts to go down the Json tree
proc subJson(j_node: JsonNode, parts: seq[string]): JsonNode =
  result = j_node
  # iteratively go down the JsonTree
  for part in parts:
    try:
      result = result[part]
    except KeyError:
      echo part & " is not an attribute in json! Exiting..."
      quit(1)

  return result

# produces a randomly generated string from template from json file
#! json should be the root json node from file (aka parseFile(<file_name>))
proc genRandom(temp: string, json: JsonNode): string = 
  # we seperate the parts of the word, that must be generated and clear all white spaces
  # we leave ! and ? in the word, to use it afterwards, when choosing a random word
  let sentence = temp.split({'<', '>'}).filter(x => not x.isEmptyOrWhitespace())
    .map(proc (x: string): string =
      if x.startsWith('!'):
        var sub_parts = x.split('.')
        # we remove the ! sign
        sub_parts[0] = substr(sub_parts[0], 1)
        return pickRandomFrom(subJson(json, sub_parts))
      elif x.startsWith('?'):
      # 50:50 that we get include a maybe data point
        if sample([true, false]):
          var sub_parts = x.split('.')
          # we remove the ! sign
          sub_parts[0] = substr(sub_parts[0], 1)
          return pickRandomFrom(subJson(json, sub_parts))
        else:
          return ""
      else: return x)

  return sentence.join


proc main() =
  # init the random generator from random module
  randomize()
  # all possible flags that the user can specify
  var
    flag_help = false
    flag_desc = false
    flag_use_default = true
    flag_redir_to_output = false
    flag_use_arg_template = false
    num_of_generations = 1
    data_file = DEFAULT_DATA_DIR
    # not initialized!
    output_file: string
    arg_template: string = ""

  # we parse import and get all the possible flags
  var parsed_arg: seq[string]
  for arg in commandLineParams():
    parsed_arg = arg.split(":")
    case parsed_arg[0]:
      of "-d": 
        flag_use_default = false
        data_file = parsed_arg[1]
      of "-h": flag_help = true
      of "-o": 
        flag_redir_to_output = true
        output_file = parsed_arg[1]
      of "-n": num_of_generations = readint(parsed_arg[1])
      of "-desc": flag_desc = true
      of "-t": 
        flag_use_arg_template = true
        # we open "templates.json" file, which contains the given templates
        arg_template = try: parseFile(DEFAULT_TEMPLATE_DIR)[parsed_arg[1]].getStr
                       except KeyError:
                         echo parsed_arg[1] & " is not a valid template. Available templates are: \n" & desc(DEFAULT_TEMPLATE_DIR) & "Exiting ..."
                         quit(1)
      else: arg_template = parsed_arg[0]
        

  # DEBUG
  #flag_help.debug()
  #flag_desc.debug()
  #flag_use_default.debug()
  #flag_redir_to_output.debug()
  #flag_use_arg_template.debug()
  #num_of_generations.debug()
  #data_file.debug()
  #output_file.debug()
  #arg_template.debug()

  # we put everything in this string, so that in the end, we can just print this text to output file or to the console
  var data = ""
  if flag_help: data = HELP_STRING
  elif flag_desc: data = desc(data_file)
  else:
    if arg_template == "":
      echo "No template given. Exiting ..."
      quit(1)
    let json_file = try: parseFile(data_file)
                    except IOError:
                      echo data_file & " is not in the same directory as the program! Exiting..."
                      quit(1)
    for i in 0..(num_of_generations-1):
      data &= genRandom(arg_template, json_file) & "\n"
    


  # we output the generated data to a file or to the console
  if flag_redir_to_output:
    let file = open(output_file, fmWrite)
    write(file, data)
    close(file)
  else: echo data


# call the main function
main()