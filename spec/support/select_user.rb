# frozen_string_literal: true
def select_user(user, field, hidden_field)
  user_str = user.display_name_safe
  within("##{field}_input") do
    page.find(".field.lux-field input").fill_in with: user.uid
    expect(page).to have_content user_str
    find(".lux-autocomplete-result").click

    expect(page.find("##{field}_input input").value).to eq(user_str)
    expect(page).to have_field(hidden_field, type: "hidden", with: user.uid)
  end
end

def select_data_user(user, user_list)
  user_str = user.display_name_safe

  within(".user-role") do
    page.find(".data-users.lux-field input").fill_in with: user.uid
    expect(page).to have_content user_str
    find(".lux-autocomplete-result").click

    # The user selected is visible on the page
    expect(page).to have_content(user.given_name)
    # the hidden input has all the users
    expect(page).to have_field("all_selected", type: :hidden, with: user_list.to_json)

    # the javascript cleared the find to get ready for the next search
    expect(page.find(".data-users.lux-field input").value).to eq("")
  end
end
