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

def select_data_user(user, user_list)
  user_str = user.display_name_safe

  page.find(".data-users.lux input").fill_in with: user.uid
  expect(page).to have_content user_str
  find(".lux-autocomplete-result").click

  # The user selected is visible on the page
  expect(page).to have_content(user.given_name)
  # the hidden input has all the users
  expect(page).to have_field("all_selected", type: :hidden, with: user_list.to_json)

  # the javascript cleared the find to get ready for the next search
  expect(page.find(".data-users.lux input").value).to eq("")
end
