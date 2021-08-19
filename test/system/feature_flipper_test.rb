require "application_system_test_case"

class FeatureFlipperTest < ApplicationSystemTestCase

  # Defaults
  # - navbar_banner_alert:  enabled
  # - navbar_pickup_page:   enabled
  # - curbside:             enabled

  def test_navbar_banner_alert
    # Default - Curbside Alert Banner is Present
    Flipper[:navbar_banner_alert].enable
    visit '/catalog'
    assert page.has_selector?("#navbar-banner-alert")

    # Disabled - Curbside Alert Banner is Gone
    Flipper[:navbar_banner_alert].disable
    visit '/catalog'
    assert page.has_no_selector?("#navbar-banner-alert")
  end

  def test_navbar_pickup_page
    # Default - Curbside Book Pickups Page is Present
    Flipper[:navbar_pickup_page].enable
    visit '/catalog'
    assert page.has_link?("Book Pickup Service")

    # Disabled - Curbside Book Pickups Page is Gone
    Flipper[:navbar_pickup_page].disable
    visit '/catalog'
    assert page.has_no_link?("Book Pickup Service")
  end

  def test_curbside_reserves
    # Default - Reserves Form is Gone
    Flipper[:reserves].disable
    visit '/reserves'
    assert page.has_no_selector?("form.reserves-search")

    # Disabled - Reserves Form is Present
    Flipper[:reserves].enable
    visit '/reserves'
    assert page.has_selector?("form.reserves-search")
  end
end
