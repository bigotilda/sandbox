##
# Represents a "settings" object, which contains key-value (possibly nested) pairs that are stored as YAML. Objects
# of this class act somewhat like ActiveRecord objects, implementing save-related and validation-related functions. If
# the provided filename does not exist, it will be attempted to be created. If the file cannot be written, it silenty
# does nothing (but logs an error in the log).
class YamlSettings
  # we want this class to implement ActiveRecord-style validations
  include ActiveModel::Validations
  
  # the hash resulting from the loaded YAML file 
  attr_reader :hash
  
  # the filename of the loaded YAML file
  attr_reader :filename
  
  ##
  # Initialize with the specified YAML file; if the file is not found or empty or is bad YML, set @hash as empty hash
  def initialize(yaml_file)
    @filename = yaml_file
    begin
      @hash = YAML.load_file(yaml_file)
      @hash = {} unless @hash.is_a?(Hash)
    rescue
      @hash = {}
    end
  end
  
  ##
  # Get the hash of settings for our YAML_KEY (set in subclasses)
  # Since we munge strings to booleans on the way in, we need to convert booleans to strings of 0/1 on the way out
  def get_hash
    get_hash = {}
    if @hash.has_key?(self.class::YAML_KEY)
      @hash[self.class::YAML_KEY].each do |k, v|
        if self.class::BOOLEAN_KEYS.include?(k.to_sym)
          get_hash[k] = v ? '1' : '0'
        else
          get_hash[k] = v
        end
      end
    end
    get_hash
  end
  
  ##
  # Save the contents of the settings hash to the source file if we are valid, and return true. Otherwise do not save
  # the hash to the source file, and return false.
  def save
    if valid?
      begin
        File.open(@filename, 'w') { |f| YAML.dump(@hash, f) }
      rescue StandardError => e
        Rails.logger.error(e)
      end
      
      # in production environment, there may be several threads of the application that are being cached, which will contain old
      # values for these settings; to workaround this, tell Passenger to restart after saving. This will cause the server to restart
      # on the next request (there is a separate server process that checks this file).
      FileUtils.touch(File.join(Rails.root, 'tmp', 'restart.txt')) if Rails.env.production?
      
      true
    else
      false
    end
  end
  
  ##
  # Update the hash with the specified hash, via merging, then check validations, and if valid, save to the source YAML file
  # and return true. Otherwise if not valid, do not save to the source file, and return false.
  def update_attributes(hash)
    @hash.merge!(hash)
    save
  end
  
protected
  
  attr_writer :hash, :filename
end
