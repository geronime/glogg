# GLogg - Another custom logging gem

+ [github project] (https://github.com/geronime/glogg)

GLogg is another custom logging gem with multiple debug log levels.

## Usage

### Levels

List of available log levels:

    GLogg::L_NIL = -1 # no logging at all
    GLogg::L_FAT =  0 # fatal
    GLogg::L_ERR =  1 # error
    GLogg::L_WRN =  2 # warning
    GLogg::L_INF =  3 # info
    GLogg::L_DBG =  4 # debug level 1
    GLogg::L_D2  =  5 # debug level 2
    GLogg::L_D3  =  6 # debug level 3
    GLogg::L_D4  =  7 # debug level 4

### Configuration

Without setup `GLogg` prints messages to `STDERR` with up to `GLogg::L_DBG`
verbosity.

To query/set different settings you can use:

    current_level = GLogg.log_level
    current_destination = GLogg.log_path
    GLogg.log_level = level
    GLogg.log_path = destination
    GLogg.ini destination, level

* `destination` may be one of `$stdout`, `$stderr`, `nil`, log file path
  (`nil` is the default `$stderr`)
* `level` is one of previously listed log level

### Logging

GLogg provides following methods:

* `GLogg.log_f?` to discover whether messages with `GLogg::L_FAT` verbosity
get logged
  * continuing with `log_e?`,..., `log_d?`, `log_d2?`,...
* `GLogg.log_f(msg)` to log message with `GLogg::L_FAT` verbosity
  (unless configured log level is `GLogg::L_NIL`)
  * simmilarly methods `log_e`,...
* shortcut methods where the message is passed in block which is executed
  only if the message is to be logged in the end: `GLogg.l_f{msg}`, etc.

#### Examples

These two examples have the same behaviour:

    GLogg.log_f? && GLogg.log_f("Fatal error!")

    GLogg.l_f { "Fatal error!" }

The output would look like:

    $ irb -r bundler/setup -r glogg
    irb(main):001:0> GLogg.l_f { "Fatal error!" }
    2012-08-12 12:24:52.618418 (CEST) - [30113] - [irb] - [FATAL]:
      Fatal error!

    => true

* in the log header the values in square brackets are PID, process name
  and message verbosity
* the message follows and is always terminated by an empty line

### Under the hood

The appropriate anonymous logging method is selected during destination setup:

* for `$stdout` or `$stderr` the message gets printed using `IO.write`,
  and logging method always returns `true`
* for file logging the method is more elaborate:
  * log message is assembled first
    (to spend as little time with the file handle locked as possible)
  * the file is opened in append mode
  * handle is locked using `handle.flock File::LOCK_EX` waiting
    for the exclusive access
  * message gets logged using `handle.write`
  * handle is unlocked and closed
  * in case of `SystemCallError` the warning is issued and `false` returned
  * otherwise `true` is returned

In the logging process the proper logging method is always executed only after
the message relevance was compared with the configured logging verbosity
and it is decided the message is to be logged at all.

## Changelog

+ __0.0.2__: shortcut methods with message in block, docs written
+ __0.0.1__: first revision

## License

GLogg is copyright (c)2011 Jiri Nemecek, and released under the terms
of the MIT license. See the LICENSE file for the gory details.

