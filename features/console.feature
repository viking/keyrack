Feature: Console runner
  I want to run Keyrack from the console

  Scenario: starting for the first time with a filesystem store
    * I run keyrack interactively
    * I wait a few seconds
    * the output should contain "New passphrase:"
    * I type "secret"
    * the output should contain "Confirm passphrase:"
    * I type "secret"
    * I wait a few seconds
    * the output should contain "Choose storage type:"
    * I type "filesystem"

    * the output should contain "[g]roup"
    * I type "g" to add a new group
    * the output should contain "Group:"
    * I type "Social"
    * the output should contain "[n]ew"
    * I type "n" to add a new entry
    * the output should contain "Label:"
    * I type "Twitter"
    * the output should contain "Username:"
    * I type "dudeguy"
    * the output should contain "Generate password?"
    * I type "n" for no
    * the output should contain "Password:"
    * I type "kittens"
    * the output should contain "Password (again):"
    * I type "kittens"
    * the output should contain "1. Twitter [dudeguy]"
    * the output should also contain "[s]ave"
    * I type "s" to save the database
    * the output should contain "[t]op"
    * I type "t"
    * the output should match /1\. .+Social.+/

    * the output should also contain "[n]ew"
    * I type "n" to add a new entry
    * the output should contain "Label:"
    * I type "Company X"
    * the output should contain "Username:"
    * I type "buddypal"
    * the output should contain "Generate password?"
    * I type "y" for yes
    * the output should contain "Sound good? [yn]"
    * I type "y" for yes
    * the output should contain "2. Company X [buddypal]"
    * the output should also contain "[s]ave"
    * I type "n" to add a new entry
    * the output should contain "Label:"
    * I type "Company X"
    * the output should contain "Username:"
    * I type "friendguy"
    * the output should contain "Generate password?"
    * I type "y" for yes
    * the output should contain "Sound good? [yn]"
    * I type "y" for yes
    * the output should contain "3. Company X [friendguy]"
    * I type "s" to save the database

    * the output should contain "[q]uit"
    * I type "q" to quit
    * I wait a few seconds
    * I run keyrack interactively again
    * I wait a few seconds
    * the output should contain "Keyrack password:"
    * I type "secret"
    * I wait a few seconds
    * the output should match /1\. .+Social.+/
    * the output should also contain "2. Company X [buddypal]"
    * the output should also contain "3. Company X [friendguy]"
    * I type "1" for Social
    * the output should contain "1. Twitter [dudeguy]"
    * I type "1" for Twitter
    * my clipboard should contain "kittens"

    * the output should contain "[d]elete"
    * I type "d"
    * the output should contain "1. Twitter [dudeguy]"
    * I type "1"
    * the output should contain "Are you sure?"
    * I type "y"
    * the output should contain "[t]op"
    * I type "t"

    * the output should contain "2. Company X [buddypal]"
    * I type "2" for Company X (buddypal)
    * my clipboard should match "^.{8}$"

    * the output should contain "Main Menu"
    * I type "d"
    * the output should contain "1. Company X [buddypal]"
    * I type "1"
    * the output should contain "Company X [buddypal]"
    * the output should also contain "Are you sure?"
    * I type "y"

    * the output should contain "Main Menu"
    * the output should also contain "2. Company X [friendguy]"
    * I type "q" to quit
    * the output should contain "Really quit?" (since the database is dirty)
    * I type "y"
