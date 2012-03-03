  Feature: Sign in Process
    In order to test all sign in functionality 
    as an user
    I want to check the following scenarios.

   @javascript
   Scenario: To check if login pane opens or not on click  login button.
    Given I am on the home page 
    And I press "login button"
    Then I should see "Login Pane"

   @javascript
   Scenario: To check if login pane is closing or not when user click on login button second time
    Given I am on the home page 
    And I press "login_button"
    Then I should see "Login Pane"
    And I press "login_button"
    Then I should not see "Login Pane"

   @javascript
   Scenario: To check Login Functionality for registered users
   Given I am on the home page 
   And I have user named "mahesh@cipher-tech.com" and password "mahesh123"
   Then I press "login_button"
   And I fill in "mahesh@cipher-tech.com" for "username"
   And I fill in "mahesh123" for "password"
   And I press "submit_button"
   Then I go to the users home page
   
   @javascript
   Scenario: See login process with invalid username and password
   Given I am on the home page 
   And I have user named "mahesh@cipher-tech.com" and password "mahesh123"
   Then I press "login_button"
   When I fill in the following:
      | username | invalid@cipher-tech.com |
      | password | abcd123 |
   And I press "submit_button"
   Then I should see "Invalid username or password!"
   Then I should see "Try to login again"

   @javascript
   Scenario: To check Login Functionality with Valid Username and Invalid Password.
   Given I am on the home page 
   And I have user named "mahesh@cipher-tech.com" and password "mahesh123"
   Then I press "login_button"
   When I fill in the following:
      | username | mahesh@cipher-tech.com |
      | password | abcd123 |
   And I press "submit_button"
   Then I should see "Invalid username or password!"
   Then I should see "Try to login again"

   @javascript
   Scenario: To check if login pane opens or not when user click on “try to login again link” in light box.
   Given I am on the home page 
   And I have user named "mahesh@cipher-tech.com" and password "trupti123"
   Then I press "login_button"
   When I fill in the following:
      | username | invalid@cipher-tech.com |
      | password | mahesh123 |
   And I press "submit_button"
   Then I should see "Invalid username or password!"
   And I follow "Try to login again"
   Then I should not see "Try to login again"
   And I should be on login page
   And I should see "Login Pane"

 
