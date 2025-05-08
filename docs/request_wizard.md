# Request Wizards

This system has a pattern for building our request wizards. Currently the new project request wizard is under construction, but the pattern should be the same for all types of project requests in the system.

There should be a folder for the wizard in the controllers and views directory ( app/controllers/new_project_wizard & app/views/new_project_wizard). The controllers folder should contain a controller for each step of the wizard. The views folder should have a view for each step of the wizard. For simplicity we have named the files the same as the step name.

The controllers should all inherit from the superclass RequestWizardsController. This gives you the navigation between steps in the wizard saving the Request as you go.

## Super Class for controllers

The RequestWizardsController implements the logic to check the action of the save and call the correct render method: next, back, or current

## Step controllers

The step controllers need to implement the methods to render or redirect the view for next, back or current.

## Routes

The routes should include a top level path item for the wizard and then a path item for the step. ( new-project/project-information). Routes are needed for the show and save of each step.

## Adding a new step

To add a new step you should create a new step controller, a new view, and new routes. In addition you will need to change the previous and next steps if they exists to point at your new step. See [this PR](https://github.com/pulibrary/tigerdata-app/pull/1455) for an example of adding an additional step into a wizard.
