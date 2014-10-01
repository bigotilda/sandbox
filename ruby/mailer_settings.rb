##
# Represents the 'mailer' settings used by powderDesk
class MailerSettings < YamlSettings
  YAML_KEY = 'mailer' # the key used in the settings file for the mailer entries
  BOOLEAN_KEYS = [:send_emails] # the keys underneath YAML_KEY that are considered boolean
  
  validates_with EmailFromValidator, :keys => [[YAML_KEY.to_sym, :default_from]]
    
  ##
  # Initialize using the instance settings YAML file where the mailer key exists
  def initialize()
    super('config/settings.instance.yml')
    @hash[YAML_KEY] = {} unless @hash[YAML_KEY].is_a?(Hash)
  end
  
  ##
  # Update the 'mailer' attributes with the given hash via merge. The hash should not be nested. Boolean values are also checked
  # and formatted appropriately before saving (they are assumed to come in as '1' or '0' strings from the checkboxes from views)
  def update_attributes(mailer_hash)
    mailer_hash.each { |key, val|
      mailer_hash[key] = val == '1' if BOOLEAN_KEYS.include?(key.to_sym)
    }
    
    # success
    if super({YAML_KEY => @hash[YAML_KEY].merge(mailer_hash)})
    
      # Update the locations where related values are kept cached
      Settings.reload!
      if Settings.respond_to? YAML_KEY
        ApplicationMailer.default from: Settings.send(YAML_KEY).default_from
      else
        Rails.logger.error("Settings key: #{YAML_KEY} is undefined!")
      end
    end
  end
end

