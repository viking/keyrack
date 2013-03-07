module Keyrack
  # Migrate databases from one version to the next.
  class Migrator
    def self.run(database)
      new(database).run
    end

    def initialize(database)
      @database = database
      @version = database['version']
    end

    def run
      case @version
      when 3
        migrate_3_to_4(@database.clone)
      when 4
        @database
      end
    end

    private

    def migrate_3_to_4(database)
      groups = [database['groups']['top']]
      until groups.empty?
        group = groups.pop
        group['sites'] =
          group['sites'].inject([]) do |arr, (site_name, site_hash)|
            site_hash['logins'].each_pair do |username, password|
              arr.push({
                'name' => site_name,
                'username' => username,
                'password' => password
              })
            end
          arr
        end
        groups.push(*group['groups'].values)
      end
      database['version'] = 4
      database
    end
  end
end
