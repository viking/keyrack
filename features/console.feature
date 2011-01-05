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

    * the output should contain "g. New group"
    * I type "g" to add a new group
    * the output should contain "Group:"
    * I type "Social"
    * the output should contain "n. New entry"
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
    * the output should also contain "s. Save"
    * I type "s" to save the database
    * the output should contain "t. Top level menu"
    * I type "t"
    * the output should match /1\. .+Social.+/

    * the output should also contain "n. New entry"
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
    * the output should also contain "s. Save"
    * I type "s" to save the database

    * the output should contain "q. Quit"
    * I type "q" to quit
    * I wait a few seconds
    * I run keyrack interactively again
    * I wait a few seconds
    * the output should contain "Keyrack password:"
    * I type "secret"
    * I wait a few seconds
    * the output should match /1\. .+Social.+/
    * the output should also contain "2. Company X [buddypal]"
    * I type "1" for Social
    * the output should contain "1. Twitter [dudeguy]"
    * I type "1" for Twitter
    * my clipboard should contain "kittens"
    * I type "q" to quit
