# frozen_string_literal: true
def select_and_verify_department(department:, department_code:, department_list:)
  select_department(department:, department_code:)

  within(".departments") do
    # The user selected is visible on the page
    expect(page).to have_content(department)
    # the hidden input has all the users
    expect(page).to have_field("request[departments][]", type: :hidden, with: { code: department_code, name: department }.to_json)

    department_list.each do |old_department|
      expect(page).to have_field("request[departments][]", type: :hidden, with: { code: old_department[:code], name: old_department[:name] }.to_json)
    end

    # the javascript cleared the find to get ready for the next search
    expect(page.find(".lux-field input").value).to eq("")
  end
end

def select_department(department:, department_code:)
  within(".departments") do
    page.find(".lux-field input").fill_in with: department_code
    expect(page).to have_content department
    find(".lux-autocomplete-result").click
  end
end