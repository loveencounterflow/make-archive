


############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
MKDIRP                    = require 'mkdirp'


#===========================================================================================================
# FILE SYSTEM
#-----------------------------------------------------------------------------------------------------------
### TAINT belongs to ROUTE ###
@resolve_route = ( route ) ->
  return njs_path.resolve process.cwd(), route

#-----------------------------------------------------------------------------------------------------------
@mkdirp = ( route, handler = null ) ->
  ### TAINT should support MKDIRP options ###
  return MKDIRP.sync route, handler if handler?
  MKDIRP route, handler

#-----------------------------------------------------------------------------------------------------------
@names_in_folder = ( route, handler ) ->
  return njs_fs.readdirSync route unless handler?
  njs_fs.readdir route, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@locators_in_folder = ( route, handler ) ->
  return ( njs_path.join route, name for name in @names_in_folder route ) unless handler?
  @names_in_folder route, ( error, names ) ->
    handler error, null if error?
    handler null, ( njs_path.join route, name for name in names )

#-----------------------------------------------------------------------------------------------------------
@all_locators_in_folder = ( route, handler ) ->
  ### NOTE: this version does NOT follow symlinks!
  ###
  unless handler?
    R = []
    for locator in @locators_in_folder route
      R.push locator
      if ( njs_fs.lstatSync locator ).isDirectory()
        R.splice R.length, 0, ( @all_locators_in_folder locator )...
    return R
  throw new Error 'asynchronous FS/all-locators-in-folder not implemented'

#-----------------------------------------------------------------------------------------------------------
@get_date_of_newest_object_in_folder = ( route, handler ) ->
  ### NOTE: this version does NOT follow symlinks!
  ###
  unless handler?
    locators = @all_locators_in_folder route
    throw new Error "no entries in folder #{route}" if locators.length == 0
    R = 0
    for locator in locators
      R = Math.max ( njs_fs.lstatSync locator ).mtime * 1, R
    return new Date R
  throw new Error 'asynchronous FS/get-date-of-newest-object-in-folder not implemented'

#-----------------------------------------------------------------------------------------------------------
@get_timestamp_of_newest_object_in_folder = ( route, handler ) ->
  unless handler?
    R = ( @get_date_of_newest_object_in_folder route ).toISOString()
    R = R.replace 'T', '-'
    R = R.replace /:/g, '-'
    R = R.replace /\..*$/g, ''
    return R
  throw new Error 'asynchronous FS/get-iso-timestamp-of-newest-object-in-folder not implemented'

#-----------------------------------------------------------------------------------------------------------
@_safe_get_fs_stat = ( route, follow_links = yes ) ->
  try
    return if follow_links then njs_fs.statSync route else njs_fs.lstatSync route
  catch error
    throw error unless ( error[ 'message' ].indexOf 'ENOENT, no such file or directory ' ) == 0
    return null

#-----------------------------------------------------------------------------------------------------------
@exists = ( route ) ->
  return ( @_safe_get_fs_stat route )?

#-----------------------------------------------------------------------------------------------------------
@is_folder = ( route ) ->
  stat = @_safe_get_fs_stat route
  return false if stat is null
  return stat.isDirectory()
