yaml = YAML.load(ERB.new(File.read(Rails.root.join('config/config.yml'))).result)

# env-specific if available, otherwise default hash. 
# yaml file itself should merge in defaults to env-specific. 
APP_CONFIG = yaml[Rails.env] || yaml["default"]