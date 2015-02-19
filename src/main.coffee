


############################################################################################################
njs_path                  = require 'path'
njs_os                    = require 'os'
njs_spawn                 = ( require 'child_process' ).spawn
#...........................................................................................................
### TAINT temporary solution; should unify the two ###
njs_fs                    = require 'fs-extra'
FS                        = require './FS'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'make-archive'
log                       = CND.get_logger 'plain',   badge
info                      = CND.get_logger 'info',    badge
alert                     = CND.get_logger 'alert',   badge
debug                     = CND.get_logger 'debug',   badge
warn                      = CND.get_logger 'warn',    badge
urge                      = CND.get_logger 'urge',    badge
whisper                   = CND.get_logger 'whisper', badge
help                      = CND.get_logger 'help',    badge
echo                      = CND.echo.bind CND
#...........................................................................................................
ruler                     = ( new Array 108 ).join '─'
fat_ruler                 = ( new Array 108 ).join '━'
ASYNC                     = require 'async'
glob                      = require 'glob'
#...........................................................................................................
host_name                 = njs_os.hostname()
host_name                 = host_name.replace '.fritz.box', ''
project_locators          = process.argv[ 2 ... ]
#...........................................................................................................
options                   = require '../options'
dryrun                    = options[ 'dryrun' ] ? no

#-----------------------------------------------------------------------------------------------------------
@main = ->
  throw new Error "must give at least one project locator" if project_locators.length is 0
  #.........................................................................................................
  backup_homes                  = []
  primary_tasks                 = []
  [ primary_output_home
    secondary_output_homes... ] = options[ 'output-homes' ]
  @validate_route_is_folder primary_output_home
  #.........................................................................................................
  info()
  whisper fat_ruler
  info 'COFFEENODE Backup Utility'
  whisper ruler
  #.........................................................................................................
  for backup_home in secondary_output_homes
    backup_homes.push backup_home if is_folder = FS.is_folder backup_home
    help 'backup folder:        ', backup_home, CND.truth is_folder
  #.........................................................................................................
  for project_locator in project_locators
    project_locator     = ( FS.resolve_route project_locator ).replace /\/+$/, ''
    @validate_route_is_folder project_locator
    #.......................................................................................................
    project_name        = njs_path.basename project_locator
    project_home        = njs_path.dirname  project_locator
    #.......................................................................................................
    @validate_name project_name
    #.......................................................................................................
    timestamp           = FS.get_timestamp_of_newest_object_in_folder project_locator
    # archive_name        = "#{host_name}_#{project_name}_#{timestamp}.dmg"
    archive_name        = "#{project_name}_#{timestamp}.dmg"
    archive_home        = njs_path.join primary_output_home, project_name
    archive_locator     = njs_path.join archive_home, archive_name
    @ensure_route_is_folder archive_home
    archive_exists      = FS.exists archive_locator
    whisper ruler
    help 'project-name:         ', project_name
    help 'project-locator:      ', project_locator
    help 'archive-locator:      ', archive_locator
    help 'archive-exists:       ', CND.truth archive_exists
    #.......................................................................................................
    for backup_home in backup_homes
      backup_glob       = njs_path.join backup_home, "#{project_name}_*.dmg"
      help 'backup folder:        ', backup_home
      existing_backups  = glob.sync backup_glob
      surplus_count     = Math.max 0, existing_backups.length - options[ 'max-backup-count' ]
      surplus_count    += +1 unless archive_exists
      surplus_count     = Math.min surplus_count, existing_backups.length
      help "There are #{existing_backups.length} backups of this archive in #{backup_home}"
      if surplus_count > 0
        warn "#{surplus_count} of which will be removed"
        for idx in [ 0 ... surplus_count ]
          warn "removing #{existing_backups[ idx ]}"
          njs_fs.unlinkSync existing_backups[ idx ] unless dryrun
    #.......................................................................................................
    continue if archive_exists
    command_and_arguments   = @get_archiving_command_and_arguments project_locator, archive_locator
    #.......................................................................................................
    do ( project_locator, archive_name, archive_locator, command_and_arguments ) =>
      primary_tasks.push ( primary_handler ) =>
        @spawn command_and_arguments..., ( error ) =>
          return primary_handler error if error?
          return primary_handler null if backup_homes.length is 0
          secondary_tasks = []
          for backup_home in backup_homes
            do ( backup_home ) =>
              secondary_tasks.push ( secondary_handler ) =>
                backup_locator = njs_path.join backup_home, archive_name
                @copy_with_rsync archive_locator, backup_locator, secondary_handler
                # njs_fs.copy archive_locator, backup_locator, ( error ) =>
                #   help "copied #{archive_locator} to #{backup_home}" unless error?
                #   secondary_handler error
          ASYNC.parallelLimit secondary_tasks, 5, ( error ) =>
            return primary_handler error
  #.........................................................................................................
  ASYNC.series primary_tasks, ( error, results ) ->
    throw error if error?
    whisper fat_ruler
    help 'All tasks have finished.'

#===========================================================================================================
# VALIDATORS
#-----------------------------------------------------------------------------------------------------------
@validate_route = ( route ) ->
  throw new Error "expected a text as route" unless ( Object::toString.call route ) is '[object String]'
  throw new Error "expected a non-empty text as route" if route.length is 0
  throw new Error "illegal route: #{rpr route}" unless ( route.match /[\s:"'\\<>|]/ ) is null
  return null

#-----------------------------------------------------------------------------------------------------------
@validate_name = ( name ) ->
  throw new Error "expected a text as name" unless ( Object::toString.call name ) is '[object String]'
  throw new Error "expected a non-empty text as name" if name.length is 0
  throw new Error "illegal name: #{rpr name}" unless ( name.match /[\s:"'\\<>|\/]/ ) is null
  return null

#-----------------------------------------------------------------------------------------------------------
@validate_route_is_folder = ( route ) ->
  @validate_route route
  unless FS.is_folder route
    @complain "route #{rpr route} must point to existing folder" unless options[ 'create-folder' ] ? true
  return null

#-----------------------------------------------------------------------------------------------------------
@ensure_route_is_folder = ( route ) ->
  @validate_route route
  unless FS.is_folder route
    @complain "route #{rpr route} must point to existing folder" unless options[ 'create-folder' ] ? true
    @complain "route #{rpr route} points to existing file" if FS.exists route
    FS.mkdirp route
    help "created folder at #{route}"
  return null

#-----------------------------------------------------------------------------------------------------------
@validate_route_doesnt_exist = ( route ) ->
  @validate_route route
  throw new Error "route #{rpr route} already exists" if FS.exists route
  return null

#-----------------------------------------------------------------------------------------------------------
@validate_archive_format = ( format ) ->
  throw new Error "expected a text as format" unless ( Object::toString.call format ) is '[object String]'
  switch format
    when 'UDRW', 'UDRO', 'UDCO', 'UDZO', 'UDBZ', 'UFBI', 'UDTO', 'UDxx', 'UDSP', 'UDSB' then null
    else
      throw new Error "unknown format #{rpr format}"
  return null

#-----------------------------------------------------------------------------------------------------------
@complain = ( message ) ->
  warn message
  process.exit()

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
@copy_with_rsync = ( archive_locator, backup_locator, handler ) ->
  help "using rsync to copy"
  help "  from #{archive_locator}"
  help "  to   #{backup_locator}"
  @spawn ( @get_copy_command_and_arguments archive_locator, backup_locator )..., ( error ) =>
    return handler error if error?
    help 'ok'
    handler null

#-----------------------------------------------------------------------------------------------------------
@get_copy_command_and_arguments = ( archive_locator, backup_locator ) ->
  command     = 'rsync'
  arguments_  = [
    '-av'
    '--progress'
    archive_locator
    backup_locator
    ]
  return [ command, arguments_, ]


#-----------------------------------------------------------------------------------------------------------
if dryrun
  warn "dryrun"
  #---------------------------------------------------------------------------------------------------------
  @spawn = ( command, arguments_, handler ) ->
    whisper fat_ruler
    whisper command + ' ' + arguments_.join ' '
    handler null, null
    #.........................................................................................................
    return null
else
  #---------------------------------------------------------------------------------------------------------
  @spawn = ( command, arguments_, handler ) ->
    whisper fat_ruler
    whisper command + ' ' + arguments_.join ' '
    R = njs_spawn command, arguments_, { stdio: 'inherit', }
    # #.........................................................................................................
    # R.on 'error', ( error ) =>
    #   handler error
    # #.........................................................................................................
    # R.stderr.on 'data', ( error ) =>
    #   handler error
    # #.........................................................................................................
    # R.stdout.on 'data', ( data_buffer ) =>
    #   ### TAINT strictly speaking, this could cause encoding errors: ###
    #   text = ( data_buffer.toString 'utf-8' ).trim()
    #   help text if text.length > 0
    #.......................................................................................................
    R.on 'close', ( code ) =>
      # echo 'OK'
      handler null, null
    #.......................................................................................................
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
  # debug cli_options
  settings = {}
  settings[ 'project-locators' ] = cli_options[ '<project-locators>' ]
  @main()

#-----------------------------------------------------------------------------------------------------------
@cli() unless module.parent?



