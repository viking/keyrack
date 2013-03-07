require 'helper'

class TestMigrator < Test::Unit::TestCase
  test "migrating version 3 to version 4" do
    database = {
      'groups' => {
        'top' => {
          'name' => 'top',
          'sites' => {},
          'groups' => {
            'Starfleet' => {
              'name' => 'Starfleet',
              'sites' => {
                'Enterprise' => {
                  'name' => 'Enterprise',
                  'logins' => {
                    'picard' => 'livingston',
                    'riker' => 'trombone'
                  }
                },
              },
              'groups' => {}
            },
            'Klingon Empire' => {
              'name' => 'Klingon Empire',
              'sites' => {
                "Bortas" => {
                  'name' => "Bortas",
                  'logins' => {"gowron" => "bat'leth"}
                }
              },
              'groups' => {}
            }
          }
        }
      },
      'version' => 3
    }
    expected = {
      'groups' => {
        'top' => {
          'name' => 'top',
          'sites' => [],
          'groups' => {
            'Starfleet' => {
              'name' => 'Starfleet',
              'sites' => [
                {'name' => 'Enterprise', 'username' => 'picard',
                 'password' => 'livingston'},
                {'name' => 'Enterprise', 'username' => 'riker',
                 'password' => 'trombone'},
              ],
              'groups' => {}
            },
            'Klingon Empire' => {
              'name' => 'Klingon Empire',
              'sites' => [
                {'name' => "Bortas", 'username' => "gowron",
                 'password' => "bat'leth"}
              ],
              'groups' => {}
            }
          }
        }
      },
      'version' => 4
    }
    actual = Keyrack::Migrator.run(database)
    assert_equal expected, actual
    assert_not_same database, actual
  end

  test "migrating version 4 returns the database unchanged" do
    database = {
      'groups' => {
        'top' => {
          'name' => 'top',
          'sites' => [],
          'groups' => {
            'Starfleet' => {
              'name' => 'Starfleet',
              'sites' => [
                {'name' => 'Enterprise', 'username' => 'picard',
                 'password' => 'livingston'},
                {'name' => 'Enterprise', 'username' => 'riker',
                 'password' => 'trombone'},
              ],
              'groups' => {}
            },
            'Klingon Empire' => {
              'name' => 'Klingon Empire',
              'sites' => [
                {'name' => "Bortas", 'username' => "gowron",
                 'password' => "bat'leth"}
              ],
              'groups' => {}
            }
          }
        }
      },
      'version' => 4
    }
    assert_equal database.clone, Keyrack::Migrator.run(database)
  end
end
