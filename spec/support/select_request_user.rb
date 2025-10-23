def select_request_user(user, field_name)
    user_str = user.display_name_safe

    # Fill in a partial match to force the textbox to fetch a list of options to select from
    fill_in field_name, with: user.uid
    sleep(1.5)
    expect(page.body).to include("option")
    select user_str + "\u00A0", from: field_name
end