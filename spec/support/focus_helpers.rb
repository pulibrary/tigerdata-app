# frozen_string_literal: true

require "timeout"

# Helpers for keyboard-focus / tab-order system specs.
# Prefer stable ids and container scopes over generated Lux/Vue ids (e.g. #displayInput-v-0).

def active_dom_element
  page.driver.browser.switch_to.active_element
end

def send_tab
  active_dom_element.send_keys(:tab)
end

# Wait until document.activeElement has the given id (works with Capybara's wait semantics).
def expect_active_element_id(element_id, visible: true)
  visible_opt = visible == true ? true : visible
  expect(page).to have_css("##{element_id}", visible: visible_opt)

  deadline = Capybara.default_max_wait_time
  Timeout.timeout(deadline) do
    loop do
      active = active_dom_element
      break if active&.attribute("id") == element_id

      sleep 0.05
    end
  end
rescue Timeout::Error
  active = active_dom_element
  raise "Expected focus on ##{element_id}, active element was " \
        "##{active&.attribute('id')} (#{active&.tag_name} class=#{active&.attribute('class')})"
end

# Wait until focus is inside a container (for Lux fields whose inner input ids are generated).
def expect_focus_within(container_selector)
  expect(page).to have_css(container_selector)

  deadline = Capybara.default_max_wait_time
  Timeout.timeout(deadline) do
    loop do
      break if focus_within?(container_selector)

      sleep 0.05
    end
  end
rescue Timeout::Error
  active = active_dom_element
  raise "Expected focus within #{container_selector}, active element was " \
        "##{active&.attribute('id')} (#{active&.tag_name} class=#{active&.attribute('class')})"
end

def focus_within?(container_selector)
  container = page.find(container_selector, match: :first)
  active = active_dom_element
  page.driver.browser.execute_script(
    "return arguments[0] === arguments[1] || arguments[0].contains(arguments[1]);",
    container.native,
    active
  )
end
