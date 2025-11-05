# frozen_string_literal: true
def select_user(user, field, hidden_field)
  name_with_space = user.display_name_safe + "\u00A0"

  option_string = "<option data-uid=\"#{user.uid}\" data-name=\"#{user.display_name_safe}\" value=\"#{user.display_name_safe + "&nbsp\;"}\">"

  # Fill in a partial match to force the textbox to fetch a list of options to select from
  fill_in field, with: user.uid[0]
  fill_in field, with: user.uid
  sleep(0.6) # allow for debounce
  wait_for_option(option_string)

  select name_with_space, from: field
  expect(page).to have_field(field, with: user.display_name_safe)
  expect(page).to have_field(hidden_field, type: "hidden", with: user.uid)
end

def wait_for_option(option_string)
  count = 5
  while (count > 0) && body.exclude?(option_string)
    sleep(0.1) # allow for values to return
    count -= 1
  end

  unless body.include?(option_string)
    puts "This will error"
    puts page.driver.browser.logs.get(:browser)
  end
end
