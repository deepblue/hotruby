require 'yaml'

module LastRuntime
  YML_FILE = File.dirname(__FILE__) + "/../.last_runtime.yml"
  
  def load_yml
    YAML.load(File.read(YML_FILE))
  end
  
  def last_runtime
    load_yml[self.class.name] rescue nil
  end
  
  def update_last_runtime(t)
    yml = load_yml rescue {}
    yml[self.class.name] = t
    File.open(YML_FILE, 'w+'){|f| f.write yml.to_yaml}
  end
  
  def with_last_runtime
    last = last_runtime
    now  = Time.now
    
    yield last, now
    
    update_last_runtime(now)
  end
end