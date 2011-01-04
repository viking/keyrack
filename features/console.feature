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
    * the output should contain "n. Add new"
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
    * the output should contain "1. Twitter"
    * the output should also contain "s. Save"
    * I type "s" to save the database
    * I type "q" to quit
    * I wait a few seconds
    * I run keyrack interactively again
    * I wait a few seconds
    * the output should contain "Keyrack password:"
    * I type "secret"
    * I wait a few seconds
    * the output should contain "1. Twitter"
    * I type "1" for Twitter
    * my clipboard should contain "kittens"
    * I type "q" to quit
