# frozen_string_literal: true

# Interaction pattern matches main (fill_in → wait for label → click first result).
# Locator uses a plain input under the field root: #data_*_input is itself the
# .lux-field.field wrapper, so a descendant selector ".field.lux-field input" is unreliable.
def select_user(user, field, hidden_field)
  user_str = user.display_name_safe
  within("##{field}_input") do
    page.find("input", match: :first).fill_in with: user.uid
    expect(page).to have_content user_str
    find(".lux-autocomplete-result").click

    expect(page.find("input", match: :first).value).to eq(user_str)
    expect(page).to have_field(hidden_field, type: "hidden", with: user.uid)
  end
end

def select_data_user(user, user_list)
  user_str = user.display_name_safe

  within(".user-role") do
    page.find(".data-users input", match: :first).fill_in with: user.uid
    expect(page).to have_content user_str
    find(".lux-autocomplete-result").click

    # The user selected is visible on the page
    expect(page).to have_content(user.given_name)
    # the hidden input has all the users
    expect(page).to have_field("all_selected", type: :hidden, with: user_list.to_json)

    # the javascript cleared the find to get ready for the next search
    expect(page.find(".data-users input", match: :first).value).to eq("")
  end
end
