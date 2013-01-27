#encoding:utf-8

module GLogg

	# logging constants
	L = {
		(L_NIL = -1) => '', # disables logging
		(L_FAT = 0)  => 'FATAL',
		(L_ERR = 1)  => 'ERROR',
		(L_WRN = 2)  => 'WARNING',
		(L_INF = 3)  => 'INFO',
		(L_DBG = 4)  => 'DEBUG',
		(L_D2  = 5)  => 'DEBUG2',
		(L_D3  = 6)  => 'DEBUG3',
		(L_D4  = 7)  => 'DEBUG4',
	}

	# default log level
	DFLT_LOG_LVL  = L_DBG

	# initializing function, necessary only for redefinition of defaults
	# priorities for settings of the log level:
	#   1. function parameter level
	#   2. ENV['LOG_LVL'] (converted to Integer using to_i)
	#   3. $LOG_LVL
	#   4. DFLT_LOG_LVL
	# priorities for settings of the log target:
	#   1. defined function parameter path
	#   2. ENV['LOG_PATH'] (strings 'STDOUT' and 'STDERR' are accepted as well)
	#   3. $LOG_PATH
	#   4. $stderr
	# Specified log file is attempted to be opened in append mode (excepts IOs).
	# Logging into files itself goes in locking procedure.
	def self.ini path=nil, level=nil
		if level
			self.log_level = level
		elsif ENV['LOG_LVL']
			self.log_level = ENV['LOG_LVL'].to_i
		elsif defined? $LOG_LVL
			self.log_level = $LOG_LVL
		else
			@@LOG_LVL = DFLT_LOG_LVL
		end
		return if @@LOG_LVL == L_NIL
		unless path && (self.log_path = path)
			if ENV['LOG_PATH']
				return if ENV['LOG_PATH'] == 'STDOUT' and self.log_path = $stdout
				return if ENV['LOG_PATH'] == 'STDERR' and self.log_path = $stderr
				return if self.log_path = ENV['LOG_PATH']
			elsif defined?($LOG_PATH) and self.log_path = $LOG_PATH
				return # ok
			else
				self.log_path = $stderr # default
			end
		end
	end

	def self.log_path
		@@LOG_PATH
	end
	def self.log_level
		@@LOG_LVL
	end

	def self.log_level= level
		if level && L[level]
			@@LOG_LVL = level
		else
			throw "GLogg: Unknown log level #{level}!"
		end
	end

	# return true on successful set, false otherwise
	def self.log_path= log_path
		if log_path.nil? || log_path == $stderr
			@@LOG_PATH = $stderr
			@@log_func = @@log_msg_io_proc
		elsif log_path == $stdout
			@@LOG_PATH = $stdout
			@@log_func = @@log_msg_io_proc
		elsif self.check_logpath(log_path)
			@@LOG_PATH = log_path
			@@log_func = @@log_msg_file_proc
		else
			return false # failed to set logging to a file
		end
		true
	end

	def self.log_f?
		L_FAT <= @@LOG_LVL
	end
	def self.log_e?
		L_ERR <= @@LOG_LVL
	end
	def self.log_w?
		L_WRN <= @@LOG_LVL
	end
	def self.log_i?
		L_INF <= @@LOG_LVL
	end
	def self.log_d?
		L_DBG <= @@LOG_LVL
	end
	def self.log_d2?
		L_D2 <= @@LOG_LVL
	end
	def self.log_d3?
		L_D3 <= @@LOG_LVL
	end
	def self.log_d4?
		L_D4 <= @@LOG_LVL
	end

	def self.log_f m
		session_log L_FAT, m
		@@log_func.call L_FAT, m
	end
	def self.log_e m
		session_log L_ERR, m
		@@log_func.call L_ERR, m
	end
	def self.log_w m
		session_log L_WRN, m
		@@log_func.call L_WRN, m
	end
	def self.log_i m
		session_log L_INF, m
		@@log_func.call L_INF, m
	end
	def self.log_d m
		session_log L_DBG, m
		@@log_func.call L_DBG, m
	end
	def self.log_d2 m
		session_log L_D2, m
		@@log_func.call L_D2, m
	end
	def self.log_d3 m
		session_log L_D3, m
		@@log_func.call L_D3, m
	end
	def self.log_d4 m
		session_log L_D4, m
		@@log_func.call L_D4, m
	end

	def self.l_f &m
		session_log L_FAT, m
		log_f? and msg = yield and @@log_func.call L_FAT, msg
	end
	def self.l_e &m
		session_log L_ERR, m
		log_e? and msg = yield and @@log_func.call L_ERR, msg
	end
	def self.l_w &m
		session_log L_WRN, m
		log_w? and msg = yield and @@log_func.call L_WRN, msg
	end
	def self.l_i &m
		session_log L_INF, m
		log_i? and msg = yield and @@log_func.call L_INF, msg
	end
	def self.l_d &m
		session_log L_DBG, m
		log_d? and msg = yield and @@log_func.call L_DBG, msg
	end
	def self.l_d2 &m
		session_log L_D2, m
		log_d2? and msg = yield and @@log_func.call L_D2, msg
	end
	def self.l_d3 &m
		session_log L_D3, m
		log_d3? and msg = yield and @@log_func.call L_D3, msg
	end
	def self.l_d4 &m
		session_log L_D4, m
		log_d4? and msg = yield and @@log_func.call L_D4, msg
	end

	def self.start_session
		Thread.current['glogg_session'] = []
	end

	def self.close_session evaluate = false, level = nil
		buffer = Thread.current['glogg_session']
		Thread.current['glogg_session'] = nil

		if evaluate and buffer
			level = @@LOG_LVL if level.nil?
			buffer.delete_if {|lvl, m| lvl > level }.map do |lvl, m|
				m.is_a?(Proc) ? m.call.to_s : m.to_s
			end
		end
	end

	private

	def self.session_log lvl, m
		if Thread.current['glogg_session']
			Thread.current['glogg_session'] << [lvl, m]
		end
	end

	# function for logging into file in locking mode
	# return false in case of error (during fileopen, true otherwise
	@@log_msg_file_proc = proc do |level, message|
		if level <= @@LOG_LVL
			msg = assemble_message level, message
			begin
				fh = File.open @@LOG_PATH, 'a'
				fh.flock File::LOCK_EX
				fh.seek 0, IO::SEEK_END ### ===
				fh.write msg
				fh.flock File::LOCK_UN
				fh.close
				true
			rescue SystemCallError => e
				warn "Logging failed: #{e} !"
				false
			end
		end
		true
	end

	# function for logging into IO stream ($stdout or $stdin typically)
	# return true always
	@@log_msg_io_proc = proc do |level, message|
		if level <= @@LOG_LVL
			msg = assemble_message(level, message)
			@@LOG_PATH.write msg
		end
		true
	end

	def self.assemble_message level, message
		sprintf "%s - [%u] - [%s] - [%s]:\n  %s\n\n",
			self.hr_time(Time.now), $$, $0, L[level], message
	end

	def self.hr_time tm=Time.now
		return sprintf '%4u-%02u-%02u %02u:%02u:%02u.%06u (%s)',
			tm.year, tm.month, tm.day, tm.hour, tm.min, tm.sec, tm.usec, tm.zone
	end

	# attempt to open 'path' for writing, warn, return false in case of error
	def self.check_logpath path
		begin
			fh = File.open path, 'a'
			fh.close
			return true
		rescue SystemCallError => e
			warn "GLogg: Failed to open '#{path}' for writing: #{e}"
			return false
		end
	end

end # GLogg

