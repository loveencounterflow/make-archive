// Generated by CoffeeScript 1.8.0
(function() {
  var ASYNC, FS, TRM, alert, badge, debug, echo, fat_ruler, help, host_name, info, log, njs_fs, njs_os, njs_path, njs_spawn, options, project_locators, rpr, ruler, urge, warn, whisper,
    __slice = [].slice;

  njs_path = require('path');

  njs_fs = require('fs');

  njs_os = require('os');

  njs_spawn = (require('child_process')).spawn;

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  badge = 'make-archive';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  alert = TRM.get_logger('alert', badge);

  debug = TRM.get_logger('debug', badge);

  warn = TRM.get_logger('warn', badge);

  urge = TRM.get_logger('urge', badge);

  whisper = TRM.get_logger('whisper', badge);

  help = TRM.get_logger('help', badge);

  echo = TRM.echo.bind(TRM);

  ruler = (new Array(108)).join('─');

  fat_ruler = (new Array(108)).join('━');

  ASYNC = require('async');

  FS = require('./FS');

  host_name = njs_os.hostname();

  host_name = host_name.replace('.fritz.box', '');

  project_locators = process.argv.slice(2);

  options = require('../options');

  this.main = function() {
    var archive_exists, archive_home, archive_locator, archive_name, command_and_arguments, commands_and_arguments, primary_output_home, project_home, project_locator, project_name, secondary_output_homes, tasks, timestamp, _fn, _i, _j, _len, _len1, _ref, _results;
    if (project_locators.length === 0) {
      throw new Error("must give at least one project locator");
    }
    _ref = options['output-homes'], primary_output_home = _ref[0], secondary_output_homes = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
    this.validate_route_is_folder(primary_output_home);
    _results = [];
    for (_i = 0, _len = project_locators.length; _i < _len; _i++) {
      project_locator = project_locators[_i];
      project_locator = project_locator.replace(/\/+$/, '');
      this.validate_route_is_folder(project_locator);
      project_name = njs_path.basename(project_locator);
      project_home = njs_path.dirname(project_locator);
      this.validate_name(project_name);
      timestamp = FS.get_timestamp_of_newest_object_in_folder(project_locator);
      archive_name = "(" + host_name + ")_" + project_name + "_" + timestamp + ".dmg";
      archive_home = njs_path.join(primary_output_home, project_name);
      archive_locator = njs_path.join(archive_home, archive_name);
      this.validate_route_is_folder(archive_home);
      archive_exists = FS.exists(archive_locator);
      echo();
      whisper(fat_ruler);
      info('COFFEENODE Backup Utility');
      whisper(ruler);
      help('project-name:         ', project_name);
      help('project-locator:      ', project_locator);
      help('archive-locator:      ', archive_locator);
      help('archive-exists:       ', TRM.truth(archive_exists));
      commands_and_arguments = [];
      tasks = [];
      if (!archive_exists) {
        commands_and_arguments.push(this.get_archiving_command_and_arguments(project_locator, archive_locator));
      }
      _fn = (function(_this) {
        return function(command_and_arguments) {
          return tasks.push(function(handler) {
            return _this.spawn.apply(_this, __slice.call(command_and_arguments).concat([handler]));
          });
        };
      })(this);
      for (_j = 0, _len1 = commands_and_arguments.length; _j < _len1; _j++) {
        command_and_arguments = commands_and_arguments[_j];
        _fn(command_and_arguments);
      }
      _results.push(ASYNC.series(tasks, function(error, results) {
        if (error != null) {
          throw error;
        }
        whisper(fat_ruler);
        return echo('All tasks have finished.');
      }));
    }
    return _results;
  };

  this.validate_route = function(route) {
    if ((Object.prototype.toString.call(route)) !== '[object String]') {
      throw new Error("expected a text as route");
    }
    if (route.length === 0) {
      throw new Error("expected a non-empty text as route");
    }
    if ((route.match(/[\s:"'\\<>|]/)) !== null) {
      throw new Error("illegal route: " + (rpr(route)));
    }
  };

  this.validate_name = function(name) {
    if ((Object.prototype.toString.call(name)) !== '[object String]') {
      throw new Error("expected a text as name");
    }
    if (name.length === 0) {
      throw new Error("expected a non-empty text as name");
    }
    if ((name.match(/[\s:"'\\<>|\/]/)) !== null) {
      throw new Error("illegal name: " + (rpr(name)));
    }
  };

  this.validate_route_is_folder = function(route) {
    this.validate_route(route);
    if (!FS.is_folder(route)) {
      throw new Error("route " + (rpr(route)) + " must point to existing folder");
    }
  };

  this.validate_route_doesnt_exist = function(route) {
    this.validate_route(route);
    if (FS.exists(route)) {
      throw new Error("route " + (rpr(route)) + " already exists");
    }
  };

  this.validate_archive_format = function(format) {
    if ((Object.prototype.toString.call(format)) !== '[object String]') {
      throw new Error("expected a text as format");
    }
    switch (format) {
      case 'UDRW':
      case 'UDRO':
      case 'UDCO':
      case 'UDZO':
      case 'UDBZ':
      case 'UFBI':
      case 'UDTO':
      case 'UDxx':
      case 'UDSP':
      case 'UDSB':
        return null;
      default:
        throw new Error("unknown format " + (rpr(format)));
    }
  };

  this.get_archiving_command_and_arguments = function(project_locator, archive_locator) {

    /* thx to http://qntm.org/bash
     */
    var archive_format, arguments_, command, volume_name;
    volume_name = (njs_path.basename(archive_locator)).replace(/\..*$/, '');
    archive_format = options['archive-format'];
    this.validate_archive_format(archive_format);
    command = 'hdiutil';
    arguments_ = ['create', '-format', archive_format, '-srcfolder', project_locator, '-volname', volume_name, archive_locator];
    return [command, arguments_];
  };

  this.spawn = function(command, arguments_, handler) {
    var R;
    whisper(fat_ruler);
    whisper(command + ' ' + arguments_.join(' '));
    R = njs_spawn(command, arguments_);
    R.on('error', (function(_this) {
      return function(error) {
        return handler(error);
      };
    })(this));
    R.stderr.on('data', (function(_this) {
      return function(error) {
        return handler(error);
      };
    })(this));
    R.stdout.on('data', (function(_this) {
      return function(data_buffer) {
        return echo((data_buffer.toString('utf-8')).trim());
      };
    })(this));
    R.on('close', (function(_this) {
      return function(code) {
        echo('OK');
        return handler(null, null);
      };
    })(this));
    return R;
  };


  /*
   *===========================================================================================================
  
  
  
   .d8888b.  888      8888888
  d88P  Y88b 888        888
  888    888 888        888
  888        888        888
  888        888        888
  888    888 888        888
  Y88b  d88P 888        888
   "Y8888P"  88888888 8888888
  
  
  
   *===========================================================================================================
   */

  this.cli = function() {
    var cli_options, docopt, filename, settings, usage, version;
    docopt = (require('coffeenode-docopt')).docopt;
    version = (require('../package.json'))['version'];
    filename = (require('path')).basename(__filename);
    usage = "Usage: " + filename + " <project-locators>...\n\nOptions:\n  -h, --help\n  -v, --version";
    cli_options = docopt(usage, {
      version: version,
      help: function(left, collected) {
        return help('\n' + usage);
      }
    });
    debug(cli_options);
    settings = {};
    settings['project-locators'] = cli_options['<project-locators>'];
    return this.main();
  };

  if (module.parent == null) {
    this.cli();
  }

}).call(this);