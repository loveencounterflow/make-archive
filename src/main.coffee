


############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
njs_os                    = require 'os'
njs_spawn                 = ( require 'child_process' ).spawn
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'make-archive'
log                       = TRM.get_logger 'plain',   badge
info                      = TRM.get_logger 'info',    badge
alert                     = TRM.get_logger 'alert',   badge
debug                     = TRM.get_logger 'debug',   badge
warn                      = TRM.get_logger 'warn',    badge
urge                      = TRM.get_logger 'urge',    badge
whisper                   = TRM.get_logger 'whisper', badge
help                      = TRM.get_logger 'help',    badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
ruler                     = ( new Array 108 ).join '─'
fat_ruler                 = ( new Array 108 ).join '━'
ASYNC                     = require 'async'
FS                        = require './FS'
#...........................................................................................................
host_name                 = njs_os.hostname()
host_name                 = host_name.replace '.fritz.box', ''
project_locators          = process.argv[ 2 ... ]
#...........................................................................................................
options                   = require '../options'


#-----------------------------------------------------------------------------------------------------------
@main = ->
  throw new Error "must give at least one project locator" if project_locators.length is 0
  #.........................................................................................................
  [ primary_output_home
    secondary_output_homes... ] = options[ 'output-homes' ]
  @validate_route_is_folder primary_output_home
  #.........................................................................................................
  for project_locator in project_locators
    project_locator = project_locator.replace /\/+$/, ''
    @validate_route_is_folder project_locator
    #.......................................................................................................
    project_name       = njs_path.basename project_locator
    project_home       = njs_path.dirname  project_locator
    #   project_name        = o.argv._[ 1 ] ? source_name
    #.......................................................................................................
    @validate_name project_name
    #.......................................................................................................
    timestamp           = FS.get_timestamp_of_newest_object_in_folder project_locator
    archive_name        = "(#{host_name})_#{project_name}_#{timestamp}.dmg"
    archive_home        = njs_path.join primary_output_home, project_name
    archive_locator     = njs_path.join archive_home, archive_name
    @validate_route_is_folder archive_home
    archive_exists      = FS.exists archive_locator
    #.......................................................................................................
    echo()
    whisper fat_ruler
    info 'COFFEENODE Backup Utility'
    whisper ruler
    help 'project-name:         ', project_name
    help 'project-locator:      ', project_locator
    help 'archive-locator:      ', archive_locator
    help 'archive-exists:       ', TRM.truth archive_exists
    #.......................................................................................................
    commands_and_arguments  = []
    tasks                   = []
    unless archive_exists
      commands_and_arguments.push @get_archiving_command_and_arguments project_locator, archive_locator
    #.......................................................................................................
    for command_and_arguments in commands_and_arguments
      do ( command_and_arguments ) =>
        tasks.push ( handler ) =>
          @spawn command_and_arguments..., handler
    #.......................................................................................................
    ASYNC.series tasks, ( error, results ) ->
      throw error if error?
      whisper fat_ruler
      echo 'All tasks have finished.'


#===========================================================================================================
# VALIDATORS
#-----------------------------------------------------------------------------------------------------------
@validate_route = ( route ) ->
  throw new Error "expected a text as route" unless ( Object::toString.call route ) is '[object String]'
  throw new Error "expected a non-empty text as route" if route.length is 0
  throw new Error "illegal route: #{rpr route}" unless ( route.match /[\s:"'\\<>|]/ ) is null

#-----------------------------------------------------------------------------------------------------------
@validate_name = ( name ) ->
  throw new Error "expected a text as name" unless ( Object::toString.call name ) is '[object String]'
  throw new Error "expected a non-empty text as name" if name.length is 0
  throw new Error "illegal name: #{rpr name}" unless ( name.match /[\s:"'\\<>|\/]/ ) is null

#-----------------------------------------------------------------------------------------------------------
@validate_route_is_folder = ( route ) ->
  @validate_route route
  throw new Error "route #{rpr route} must point to existing folder" unless FS.is_folder route

#-----------------------------------------------------------------------------------------------------------
@validate_route_doesnt_exist = ( route ) ->
  @validate_route route
  throw new Error "route #{rpr route} already exists" if FS.exists route

#-----------------------------------------------------------------------------------------------------------
@validate_archive_format = ( format ) ->
  throw new Error "expected a text as format" unless ( Object::toString.call format ) is '[object String]'
  switch format
    when 'UDRW', 'UDRO', 'UDCO', 'UDZO', 'UDBZ', 'UFBI', 'UDTO', 'UDxx', 'UDSP', 'UDSB' then null
    else
      throw new Error "unknown format #{rpr format}"

# #===========================================================================================================
# # BASH
# #-----------------------------------------------------------------------------------------------------------
# BASH = {}

# #-----------------------------------------------------------------------------------------------------------
# BASH.escape = ( route ) ->
#   return route.replace /([^-a-zA-Z0-9\/_.])/g, '\\$1'


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@get_archiving_command_and_arguments = ( project_locator, archive_locator ) ->
  ### thx to http://qntm.org/bash
  ###
  volume_name     = ( njs_path.basename archive_locator ).replace /\..*$/, ''
  archive_format  = options[ 'archive-format']
  @validate_archive_format archive_format
  # volume_name     = BASH.escape volume_name
  # project_locator = BASH.escape project_locator
  # archive_locator = BASH.escape archive_locator
  # return [ "/usr/bin/env", ['hdiutil', 'help', ] ]
  # return "hdiutil create -format UDZO -srcfolder #{project_locator} -volname #{volume_name} #{archive_locator}"
  command         = 'hdiutil'
  arguments_      = [
    'create'
    '-format'
    archive_format
    '-srcfolder'
    project_locator
    '-volname'
    volume_name
    archive_locator ]
  return [ command, arguments_, ]

#-----------------------------------------------------------------------------------------------------------
@spawn = ( command, arguments_, handler ) ->
  whisper fat_ruler
  whisper command + ' ' + arguments_.join ' '
  R = njs_spawn command, arguments_
  #.........................................................................................................
  R.on 'error', ( error ) =>
    handler error
  #.........................................................................................................
  R.stderr.on 'data', ( error ) =>
    handler error
  #.........................................................................................................
  R.stdout.on 'data', ( data_buffer ) =>
    echo ( data_buffer.toString 'utf-8' ).trim()
  #.........................................................................................................
  R.on 'close', ( code ) =>
    echo 'OK'
    handler null, null
  #.........................................................................................................
  return R

###
#===========================================================================================================



 .d8888b.  888      8888888
d88P  Y88b 888        888
888    888 888        888
888        888        888
888        888        888
888    888 888        888
Y88b  d88P 888        888
 "Y8888P"  88888888 8888888



#===========================================================================================================
###


#-----------------------------------------------------------------------------------------------------------
@cli = ->
  docopt    = ( require 'coffeenode-docopt' ).docopt
  version   = ( require '../package.json' )[ 'version' ]
  filename  = ( require 'path' ).basename __filename
         # #{filename} pos [--sample] [<prefix>]
# build DB;
# erase with `fresh`;
# include all codepoints with `all`
  usage     = """
  Usage: #{filename} <project-locators>...

  Options:
    -h, --help
    -v, --version
  """
  #.........................................................................................................
  cli_options = docopt usage, version: version, help: ( left, collected ) ->
    # urge left
    # help collected
    help '\n' + usage
  #.........................................................................................................
  debug cli_options
  settings = {}
  settings[ 'project-locators' ] = cli_options[ '<project-locators>' ]
  @main()

#-----------------------------------------------------------------------------------------------------------
@cli() unless module.parent?



