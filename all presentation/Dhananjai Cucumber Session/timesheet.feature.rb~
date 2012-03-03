  Feature: Create Timesheet
   
   @javascript
   Scenario: To check Login Functionality for Valid User.
    Given I have login username "dhananjai" and password "dhananjai"
    Given I am on the login page 
    When I fill in the following:
      | username | dhananjai |
      | password | dhananjai |
    And I press "login_button"
    Then I should see "Time sheet page"

   @javascript
   Scenario: To check Login Functionality for InValid User.
   Given I am on the home page 
   And I have user named "dhananjai" and password "dhananjai"
   When I fill in the following:
      | username | abc |
      | password | abc |
   And I press "login_button"
   Then I should see "Invalid username or password!"

   @javascript
   Scenario: To check Create Time Sheet Button is present on Time Sheet Page.
    Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  "Time sheet page"
    And I should see "Create Time Sheet"
    

   @javascript
   Scenario: To check timesheet list is present on Time Sheet Page.
    Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  "Time sheet page"
    And I should see "list"
    
   @javascript
   Scenario: To check Time Sheet light box opens or not when user clicks on Create Time Sheet button
    Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  "Time sheet page" 
    And I press "Create Time Sheet"
    Then I should see "Time Sheet Light box"
    And I should see "Date"
    And I should see "Task_name"
    And I should see "Task_details"
    And I should see "Duration"
    And I should see "Add"
    And I should see "Create"
    And I should see "Cancel"
    And I should not see "Create Time Sheet"
    
   @javascript
   Scenario: To check invalid format of timespent field
   Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  timesheet page 
    And I press "Create Time Sheet"
    Then I should see "create timesheet panel"
    When I fill in the following:
      | date | 03/12/2011  |
      | task_name | abc |
      | task_details  | xyz  |
      | time_spent |24:61   |
    And I press "create"
    Then I should see "time is not in proper format"

   @javascript
   Scenario: To check valid format of timespent field
   Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  timesheet page 
    And I press "Create Time Sheet"
    Then I should see "create timesheet panel"
    When I fill in the following:
      | date | 03/12/2011  |
      | task_name | abc |
      | task_details  | xyz  |
      | time_spent |23:59   |
    And I press "create"
    Then I should see "Time Sheet page"
    
    @javascript
   Scenario: To check that there is no Remove button for first pane in light box
    Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  "Time sheet page" 
    And I press "Create Time Sheet"
    Then I should see "Time Sheet Light box"
    And I should see "Date"
    And I should see "Task_name"
    And I should see "Task_details"
    And I should see "Duration"
    And I should see "Create"
    And I should see "Cancel"
    And I should see "Add"
    And I should not see "Remove"
    
    @javascript
   Scenario: To check that new pane opens by click on Add button
    Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  "Time sheet page" 
    And I press "Create Time Sheet"
    Then I should see "Time Sheet Light box"
    And I should see "Date"
    And I should see "Task_name_1"
    And I should see "Task_details_1"
    And I should see "Duration_1"
    And I should see "Create"
    And I should see "Cancel"
    And I should see "Add"
    Then I press "Add"
    And I should see "Task_name_2"
    And I should see "Task_details_2"
    And I should see "Duration_2"
    And I should see "Remove"
    
    
   @javascript
   Scenario: To check timesheet creation
   Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  "Time sheet page" 
    And I press "Create Time Sheet"
    Then I should see "Time Sheet light box"
    When I fill in the following:
      | date | 05/12/2011  |
      | task_name | abc |
      | task_details  | xyz  |
      | time_spent |  2.30 |
    And I press "create"
    Then I should not see "Time sheet Light box"
    Then I should see "Timesheet created successfully"
    And I should see "Create Time Sheet"
    And I should see "list"
    

   @javascript
   Scenario: To check click on cancel button in light box enables Create Time Sheet button
    Given I have login username "dhananjai" and password "dhananjai"
    Then I logged in as username "dhananjai" and password "dhananjai"
    Then I should see  timesheet page 
    And I press "Create Time Sheet"
    Then I should see "Time Sheet light box"
    And I should see "Date"
    And I should see "Task_name"
    And I should see "Task_details"
    And I should see "Duration"
    And I should see "Create"
    And I should see "Cancel"
    And I should see "Add"
    And I press "Cancel"
    Then I should not see "Time sheet Light box"
    And I should see "Create Time Sheet"
    
    
    

