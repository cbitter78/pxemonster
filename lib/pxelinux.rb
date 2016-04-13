require_relative 'host_configs'
require_relative 'pxe_file' 

require 'fileutils'
require 'pathname'


# Manage a pxe file for a given ip
class PXELinux 

	def initialize()
		@host_configs = HostConfigs.new
	end


	def get(ip)
		info = @host_configs[ip]
		raise NoConfigFoundForIp.new(ip) if info.nil?
		info
	end

	def create(ip)
		info = get(ip)
		pxe_file = PxeFile.new(info)
		pxe_file.write(@host_configs.config_dir)
		info["pxe_file_exists"] = true
		info
	end

	def delete(ip)
		info = get(ip)
		pxe_file = @host_configs.config_dir.join(info["pxe_file_name"])
		FileUtils.rm_f pxe_file
		info["pxe_file_exists"] = false
		info
	end

end

class NoConfigFoundForIp < StandardError
	def initialize(ip)
	  super("No configuration was found in pxemonster.yml for the ip #{ip}")
	end
end
